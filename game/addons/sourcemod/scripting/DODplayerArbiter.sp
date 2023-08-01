//*
//* DoD:S Player arbiter for DODs
//*
//* Version 1.1
//*
//* Description:
//*   1.0 2021 Plugin restart score when count of players rise to 6
//*   1.1 2023 Plugin refresh bots every minute by simply kick all of them.
//*

#define noDEBUG 1
#define PLUGIN_VERSION "1.1"
#define PLUGIN_NAME "DoD player arbiter"
#define GAME_DOD
#define USE_PLAYER
#include "c:\Users\skorik\source\repos\smK64t\scripting\include\k64t"
#define IGNORE_BOTS 1
#define noNO_COMMANDS 1
#define REFRESH_BOT  1 //ver 1.1

#define SND_GONG "k64t\\whistle.mp3" 
#define MSG_RESTART "Restart"
#define MSG_Start_scoring	"Start scoring"
#define MSG_Stop_scoring	"Stop scoring"

//#include "DODplayerArbiter.TeamScore.inc" 
//#include "DODplayerArbiter.PlayerSpawn.inc"

// Global Var
int PlayerTeam[MAX_PLAYERS+1];
int TeamHumanPlayerCount[DOD_TEAMS_COUNT];
#if defined REFRESH_BOT
int BotKills[MAX_PLAYERS+1];
bool BotToKick[MAX_PLAYERS+1];
#endif
char sndGong[]={SND_GONG};
bool g_Scoring=false;
bool g_1stRestart=false;
#define roundWin		0	
#define roundStart 		1
#define roundActive		2
#define roundRestart	3	
//int roundStatus=roundWin;

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
//***********************************************
public void OnPluginStart(){
//***********************************************
#if defined DEBUG
DebugPrint("OnPluginStart");
RegConsoleCmd("showHcount", cmdShowTeamHumanPlayerCount);
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
//HookEvent("dod_round_win", Event_RoundWin, EventHookMode_Post);
	HookEvent("player_spawn",			Event_PlayerSpawn,	EventHookMode_Post);
	HookEvent("player_team",			Event_PlayerTeam,	EventHookMode_Post);// A player changed his team  https://wiki.alliedmods.net/Generic_Source_Events#player_team
HookEvent("player_changeclass",		Event_PlayerClass,	EventHookMode_Post);
//HookEvent("player_death", Event_RoundWin, EventHookMode_Post);
	//HookEvent("dod_round_start",		Event_Showevent,	EventHookMode_Post);	
	//HookEvent("dod_round_active",		Event_Showevent,	EventHookMode_Post);
	//HookEvent("dod_restart_round",		Event_Showevent,	EventHookMode_Post);
	//HookEvent("dod_round_win",		Event_Showevent,	EventHookMode_Post);
#if defined REFRESH_BOT
HookEvent("player_death",Event_player_killed, EventHookMode_Post);
HookEvent("dod_capture_blocked",Event_capture_blocked, EventHookMode_Post);
HookEvent("dod_point_captured",Event_point_captured, EventHookMode_Post);
HookEvent("dod_bomb_planted",Event_bomb, EventHookMode_Post);
HookEvent("dod_bomb_defused",Event_bomb, EventHookMode_Post);
#endif 	
}
//public void OnPluginEnd(){}
//**************************************************
public void OnMapStart(){
//**************************************************	
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
	StoreTeamsScore();	
	for (int client = 1; client <=MaxClients ; client++)PlayerTeam[client]=0;
	//TODO:Test Logic
	#if defined DEBUG
	CalculateTeamHumanPlayerCount();
	#endif
	if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS] >= minPlayer_to_start_score)
	{
		g_Scoring=true;
	}
	g_1stRestart=false;
	
	#if defined REFRESH_BOT
	CreateTimer(60.0,Refreshbot,0,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	#endif 		
}
#if defined REFRESH_BOT
//**************************************************
public  Action Refreshbot(Handle timer, int client){
//**************************************************
#if defined DEBUG
	PrintToServer("-----------");
	PrintToServer("Refresh bot");
	PrintToServer("-----------");
#endif
for (int i = 1;  i<=MaxClients ; i++) 
	if (IsClientConnected(i)) 
	if (!IsClientSourceTV(i))	
	if (IsFakeClient(i)) 	
		{			
		#if defined DEBUG
		char clientName[32];
		GetClientName(i, clientName, 31);
		PrintToServer("%d.%s kills=%d",i,clientName, BotKills[i]);	
		#endif
		if (BotKills[i]==0){BotToKick[i]=true;CreateTimer(GetRandomFloat(0.1,1.0)*59,Kickbot,i,TIMER_FLAG_NO_MAPCHANGE);}else {BotKills[i]=0;}
	}
}	
public  Action Kickbot(Handle timer, int client){
	if (BotToKick[client])
	if (IsClientConnected(client)) 
	if (IsFakeClient(client)) 
	if (BotKills[client]==0)	
	{
	#if defined DEBUG
	char clientName[32];
	GetClientName(client, clientName, 31);
	PrintToServer("#%d %s kills=%d -> kick",client,clientName, BotKills[client]);	
	#endif		
	KickClient(client);
	}
}
public  void Event_player_killed(Event event, const char[] name,  bool dontBroadcast){
int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
BotKills[attacker]++;	
//#if defined DEBUG
//	char clientName[32];
//	GetClientName(attacker, clientName, 31)	;
//	PrintToServer("[%s] #%d %s %d",PLUGIN_NAME,attacker,clientName,BotKills[attacker] );
//#endif
int victim = GetClientOfUserId(GetEventInt(event, "victim"));	
if (BotToKick[victim]) 
if (IsClientConnected(victim)) 
if (IsFakeClient(victim)) KickClient(victim);	
}
public  void Event_capture_blocked (Event event, const char[] name,  bool dontBroadcast){
int blocker = GetClientOfUserId(GetEventInt(event, "blocker"));	
BotKills[blocker]++;	
}
public  void Event_point_captured (Event event, const char[] name,  bool dontBroadcast){
char cappers[32] ;	
GetEventString(event, "cappers", cappers, 31, "");
//PrintToServer("-----------------------------------------------------------");
//PrintToServer("[%s]:[Event_point_captured] %s ",PLUGIN_NAME,cappers);
for (int i=0;i!=31;i++)
	{
	int id=cappers[i];
	if (id==0) break;
	BotKills[id]++;	
	//#if defined DEBUG
	//char clientName[32];
	//GetClientName(id, clientName, 31);
	//PrintToServer("[%s]:[Event_point_captured] #%d %d %s",PLUGIN_NAME,i,id,clientName);
	//#endif
	}

}
public  void Event_bomb (Event event, const char[] name,  bool dontBroadcast){
int userid=GetClientOfUserId(GetEventInt(event, "userid"));	
BotKills[userid]++;	
//#if defined DEBUG
//	char clientName[32];
//	GetClientName(userid, clientName, 31)	;
//	char eventName[32];
//	GetEventName(event, eventName, 31);
//	PrintToServer("[%s]:[%s] #%d %s %d",PLUGIN_NAME,eventName,userid,clientName,BotKills[userid] );
//#endif
}

#endif 
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
	ShowTeamHumanPlayerCount();
	#endif	
}
//**************************************************
public void Event_PlayerClass(Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if defined REFRESH_BOT
	BotKills[client]=0;
	BotToKick[client]=false;
	#endif
	#if defined IGNORE_BOTS
	if (!IsFakeClient(client))
	#endif	
	{
		//#if defined DEBUG
		//PrintToServer("PlayerTeam[%d]=%d",client,PlayerTeam[client]);
		//#endif	
		if (PlayerTeam[client]==0)
		{
			int Team=GetClientTeam(client);			
			PlayerTeam[client]=Team;
			#if defined DEBUG
			PrintToServer("GetClientTeam(%d)=%d",client,Team);
			PrintToServer("PlayerTeam[%d]=%d",client,PlayerTeam[client]);
			#endif	
			TeamHumanPlayerCount[Team]++;	
			#if defined DEBUG
			PrintToServer("%d + %d %d",TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],minPlayer_to_start_score);
			#endif	
			if (!g_Scoring){		
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==minPlayer_to_start_score)				
					StartScoring();
			}
		}
	}	
}	
//**************************************************
void StartScoring(){
//**************************************************	
	g_Scoring=true;
	PrintHintTextToAll("%t",MSG_Start_scoring);
	//Если состояние раунда между старт и победа. Если состояние раунда бонус, то только очистить счет
	if (g_1stRestart)
	{
		ReStoreTeamsScore();	
	}
	else
	{
		#if !defined NO_COMMANDS				
		ServerCommand("mp_clan_restartround 10");//Restart round
		#else
		PrintToServer("----------------\nmp_clan_restartround 10\n-----------------");					
		#endif
		PrintHintTextToAll("%t",MSG_RESTART);
		g_1stRestart=true;
	}					
	EmitSoundToAll(sndGong);					
	#if defined DEBUG
	ShowTeamHumanPlayerCount();
	#endif
}
void ReStoreTeamsScore(){}
void StoreTeamsScore(){}
void ReSetTeamsScore(){}

public void Event_PlayerSpawn(Event event, const char[] name,  bool dontBroadcast){
	
}


//**************************************************
public void Event_PlayerTeam(Event event, const char[] name,  bool dontBroadcast){
//**************************************************
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if defined IGNORE_BOTS
	if (!IsFakeClient(client))
	#endif	
	{
		int oldTeam=event.GetInt("oldteam");	
		int newTeam=event.GetInt("team");	
		if ((oldTeam==DOD_TEAM_ALLIES || oldTeam==DOD_TEAM_AXIS) && newTeam!=oldTeam )	
		{
			TeamHumanPlayerCount[oldTeam]--;
			PlayerTeam[client]=0;
			#if defined DEBUG
			ShowTeamHumanPlayerCount();
			#endif
			if (g_Scoring)
			{		
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==minPlayer_to_start_score-1)
				{			
					g_Scoring=false;
					StoreTeamsScore();
					PrintHintTextToAll("%t",MSG_Stop_scoring);
				}
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==0) 
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
			StartScoring();
}
#if defined DEBUG
public  Action cmdShowTeamHumanPlayerCount (int client, int args){
	ShowTeamHumanPlayerCount();	
	return Plugin_Handled;
}
void ShowTeamHumanPlayerCount (){PrintToServer("ALLIES=%d\tAXIS=%d",TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS]);}

#endif 

public void Event_Showevent(Event event, const char[] name, bool dontBroadcast){
	LogError("Event [%s]",name);
}

#endinput
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 








































































#define nDEBUG 1
#define PLUGIN_VERSION "0.2"
#define PLUGIN_NAME "Move Players To Spectators"
#include "K64t.inc"


public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "K64t",
	description = PLUGIN_NAME,
	version = PLUGIN_VERSION,
	url = ""
	};
new Float:P[MAX_PLAYERS][3]; // Координаты в начале раунда	
new Float:T_DEATH[MAX_PLAYERS];	//Время смерти игрока или -1
new Float:T_RoundStart;	//Время старта раунда
	
public OnPluginStart(){
//*****************************************************************************
}
//*****************************************************************************
public OnMapStart(){
//*****************************************************************************
HookEvent("round_end", EventRoundEnd);	
HookEvent("round_start", EventRoundStart);	
HookEvent("player_death", EventPlayerDeath);
//*****************************************************************************
}
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
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
//*****************************************************************************
#if defined DEBUG 
	PrintToChatAll("%s","DEATH");	
#endif	
new Client=GetClientOfUserId(GetEventInt(event, "userid"));
T_DEATH[Client-1]=GetGameTime(); 
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


  
  
