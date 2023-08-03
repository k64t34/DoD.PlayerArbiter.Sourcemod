//*
//* DoD:S Players(bots)  arbiter for DODs
//*
//* Version 1.1
//*
//* Description:
//*   1.0 2021 The plugin restart score when count of players rise to 6
//*   1.1 2023 The plugin refresh  bots every minute, simply removing all useless ones (no frags, no flag capture/blocking, no bomb plant/defusing).
//*   1.2 2023 The plugin reset, save,restore scoring when  start, stop, resume scoring.
#define nDEBUG 1
#define PLUGIN_VERSION "1.2"
#define PLUGIN_NAME "DoD player arbiter"
#define GAME_DOD
#define USE_PLAYER
#include "c:\Users\skorik\source\repos\smK64t\scripting\include\k64t"
#define IGNORE_BOTS 1 //for debug define IGNORE_BOTS
#define noNO_COMMANDS 1
#define REFRESH_BOT  1 //ver 1.1

#define SND_GONG "k64t\\whistle.mp3" 
#define MSG_RESTART			"Restart"
#define MSG_Start_scoring	"Start scoring"
#define MSG_Stop_scoring	"Stop scoring"
#define MSG_Resume_scoring	"Resume scoring" //ver 1.2
// Global Var
char g_PLUGIN_NAME[]=PLUGIN_NAME;
int PlayerTeam[MAX_PLAYERS+1];				// Команда игрока
int TeamHumanPlayerCount[DOD_TEAMS_COUNT];	// Number of human players in a team
char sndGong[]=SND_GONG;					// The sound of the beginning of scoring
bool g_Scoring=false;						// Scoring points 
bool g_1stRestart=false;					// true - first round with scoring has already passed, false - no restart occur
bool g_Restarting=false;					// Command _restart 10 was sent
int g_RoundStatus=0;						// 0-Bonus,1-Start,2-Active
//ConVar 
ConVar sm_arbiter_minPlayer_to_start_score;
int minPlayer_to_start_score=0;
public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "Kom64t",
    description = "Reset score",
    version = PLUGIN_VERSION,
    url = "https://github.com/k64t34/DoD.PlayerArbiter.Sourcemod.git"
};
#include "DODplayerArbiter.TeamScore.inc" 
//#include "DODplayerArbiter.PlayerSpawn.inc"
#if defined REFRESH_BOT
#include "DODplayerArbiter.Refreshbots.inc"
#endif
#if defined DEBUG
char  g_LOG[] = "DODplayerArbiter.log";
//TODO:GetPluginFilename(,g_LOG,sizeof(g_LOG)); and pass to k_debug 
#endif 
//***********************************************
public void OnPluginStart(){
//***********************************************
#if defined DEBUG
DebugPrint("OnPluginStart");
LogToFile(g_LOG,"[%s]StartScoring",g_PLUGIN_NAME);
RegConsoleCmd("showHcount", cmdPrintTeamHumanPlayerCount);
#endif 
LoadTranslations("DODplayerArbiter.phrases");
char buffer[MAX_FILENAME_LENGHT];
Format(buffer, MAX_FILENAME_LENGHT,"sound\\%s",sndGong);	
AddFileToDownloadsTable(buffer);
PrecacheSound(sndGong,true);
sm_arbiter_minPlayer_to_start_score = CreateConVar("sm_arbiter_minPlayer_to_start_score", "0", "Count of player to start score",_,true,0.0/*,true,float(MaxClients)*/);
if (sm_arbiter_minPlayer_to_start_score != null)
{
	sm_arbiter_minPlayer_to_start_score.AddChangeHook(OnCvar_minPlayer_to_start_score);
	AutoExecConfig(true, "DODplayerArbiter");
	minPlayer_to_start_score=GetConVarInt(sm_arbiter_minPlayer_to_start_score);
}
HookEvent("player_team",			Event_PlayerTeam,	EventHookMode_Post);// A player changed his team  
HookEvent("player_changeclass",		Event_PlayerClass,	EventHookMode_Post); // https://wiki.alliedmods.net/Generic_Source_Events#player_team
	HookEvent("dod_round_start",		Event_RoundStart,	EventHookMode_Post);	
	HookEvent("dod_round_active",		Event_RoundActive,	EventHookMode_Post);
	HookEvent("dod_restart_round",		Event_RoundRestart,	EventHookMode_Post);
	HookEvent("dod_round_win",		Event_RoundWin,	EventHookMode_Post);
#if defined REFRESH_BOT
HookEvent("player_death",Event_player_killed, EventHookMode_Post);
HookEvent("dod_capture_blocked",Event_capture_blocked, EventHookMode_Post);
HookEvent("dod_point_captured",Event_point_captured, EventHookMode_Post);
HookEvent("dod_bomb_planted",Event_bomb, EventHookMode_Post);
HookEvent("dod_bomb_defused",Event_bomb, EventHookMode_Post);
#endif 	
}
public void OnPluginEnd(){
UnhookEvent("player_team",			Event_PlayerTeam,	EventHookMode_Post);
UnhookEvent("player_changeclass",		Event_PlayerClass,	EventHookMode_Post);
	UnhookEvent("dod_round_start",		Event_RoundStart,	EventHookMode_Post);	
	UnhookEvent("dod_round_active",		Event_RoundActive,	EventHookMode_Post);
	UnhookEvent("dod_restart_round",		Event_RoundRestart,	EventHookMode_Post);
	UnhookEvent("dod_round_win",		Event_RoundWin,	EventHookMode_Post);
#if defined REFRESH_BOT
UnhookEvent("player_death",Event_player_killed, EventHookMode_Post);
UnhookEvent("dod_capture_blocked",Event_capture_blocked, EventHookMode_Post);
UnhookEvent("dod_point_captured",Event_point_captured, EventHookMode_Post);
UnhookEvent("dod_bomb_planted",Event_bomb, EventHookMode_Post);
UnhookEvent("dod_bomb_defused",Event_bomb, EventHookMode_Post);
#endif 		
}
//**************************************************
public void OnMapStart(){
//**************************************************	
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
	ReSetTeamsScore();
	for (int client = 1; client <=MaxClients ; client++)PlayerTeam[client]=0;
	//TODO:Test Logic
	#if defined DEBUG
	CalculateTeamHumanPlayerCount();		
	if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS] >= minPlayer_to_start_score)
	{
		g_Scoring=true;
	}
	g_1stRestart=false;
	#endif
	
	#if defined REFRESH_BOT
	CreateTimer(60.0,Refreshbot,0,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	#endif 		
}

//**************************************************
stock void CalculateTeamHumanPlayerCount(){
//**************************************************	
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
	int Team;
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			#if defined IGNORE_BOTS
			if (!IsFakeClient(i))
			#endif	
			{
			Team=GetClientTeam(i);
			PlayerTeam[i]=Team;	
			TeamHumanPlayerCount[Team]++;
			}
		}			
	}
	#if defined DEBUG
	PrintTeamHumanPlayerCount();
	#endif	
}
//**************************************************
public void Event_PlayerClass(Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if defined DEBUG
	char eventName [32];event.GetName(eventName,31);
	char clientName[32];GetClientName(client, clientName, 31);
	PrintToServer("[%s]:[%s] #%d %s",g_PLUGIN_NAME,eventName,client,clientName);
	#endif
	#if defined REFRESH_BOT
	BotKills[client]=0;
	BotToKick[client]=false;
	#endif	
	#if defined IGNORE_BOTS
	if (!IsFakeClient(client))
	#endif		
	{		
		#if defined DEBUG
		PrintToServer("[%s]:[%s]GetClientTeam[%s]=%d",g_PLUGIN_NAME,eventName,clientName,GetClientTeam(client));
		PrintToServer("[%s]:[%s]PlayerTeam[%s]=%d",g_PLUGIN_NAME,eventName,clientName,PlayerTeam[client]);		
		#endif	
		if (PlayerTeam[client]==0) // Player only change class (team remain at the same)
		{
			int Team=GetClientTeam(client);
			PlayerTeam[client]=Team;
			#if defined DEBUG
			PrintToServer("[%s]:[%s]GetClientTeam(%s)=%d",g_PLUGIN_NAME,eventName,clientName,Team);			
			PrintToServer("[%s]:[%s]PlayerTeam[%s]=%d",g_PLUGIN_NAME,eventName,clientName,PlayerTeam[client]);			
			#endif	
			TeamHumanPlayerCount[Team]++;
			#if defined DEBUG
			PrintTeamHumanPlayerCount();				
			#endif	
			if (!g_Scoring){		
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==minPlayer_to_start_score)				
				{
					g_Scoring=true;
					CreateTimer(3.0,StartScoring,TIMER_FLAG_NO_MAPCHANGE);					
				}
			}
		}
	}	
}	
//**************************************************
Action  StartScoring(Handle timer){
//**************************************************
#if defined DEBUG
LogToFile(g_PLUGIN_NAME,"[%s]StartScoring",g_PLUGIN_NAME);
#endif	
if (g_Scoring) 
{
	if (g_RoundStatus==2 ) //Если состояние раунда между стартом и победой, то _restart
		{
		#if defined DEBUG
		PrintToServer("[%s]StartScoring RESTART_ROUND",g_PLUGIN_NAME);
		#endif	
		#if !defined NO_COMMANDS				
		ServerCommand("mp_clan_restartround 10");//Restart round
		g_Restarting=true;
		#else
		PrintToServer("----------------\nmp_clan_restartround 10\n-----------------");					
		#endif
		}
	if (g_1stRestart)
		{			
		if (!g_Restarting)	ReStoreTeamsScore();
		PrintToConsoleAll("[%s]: %s",g_PLUGIN_NAME,MSG_Resume_scoring);				
		PrintHintTextToAll("%t",MSG_Resume_scoring);
		}
	else
		{
		g_1stRestart=true;	
		if (!g_Restarting) ReSetTeamsScore();			
		PrintHintTextToAll("%t",MSG_Start_scoring);
		PrintToConsoleAll("[%s]: %s",g_PLUGIN_NAME,MSG_Start_scoring);			
		}		
	//EmitSoundToAll(sndGong);					
	#if defined DEBUG
	PrintTeamHumanPlayerCount();
	#endif
}
return Plugin_Continue;
}
//**************************************************
public void Event_PlayerTeam(Event event, const char[] name,  bool dontBroadcast){
//**************************************************
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if defined DEBUG
	char eventName [32];event.GetName(eventName,31);
	char clientName[32];GetClientName(client, clientName, 31);
	PrintToServer("[%s]:[%s] #%d %s team %d->%d",g_PLUGIN_NAME,eventName,client,clientName,event.GetInt("oldteam"),event.GetInt("team"));
	LogError("[%s]:[%s] #%d %s team %d->%d",g_PLUGIN_NAME,eventName,client,clientName,event.GetInt("oldteam"),event.GetInt("team"));
	#endif
	#if defined IGNORE_BOTS
	if (!IsFakeClient(client))
	#endif	
	{
		int oldTeam=event.GetInt("oldteam");	
		int newTeam=event.GetInt("team");	
		if ((oldTeam==DOD_TEAM_ALLIES || oldTeam==DOD_TEAM_AXIS) && newTeam!=oldTeam )	
		{
			TeamHumanPlayerCount[oldTeam]--;
			PlayerTeam[client]=0; // While no class has been selected player team set to 0. Its need to determinide than player change (not 1st set) class 
			#if defined DEBUG
			PrintTeamHumanPlayerCount();			
			#endif
			if (g_Scoring)
			{		
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==minPlayer_to_start_score-1)
				{			
					g_Scoring=false;
					if (!g_Restarting)
					{
						
						#if defined DEBUG
						LogError("[%s] Store score",g_PLUGIN_NAME);	
						#endif					
						StoreTeamsScore();
						PrintHintTextToAll("%t",MSG_Stop_scoring);
					}
				}
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]==0 && TeamHumanPlayerCount[DOD_TEAM_AXIS]==0) 
				{
					g_1stRestart=false;
					ReSetTeamsScore();
				}
			}
		}	
	}	
}
//**************************************************
public void OnCvar_minPlayer_to_start_score(ConVar convar, char[] oldValue, char[] newValue){
//**************************************************	
	minPlayer_to_start_score=StringToInt(newValue);
	if (!g_Scoring)	
		if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]>=minPlayer_to_start_score)
		{
			g_Scoring=true;
			CreateTimer(1.0,StartScoring,TIMER_FLAG_NO_MAPCHANGE);		
		}
}
#if defined DEBUG
public  Action cmdPrintTeamHumanPlayerCount (int client, int args){
	PrintTeamHumanPlayerCount();	
	return Plugin_Handled;
}
void PrintTeamHumanPlayerCount (){
	PrintToServer("[%s]Allies team =%d Axis team=%d min_to_score=%d",g_PLUGIN_NAME,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],minPlayer_to_start_score);	
	LogError("[%s]Allies team =%d Axis team=%d min_to_score=%d",g_PLUGIN_NAME,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],minPlayer_to_start_score);	
	}
#endif 
public void Event_RoundRestart(Event event, const char[] name, bool dontBroadcast){EmitSoundToAll(sndGong);						}
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){g_RoundStatus=1;}
public void Event_RoundActive(Event event, const char[] name, bool dontBroadcast){
g_RoundStatus=2;
if (g_Restarting)
	{		
		if (g_Scoring)
		{
			if (g_1stRestart){ReStoreTeamsScore();}	
			else{ReSetTeamsScore();}	
		}
		g_Restarting=false;
	}
}
public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast){g_RoundStatus=0;}

#endinput
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 






	
//*****************************************************************************
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast){
//*****************************************************************************
T_RoundStart=GetGameTime();
for (new client = 1; client <=MaxClients ; client++)	
	{
	if (IsValidClient(client)) GetClientAbsOrigin(client,P[client-1]);		
	T_DEATH[client-1]=-1.0;
	#if defined DEBUG 
	new String:ClientName[25];
	if (IsClientConnected(client))
		{
		GetClientName(client,ClientName, sizeof(ClientName)); 
		PrintToChatAll("%d %s %f %f %f",client,ClientName,P[client-1][0],P[client-1][1],P[client-1][2]);
		}	
	#endif	
	
	}
}
//*****************************************************************************
public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
//*****************************************************************************
#if defined DEBUG 
PrintToChatAll("RoundEnd");	
#endif	

new Float:L[3];
new clientTeam;
for (new client = 1; client <=MaxClients ; client++)
	{ 
	if (!IsValidAliveOrDeadClient(client)  || IsFakeClient(client) || T_DEATH[client-1]==-1.0 )
		{
		#if defined DEBUG
		PrintToChatAll("%d - T-death %f ignored",client,T_DEATH[client-1]);
		#endif 
		continue;
		}
		clientTeam=GetClientTeam(client);
	if (clientTeam==CS_TEAM_CT || clientTeam==CS_TEAM_T) 
		{
		GetClientAbsOrigin(client,L);
		#if defined DEBUG 
		new String:ClientName[25];
		GetClientName(client,ClientName, sizeof(ClientName)); 
		PrintToChatAll("%d %s %f %f %f",client,ClientName,P[client-1][0],P[client-1][1],P[client-1][2]);	
		PrintToChatAll("%d %s %f %f %f",client,ClientName,L[0],L[1],L[2]);	
			PrintToChatAll("%d %s dZ=%f",client,ClientName,FloatAbs(P[client-1][2]-L[2]));	
		#endif
		if (P[client-1][0]==L[0] && 
			P[client-1][1]==L[1] && 
			FloatAbs(P[client-1][2]-L[2])<100.0 
			&& T_DEATH[client-1]-T_RoundStart>5.0
		)
			{
			#if defined DEBUG 
			PrintToChatAll("%d %s Stand",client,ClientName);	
			#endif
			MoveToSpec(client);
			}
		}	
	}
}
//*****************************************************************************
MoveToSpec(client){
//*****************************************************************************
#if defined DEBUG 
	PrintToChatAll("Change Client %d Team to Specators %d",client,CS_TEAM_SPECTATOR);	
#endif	
PrintCenterText(client,"You reform  to spectator  due to  were frozen for the entire round"); 
PrintToChat(client,    "You reform  to spectator  due to  were frozen for the entire round"); 
//ShowMOTDPanel( client, "Статистика", "http://csw.oduyu.so/stats.css", MOTDPANEL_TYPE_URL);
ChangeClientTeam(client, CS_TEAM_SPECTATOR); 

}


  
  
