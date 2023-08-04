//*
//* DoD:S Players(bots)  arbiter for DODs
//*
//* Version 1.1
//*
//* Description:
//*   1.0 2021 The plugin restart score when count of players rise to 6
//*   1.1 2023 The plugin refresh  bots every minute, simply removing all useless ones (no frags, no flag capture/blocking, no bomb plant/defusing).
//*   1.2 2023 The plugin reset, save,restore scoring when  start, stop, resume scoring.
//*Параметры запуска из Notepad++ по F5 c:\Users\skorik\source\repos\sourcemod-1.10.0-git6502-windows\addons\sourcemod\scripting\SMcompiler.exe  $(FULL_CURRENT_PATH)
#define noDEBUG 
#define PLUGIN_VERSION "1.2"
#define PLUGIN_NAME "DoD player arbiter"
#define PLUGIN_AUTHOR "Kom64t"
#define GAME_DOD
#define USE_PLAYER
#include "k64t"
#define IGNORE_BOTS  //for debug define IGNORE_BOTS
#define noNO_COMMANDS 
#define REFRESH_BOT   //ver 1.1

#define SND_GONG "k64t\\whistle.mp3" 
#define MSG_Start_scoring	"Start scoring"
#define MSG_Stop_scoring	"Stop scoring"
#define MSG_Resume_scoring	"Resume scoring" //ver 1.2
// Global Var
int g_cntRound=0;							// Scoring round counter ver 1.3
int g_minutePrinted=-1;							// Last printed minute
bool g_awaitStopScoring=false;				// true - waiting, false - no waiting
char g_PLUGIN_NAME[]=PLUGIN_NAME;           // Plugin name
int PlayerTeam[MAX_PLAYERS];				// Команда игрока int[] PlayerTeam = new int[MaxClients]			// Команда игрока
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
    author = PLUGIN_AUTHOR,
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
bool __test=false;
//char  g_LOG[] = "DODplayerArbiter.log";
//TODO:GetPluginFilename(,g_LOG,sizeof(g_LOG)); and pass to k_debug 
#endif 
//***********************************************
public void OnPluginStart(){
//***********************************************
#if defined DEBUG
strcopy(g_LOG,MAX_FILENAME_LENGHT,"DODplayerArbiter.log");//TODO:GetPluginFilename(,g_LOG,sizeof(g_LOG)); and pass to k_debug 
DebugLog("OnPluginStart");
RegConsoleCmd("_test", cmdPrintTeamHumanPlayerCount);
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
#if defined DEBUG
	DebugLog("OnPluginEnd");
#endif	
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
	#if defined DEBUG
	DebugLog("OnMapStart");
	#endif
	g_cntRound=0;	
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
	ReSetTeamsScore();
	for (int client = 1; client !=MAX_PLAYERS ; client++)PlayerTeam[client]=0;
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
	PrintTeamHumanPlayerCount("CalculateTeamHumanPlayerCount");
	#endif	
}
//**************************************************
public void Event_PlayerClass(Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if defined DEBUG
	char eventName [32];event.GetName(eventName,31);
	char clientName[32];GetClientName(client, clientName, 31);
	//DebugLog("[%s] #%d %s",eventName,client,clientName);
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
		//DebugLog("[%s]GetClientTeam[%s]=%d",eventName,clientName,GetClientTeam(client));
		//DebugLog("[%s]PlayerTeam[%s]=%d",eventName,clientName,PlayerTeam[client]);		
		#endif	
		if (PlayerTeam[client]==0) // Player only change class (team remain at the same)
		{
			int Team=GetClientTeam(client);
			PlayerTeam[client]=Team;
			#if defined DEBUG
			//DebugLog("[%s]GetClientTeam(%s)=%d",eventName,clientName,Team);			
			//DebugLog("[%s]PlayerTeam[%s]=%d",eventName,clientName,PlayerTeam[client]);			
			#endif	
			TeamHumanPlayerCount[Team]++;
			#if defined DEBUG			
			PrintTeamHumanPlayerCount(eventName);				
			#endif	
			if (!g_Scoring){		
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==minPlayer_to_start_score)				
				{
					#if defined DEBUG
					DebugLog("[%s]Start scoring",eventName);
					#endif	
					g_Scoring=true;
					//CreateTimer(10.0,StartScoring,TIMER_FLAG_NO_MAPCHANGE);					
					StartScoring();
				}
			}
		}
	}	
}	
//**************************************************
//Action  StartScoring(Handle timer){
void StartScoring(){
//**************************************************
#if defined DEBUG
DebugLog("[StartScoring] Begin");
#endif	
if (g_Scoring) 
{
	if (g_RoundStatus==2 ) //Если состояние раунда между стартом и победой, то _restart
		{
		g_Restarting=true;
		#if defined DEBUG
		DebugLog("[StartScoring] RestartRound");
		#endif	
		#if !defined NO_COMMANDS				
		ServerCommand("mp_clan_restartround 10");//Restart round
		
		#else
		DebugLog("----------------\nmp_clan_restartround 10\n-----------------");					
		#endif		
		}
	if (g_1stRestart)
		{			
		PrintToChatAll("[%s]: \x05%s",g_PLUGIN_NAME,MSG_Resume_scoring);				
		PrintHintTextToAll("%t",MSG_Resume_scoring);
		if (!g_Restarting)	
			{			
			#if defined DEBUG
			DebugLog("[StartScoring] Restore");
			#endif	
			ReStoreTeamsScore();
			}		
		}
	else
		{				
		PrintHintTextToAll("%t",MSG_Start_scoring);
		PrintToChatAll("[%s]: \x05%s",g_PLUGIN_NAME,MSG_Start_scoring);			
		if (!g_Restarting) 		
			{			
			#if defined DEBUG
			DebugLog("[StartScoring] Reset");
			#endif					
			ReSetTeamsScore();		
			}		
		
		}		
	//EmitSoundToAll(sndGong);					
	#if defined DEBUG	
	DebugLog("[StartScoring] End");
	#endif	
}
//return Plugin_Continue;
}
//**************************************************
public void Event_PlayerTeam(Event event, const char[] name,  bool dontBroadcast){
//**************************************************
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if defined DEBUG
	char eventName [32];event.GetName(eventName,31);
	char clientName[32];GetClientName(client, clientName, 31);
	DebugLog("[%s] #%d %s team %d->%d",eventName,client,clientName,event.GetInt("oldteam"),event.GetInt("team"));	
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
			PrintTeamHumanPlayerCount("Event_PlayerTeam");			
			#endif
			if (g_Scoring)
			{		
				if (!g_awaitStopScoring)
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==minPlayer_to_start_score-1 || TeamHumanPlayerCount[DOD_TEAM_ALLIES]==0 && TeamHumanPlayerCount[DOD_TEAM_AXIS]==0)
				{	
					g_awaitStopScoring=true;
					CreateTimer(10.0,StopScoring,TIMER_FLAG_NO_MAPCHANGE);													
				}
				/*if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]==0 && TeamHumanPlayerCount[DOD_TEAM_AXIS]==0) 
				{
					g_1stRestart=false;
					ReSetTeamsScore();
				}*/
			}
		}	
	}	
}
//**************************************************
Action  StopScoring(Handle timer){
//**************************************************
if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]<minPlayer_to_start_score)
	{
	#if defined DEBUG
	DebugLog("Stopscoring");								
	#endif		
	g_Scoring=false;
	if (!g_Restarting)
		{							
		StoreTeamsScore();
		PrintHintTextToAll("%t",MSG_Stop_scoring);
		PrintToChatAll("[%s]: \x05%s",g_PLUGIN_NAME,MSG_Stop_scoring);		
		}
	}	
#if defined DEBUG
else 
	{
	DebugLog("No Stopscoring");								
	}
#endif	
if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]==0 && TeamHumanPlayerCount[DOD_TEAM_AXIS]==0) 
	{
	g_1stRestart=false;
	ReSetTeamsScore();
	}
g_awaitStopScoring=false;	
return Plugin_Continue;
}	
//**************************************************
public void OnCvar_minPlayer_to_start_score(ConVar convar, char[] oldValue, char[] newValue){
//**************************************************	
	minPlayer_to_start_score=StringToInt(newValue);
	if (!g_Scoring)	
		if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]>=minPlayer_to_start_score)
		{
			g_Scoring=true;
			//CreateTimer(1.0,StartScoring,TIMER_FLAG_NO_MAPCHANGE);		
			StartScoring();
		}
}
#if defined DEBUG
public  Action cmdPrintTeamHumanPlayerCount (int client, int args){
	PrintTeamHumanPlayerCount("cmdPrintTeamHumanPlayerCount");	
	int HMS[3];
	GetTimeHMS(HMS);
	for (int i=1;i!=MAX_PLAYERS;i++)
	{
		if (__test)
			{
			PrintCenterText(i, "%02d:%02d:%02d",HMS[0],HMS[1],HMS[2]);
			PrintHintText(i, "\x04Raund # 23");
			PrintToChat(i, "\x05Raund # 23 \x0412:34");
			}
		else{
			PrintCenterText(i, "Raund # 23");
			PrintHintText(i, "%02d:%02d:%02d",HMS[0],HMS[1],HMS[2]);
			PrintToChat(i, "\x04Raund # 23 \x0512:34");
			}
	}
	
	//PrintCenterTextAll(const char[] format, any... ...)
	//PrintHintTextToAll(const char[] format, any... ...)
	//PrintToChatAll(const char[] format, any... ...)	
	//__test=!__test;
	
	return Plugin_Handled;
}
void PrintTeamHumanPlayerCount (char[] FromProc){
	DebugLog("[%s] Allies team =%d Axis team=%d min_to_score=%d",FromProc,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],minPlayer_to_start_score);		
	}
#endif 
public void PrintTime(){int HMS[3];
if (g_minutePrinted!=HMS[1]){g_minutePrinted=HMS[1];GetTimeHMS(HMS);PrintToChatAll("%02d:%02d",HMS[0],HMS[1]);PrintHintTextToAll("%02d:%02d",HMS[0],HMS[1]);}}
public void Event_RoundRestart(Event event, const char[] name, bool dontBroadcast){EmitSoundToAll(sndGong);						}
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){g_RoundStatus=1;}
public void Event_RoundActive(Event event, const char[] name, bool dontBroadcast){
#if defined DEBUG
	DebugLog("Event_RoundActive");
#endif 
g_RoundStatus=2;
PrintTime();
if (g_Scoring)
	{
	g_cntRound++;
	PrintCenterTextAll("Round # %d",g_cntRound);
	int HMS[3];GetTimeHMS(HMS);PrintHintTextToAll("%02d:%02d",HMS[0],HMS[1],HMS[2]);
	if (g_Restarting)
		{
		g_Restarting=false;		
		if (g_1stRestart)
			{
			ReStoreTeamsScore();
			}	
		else
			{
			g_1stRestart=true;
			}
		}
	}
}
public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast){g_RoundStatus=0;}

#endinput
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
