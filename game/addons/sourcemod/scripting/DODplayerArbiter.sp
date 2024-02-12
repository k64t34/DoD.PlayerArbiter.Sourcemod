// Sourcemod forum 
// result search  m_iDeaths, dod, dods, dod:s https://forums.alliedmods.net/search.php?searchid=43934563
// restorescore //https://forums.alliedmods.net/showthread.php?t=188378&highlight=m_iDeaths+dod+dods+dod%3As
//save score https://forums.alliedmods.net/showthread.php?t=74975&highlight=m_iDeaths+dod+dods+dod%3As
// DoD:S getting/changing player objectives scores https://forums.alliedmods.net/showthread.php?t=92508&highlight=m_iDeaths+dod+dods+dod%3As
 


//*
//* DoD:S Players(bots)  arbiter for DODs
//*
//* Version 1.1
//*
//* Description:
//*   1.0 2021 The plugin restart score when count of players rise to 6
//*   1.1 2023 The plugin refresh  bots every minute, simply removing all useless ones (no frags, no flag capture/blocking, no bomb plant/defusing).
//*   1.2 2023 The plugin reset, save,restore scoring when  start, stop, resume scoring.
//*   1.8 2023 Add team Balance
//*Параметры запуска из Notepad++ по F5 c:\Users\skorik\source\repos\sourcemod-1.10.0-git6502-windows\addons\sourcemod\scripting\SMcompiler.exe  $(FULL_CURRENT_PATH)
#define nDEBUG 
#define LOG
#define PLUGIN_VERSION "1.8"
#define PLUGIN_NAME "DoD player arbiter"
#define PLUGIN_AUTHOR "Kom64t"
#define GAME_DOD
#define USE_PLAYER
#include "k64t"
#define IGNORE_BOTS  //for debug define noIGNORE_BOTS
#define noNO_COMMANDS 
#define REFRESH_BOT   //ver 1.1
#define AntiBotTK // ver 1.7
#define WEAPON_BALANCE_WARN // ver 1.8
#define noBALANCE // ver 1.9
#if defined DEBUG  
#define nDEBUG_A   //Arbiter 
#define DEBUG_WBW //WEAPON_BALANCE_WARN											
#endif 


#define SND_GONG "k64t\\whistle.mp3" 
#define MSG_Start_scoring	"Start scoring"
char str_MSG_Start_scoring[]=MSG_Start_scoring;
#define MSG_Stop_scoring	"Stop scoring"
char str_MSG_Stop_scoring[]=MSG_Stop_scoring;
#define MSG_Resume_scoring	"Resume scoring" //ver 1.2
char str_MSG_Resume_scoring[]=MSG_Resume_scoring;
#define MSG_Round			"Round" //ver 1.5
// Global Var
int g_cntRound=0;							// Scoring round counter ver 1.3
int g_minutePrinted=-1;						// Last printed minute
bool g_awaitStopScoring=false;				// true - waiting, false - no waiting
Handle h_TimerScoring=INVALID_HANDLE;   //Handle timer

//char g_PLUGIN_NAME[]=PLUGIN_NAME;           // Plugin name
int PlayerTeam[MAX_PLAYERS];				// Команда игрока int[] PlayerTeam = new int[MaxClients]			// Команда игрока
int TeamHumanPlayerCount[DOD_TEAMS_COUNT];	// Number of human players in a team
int TeamBotPlayerCount[DOD_TEAMS_COUNT];	// Number of bot players in a team
char sndGong[]=SND_GONG;					// The sound of the beginning of scoring
bool g_Scoring=false;						// Scoring in progress
bool g_1stRestart=false;					// true - first round with scoring has already passed, false - no restart occur
bool g_Restarting=false;					// Command _restart 10 was sent
int g_RoundStatus=0;						// Дает варнинг. Временно убрал использование переменной для праильной работы парсинга лога Бритва см.ниже комментарии 
											// Time period of round:0-Bonus,1-Start,2-Active
int g_PlayersCount=0;						// Players in game 					
#if defined WEAPON_BALANCE_WARN											
int PlayerClassCount[DOD_TEAMS_COUNT][DOD_ClassCount]; // Количество игроков каждого класса в каждой команде
int PlayerClass[MAX_PLAYERS]; // Player`s game Class (weapon) 
Handle hWEAPON_BALANCE_WARN=INVALID_HANDLE ;
#endif											
//ConVar 
ConVar sm_arbiter_minPlayer_to_start_score;
int minPlayer_to_start_score=0;
public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = "Restart score, kick week bots, less TK",
    version = PLUGIN_VERSION,
    url = "https://github.com/k64t34/DoD.PlayerArbiter.Sourcemod.git"
};
#include "DODplayerArbiter.TeamScore.inc" 
//#include "DODplayerArbiter.PlayerSpawn.inc"
#if defined REFRESH_BOT
#include "DODplayerArbiter.Refreshbots.inc"
#endif

#if defined AntiBotTK
#include "DODplayerArbiter.AntiBotTK.inc"
#endif

#if defined BALANCE
#include "DODplayerArbiter.balance"
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
sm_arbiter_minPlayer_to_start_score = CreateConVar("sm_arbiter_minPlayer_to_start_score", "2", "Count of player to start score",_,true,0.0/*,true,float(MaxClients)*/);
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
#if defined AntiBotTK
HookEvent("player_hurt",Event_player_hurt, EventHookMode_Pre);
#endif 	
#if defined BALANCE
RegConsoleCmd("say", 		Command_Say);//https://wiki.alliedmods.net/Talk:Introduction_to_sourcemod_plugins
RegConsoleCmd("say_team",	Command_Say);
#endif

#if defined DEBUG
RegConsoleCmd("arb_status",	Command_Status,"Only for debug DODPlayerArbiter.sp");
#endif 
}
//***********************************************
public void OnPluginEnd(){
//***********************************************	
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
#if defined AntiBotTK
UnhookEvent("player_hurt",Event_player_hurt, EventHookMode_Pre);
#endif 	
#if defined BALANCE

#endif 	
}
//**************************************************
public void OnMapStart(){
//**************************************************	
	#if defined DEBUG
	DebugLog("[OnMapStart] start");
	#endif
	g_cntRound=0;	
	g_PlayersCount=0
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;		
	TeamBotPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamBotPlayerCount[DOD_TEAM_AXIS]=0;	
	ReSetTeamsScore();
	#if defined DEBUG_A
	PrintTeamHumanPlayerCount("OnMapStart");			
	#endif
	#if defined WEAPON_BALANCE_WARN												
	for	(int i=0;i!=DOD_TEAMS_COUNT;i++)for	(int j=0;j!=DOD_ClassCount;j++)PlayerClassCount[i][j]=0;
	#endif											
	for (int client = 1; client !=MAX_PLAYERS ; client++)
		{
		PlayerTeam[client]=0;
		#if defined WEAPON_BALANCE_WARN	
		PlayerClass[client]=DOD_NoClass;
		#endif
		}
	#if defined DEBUG
	CalculateTeamHumanPlayerCount();			
	PrintTeamHumanPlayerCount("OnMapStart");				
	if (g_PlayersCount >= minPlayer_to_start_score)
		{
		DebugLog("[OnMapStart]g_Scoring=true");
		g_Scoring=true;
		}
	g_1stRestart=false;
	#endif
	
	#if defined REFRESH_BOT
	if (h_TimerRefreshbot==INVALID_HANDLE)h_TimerRefreshbot=CreateTimer(60.0,Refreshbot,0,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	#endif
	#if defined BALANCE
	g_Balance_vote_status=0;
	g_Balance_last_vote=0;
	#endif 	
	
	#if defined DEBUG
	DebugLog("[OnMapStart] finish ");
	#endif	
}
//**************************************************
public void OnMapEnd(){
//**************************************************	
#if defined DEBUG
	DebugLog("[OnMapEnd]");
#endif
g_Scoring=false;
g_1stRestart=false;
if (g_awaitStopScoring)
{	
	if (h_TimerScoring!=INVALID_HANDLE)
	KillTimer(h_TimerScoring,true);
	g_awaitStopScoring=false;
}
#if defined WEAPON_BALANCE_WARN	
if (hWEAPON_BALANCE_WARN!=INVALID_HANDLE) 
	{
	KillTimer(hWEAPON_BALANCE_WARN,true);
	hWEAPON_BALANCE_WARN=INVALID_HANDLE;
	}
#endif


#if defined LOG
if (GetTeamRoundsWon(DOD_TEAM_ALLIES)!=0 || GetTeamScore(DOD_TEAM_ALLIES)!=0 || GetTeamRoundsWon(DOD_TEAM_AXIS)!=0 || GetTeamScore(DOD_TEAM_AXIS)!=0)
LogMessage("[OnMapEnd] Rounds # %d. Teams:allies %d, axis %d. Score: allies %d(%d), axis %d(%d). ",g_cntRound,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],GetTeamRoundsWon(DOD_TEAM_ALLIES),GetTeamScore(DOD_TEAM_ALLIES),GetTeamRoundsWon(DOD_TEAM_AXIS),GetTeamScore(DOD_TEAM_AXIS));
#endif
}
//**************************************************
stock void CalculateTeamHumanPlayerCount(){
//**************************************************	
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
	TeamBotPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamBotPlayerCount[DOD_TEAM_AXIS]=0;
	int Team,Class;
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsValidClient(i))
		{
			Team=GetClientTeam(i);
			if (Team==DOD_TEAM_ALLIES || Team==DOD_TEAM_AXIS)
			{
				Class=GetDODPlayerClass(i)
				if (Class!=DOD_NoClass)
				{
					PlayerTeam[i]=Team;
					if (IsFakeClient(i)){TeamBotPlayerCount[Team]++;}
					#if defined IGNORE_BOTS
					if (!IsFakeClient(i))
					#endif
						{
						TeamHumanPlayerCount[Team]++;
						#if defined WEAPON_BALANCE_WARN	
						PlayerClass[i]=Class;								
						PlayerClassCount[Team][PlayerClass[i]]++;							
						#endif											
						}
				}
			}
			#if defined DEBUG_A
			PrintTeamHumanPlayerCount("Event_PlayerTeam");
			#endif
		}			
	}
	g_PlayersCount=TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS];	
}

//**************************************************
public void Event_PlayerTeam(Event event, const char[] name,  bool dontBroadcast){
//**************************************************
	int client=GetClientOfUserId(event.GetInt("userid"));
	int oldTeam=event.GetInt("oldteam");	
	int newTeam=event.GetInt("team");	
	int oldClass=PlayerClass[client];//GetDODPlayerClass(client);	
	#if defined DEBUG_A || defined DEBUG_WBW
	char eventName [32];event.GetName(eventName,31);
	char clientName[32];GetClientName(client, clientName, 31);
	DebugLog("[%s] #%d %s team %d->%d class var=%d func=%d",eventName,client,clientName,oldTeam,newTeam,PlayerClass[client],GetDODPlayerClass(client));	
	#endif			
	
	if ((oldTeam==DOD_TEAM_ALLIES || oldTeam==DOD_TEAM_AXIS) && newTeam!=oldTeam )	
	{
		if (IsFakeClient(client)) 
			TeamBotPlayerCount[oldTeam]--;//=TeamBotPlayerCount[oldTeam]-1;
		#if defined IGNORE_BOTS
		if (!IsFakeClient(client))
		#endif	
			{TeamHumanPlayerCount[oldTeam]--;g_PlayersCount--;
			#if defined WEAPON_BALANCE_WARN		
			PlayerClass[client]=DOD_NoClass;
			PlayerClassCount[oldTeam][oldClass]--;
			#if defined DEBUG_WBW
			DebugLog("[%s] PlayerClass[%d]==%d",eventName,client,PlayerClass[client]);			
			DebugLog("[%s] PlayerClassCount[%d][%d]-- -> %d",eventName,oldTeam,oldClass,PlayerClassCount[oldTeam][oldClass]);	
			#endif
				
				#if defined LOG				
				if (PlayerClassCount[oldTeam][oldClass]<0)
					LogMessage("[Event_PlayerTeam] PlayerClassCount[%d][%d]=%d  < 0", oldTeam,oldClass,PlayerClassCount[oldTeam][oldClass]); 
				#endif
			#endif
			}
		PlayerTeam[client]=0; // While no class has been selected player team set to 0. Its need to determinide than player change (not 1st set) class 
		
		if (g_Scoring)
			{		
			if (!g_awaitStopScoring)
			if (g_PlayersCount==minPlayer_to_start_score-1 || TeamHumanPlayerCount[DOD_TEAM_ALLIES]==0 && TeamHumanPlayerCount[DOD_TEAM_AXIS]==0)
				{	
				g_awaitStopScoring=true;
				h_TimerScoring=CreateTimer(15.0,StopScoring,TIMER_FLAG_NO_MAPCHANGE);
				}
			/*if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]==0 && TeamHumanPlayerCount[DOD_TEAM_AXIS]==0) 
			{
				g_1stRestart=false;
				ReSetTeamsScore();
			}*/
			}
	}		
	#if defined DEBUG_A
	PrintTeamHumanPlayerCount("Event_PlayerTeam");
	#endif
}

//**************************************************
public void Event_PlayerClass(Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
	int client=GetClientOfUserId(event.GetInt("userid"));
	if (client==0) {LogError("Event_PlayerClass get client index 0");return;}
	int oldClass = PlayerClass[client];//GetDODPlayerClass(client);
	int newClass = event.GetInt("class");
	int Team=GetClientTeam(client);
	#if defined DEBUG_A || defined DEBUG_WBW
	char eventName [32];event.GetName(eventName,31);
	char clientName[32];GetClientName(client, clientName, 31);
	#endif
	#if defined DEBUG_A || defined DEBUG_WBW
	//DebugLog("[%s] #%d %s",eventName,client,clientName);	
	DebugLog("[%s] #%d %s team %d class=var %d(func %d) -> %d ",eventName,client,clientName,Team,oldClass,GetDODPlayerClass(client),newClass);
	#endif
	#if defined REFRESH_BOT
	BotKills[client]=0;
	BotToKick[client]=false;
	#endif		
	#if defined DEBUG_A
	DebugLog("[%s]GetClientTeam[%s]=%d",eventName,clientName,Team);
	DebugLog("[%s]PlayerTeam[%s]=%d",eventName,clientName,PlayerTeam[client]);		
	#endif		
	#if defined WEAPON_BALANCE_WARN
		#if defined IGNORE_BOTS
	if (!IsFakeClient(client))
		#endif	
		{
		if (oldClass!=DOD_NoClass)
			{
			PlayerClassCount[Team][oldClass]--;
			#if defined LOG		
			if (PlayerClassCount[Team][oldClass]<0)
				LogMessage("[Event_PlayerClass] PlayerClassCount[%d][%d]=%d  < 0", Team,oldClass,PlayerClassCount[Team][oldClass]); 
			#endif
			}
		//else SetDODPlayerClass(client,newClass); // Тут я влез в работу движка. Возможно из-за этого будут проблемы. Глюк проявляется в выкидывании клиента и закрытии hl2.exe
		
		PlayerClassCount[Team][newClass]++;
		PlayerClass[client]=newClass;
		#if defined LOG		
		if (PlayerClassCount[Team][newClass]>MAX_PLAYERS)
			LogMessage("[Event_PlayerClass] PlayerClassCount[%d][%d]=%d  > %d", Team,newClass,PlayerClassCount[Team][newClass],MAX_PLAYERS); 
		#endif
		}	
	#endif
	if (PlayerTeam[client]==0) // Player only change class (team remain at the same)
		{
		PlayerTeam[client]=Team;
		//#if defined DEBUG
		//DebugLog("[%s]GetClientTeam(%s)=%d",eventName,clientName,Team);			
		//DebugLog("[%s]PlayerTeam[%s]=%d",eventName,clientName,PlayerTeam[client]);			
		//#endif	
		if (IsFakeClient(client)) TeamBotPlayerCount[Team]++;//=TeamBotPlayerCount[Team]+1;		
		
		#if defined IGNORE_BOTS
		if (!IsFakeClient(client))
		#endif	
		{TeamHumanPlayerCount[Team]++;g_PlayersCount++;}

		#if defined DEBUG_A			
		PrintTeamHumanPlayerCount(eventName);				
		#endif					
		if (!g_Scoring)
			{		
			if (g_PlayersCount==minPlayer_to_start_score)				
				{
				#if defined DEBUG_A
				DebugLog("[%s]Start scoring",eventName);
				DebugLog("[%s]g_Scoring=true;",eventName);
				#endif	
				g_Scoring=true;				
				StartScoring();//CreateTimer(10.0,StartScoring,TIMER_FLAG_NO_MAPCHANGE);					
				}
			}
		}
		#if defined WEAPON_BALANCE_WARN					
		if (hWEAPON_BALANCE_WARN==INVALID_HANDLE)
			{		
			#if defined DEBUG_WBW		
			DebugLog("[%s]g_PlayersCount>=minPlayer_to_start_score && g_PlayersCount<=16 && TeamHumanPlayerCount[DOD_TEAM_ALLIES] != TeamHumanPlayerCount[DOD_TEAM_AXIS]",eventName);
			DebugLog("[%s]%d>=%d && %d<=16 && %d!= %d",eventName,g_PlayersCount,minPlayer_to_start_score,g_PlayersCount,TeamHumanPlayerCount[DOD_TEAM_ALLIES] ,TeamHumanPlayerCount[DOD_TEAM_AXIS]);
			#endif
			//#if defined DEBUG_WBW		
			//#else
			if (TeamHumanPlayerCount[DOD_TEAM_ALLIES] != TeamHumanPlayerCount[DOD_TEAM_AXIS] )
			//#endif 
				{
				int wTeam;
				if (TeamHumanPlayerCount[DOD_TEAM_ALLIES] >TeamHumanPlayerCount[DOD_TEAM_AXIS])	wTeam=DOD_TEAM_ALLIES;else wTeam=DOD_TEAM_AXIS;
				#if defined DEBUG_WBW				
				DebugLog("[%s] AllIES MG=%d R=%d AXIS MG=%d R=%d",eventName,PlayerClassCount[DOD_TEAM_ALLIES][DOD_MG],PlayerClassCount[DOD_TEAM_ALLIES][DOD_Rocket],PlayerClassCount[DOD_TEAM_AXIS][DOD_MG],PlayerClassCount[DOD_TEAM_AXIS][DOD_Rocket]);
				#endif 
				if(PlayerClassCount[wTeam][DOD_MG]>0 || PlayerClassCount[wTeam][DOD_Rocket] > 0)
				if (g_PlayersCount>=minPlayer_to_start_score && g_PlayersCount<=16)		
					{					
					#if defined DEBUG_WBW
					hWEAPON_BALANCE_WARN=CreateTimer(0.5,WeaponBalanceWarning,TIMER_FLAG_NO_MAPCHANGE);
					#else
					hWEAPON_BALANCE_WARN=CreateTimer(3.0,WeaponBalanceWarning,TIMER_FLAG_NO_MAPCHANGE);
					#endif		
					}
				}
			}		
	    #endif

			
}
//**************************************************
void StartScoring(){ //Action  StartScoring(Handle timer)
//**************************************************
#if defined DEBUG_A
DebugLog("[StartScoring] Begin");
#endif	
if (g_Scoring) 
{
	//убрал для парсинга лога Britvы // if (g_RoundStatus==2 ) //Если состояние раунда между стартом и победой, то _restart
	if (!g_1stRestart ) 
		{
		g_Restarting=true;
		LogToGame("Restart round");
		#if defined LOG
		LogMessage("Restart round");		
		#elseif defined DEBUG_A
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
		PrintToChatAll("%t",str_MSG_Resume_scoring);				
		PrintHintTextToAll("%t",str_MSG_Resume_scoring);
		LogToGame(str_MSG_Resume_scoring);
		#if defined LOG
		LogMessage(str_MSG_Resume_scoring);
		#endif
		if (!g_Restarting)	
			{			
			#if defined DEBUG_A
			DebugLog("[StartScoring] Restore");		
			#endif	
			ReStoreTeamsScore();
			}		
		}
	else
		{				
		PrintHintTextToAll("%t",str_MSG_Start_scoring);
		PrintToChatAll("%t",str_MSG_Start_scoring);
		LogToGame(str_MSG_Start_scoring);
		#if defined LOG
		LogMessage(str_MSG_Start_scoring);
		#endif
		if (!g_Restarting) 		
			{			
			#if defined DEBUG_A
			DebugLog("[StartScoring] Reset");
			#endif					
			ReSetTeamsScore();		
			}		
		
		}		
	//EmitSoundToAll(sndGong);					
	#if defined DEBUG_A	
	DebugLog("[StartScoring] End");
	#endif	
}
//return Plugin_Continue;
}

//**************************************************
Action  StopScoring(Handle timer){
//**************************************************
h_TimerScoring=INVALID_HANDLE;
if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]<minPlayer_to_start_score)
	{
	#if defined DEBUG_A
	DebugLog("Stopscoring");								
	#endif		
	g_Scoring=false;
	if (!g_Restarting)
		{							
		StoreTeamsScore();
		PrintHintTextToAll("%t",str_MSG_Stop_scoring);
		PrintToChatAll("%t",str_MSG_Stop_scoring);
		LogToGame(str_MSG_Stop_scoring);
		#if defined LOG
		LogMessage(str_MSG_Stop_scoring);
		#endif
		}
	}	
#if defined DEBUG_A
else 
	{	DebugLog("No Stopscoring");									}
#endif	
// //убрал для парсинга лога
//if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]==0 && TeamHumanPlayerCount[DOD_TEAM_AXIS]==0) 
//	{
//	g_1stRestart=false;
//	ReSetTeamsScore();
//	}
g_awaitStopScoring=false;	
return Plugin_Continue;
}	
 
//**************************************************
Action  WeaponBalanceWarning(Handle timer){
//**************************************************
	hWEAPON_BALANCE_WARN=INVALID_HANDLE;
	#if defined DEBUG_WBW
	DebugLog("WeaponBalanceWarning");									
	#endif		
	#if defined DEBUG_WBW		
	DebugLog("g_PlayersCount>=minPlayer_to_start_score && g_PlayersCount<=16 && TeamHumanPlayerCount[DOD_TEAM_ALLIES] != TeamHumanPlayerCount[DOD_TEAM_AXIS]");
	DebugLog("%d>=%d && %d<=16 && %d!= %d",g_PlayersCount,minPlayer_to_start_score,g_PlayersCount,TeamHumanPlayerCount[DOD_TEAM_ALLIES] ,TeamHumanPlayerCount[DOD_TEAM_AXIS]);
	#endif
	//#if defined DEBUG_WBW		
	//#else
	if (TeamHumanPlayerCount[DOD_TEAM_ALLIES] != TeamHumanPlayerCount[DOD_TEAM_AXIS] )
	//#endif 
		{
		int wTeam;
		if (TeamHumanPlayerCount[DOD_TEAM_ALLIES] >TeamHumanPlayerCount[DOD_TEAM_AXIS])	wTeam=DOD_TEAM_ALLIES;else wTeam=DOD_TEAM_AXIS;
		#if defined DEBUG_WBW				
		DebugLog("AllIES MG=%d R=%d AXIS MG=%d R=%d",PlayerClassCount[DOD_TEAM_ALLIES][DOD_MG],PlayerClassCount[DOD_TEAM_ALLIES][DOD_Rocket],PlayerClassCount[DOD_TEAM_AXIS][DOD_MG],PlayerClassCount[DOD_TEAM_AXIS][DOD_Rocket]);
		#endif 
		if(PlayerClassCount[wTeam][DOD_MG]>0 || PlayerClassCount[wTeam][DOD_Rocket] > 0)
		if (g_PlayersCount>=minPlayer_to_start_score && g_PlayersCount<=16)		
			{					
			for (int client=1;client<=MaxClients;client++)
				{			
				if (IsValidClient(client))
				if (GetClientTeam(client)==wTeam)			
					{							
					PrintHintText(client,"STOP USE ROCKET OR MACHINE GUN");			
					PrintToChat(client,"\x07%XSTOP USE ROCKET OR MACHINE GUN",0xFF4040);//DebugLog("[WeaponBalanceWarning] client=%d class=%d",client,GetDODPlayerClass(client));
					//PrintToChat(client,"\n!!!STOP USE ROCKET OR MACHINE GUN!!!\n");//DebugLog("[WeaponBalanceWarning] client=%d class=%d",client,GetDODPlayerClass(client));
					}
				}	
			}
		}			
// DebugLog("%d>=%d && %d<=16 && %d!= %d",g_PlayersCount,minPlayer_to_start_score,g_PlayersCount,TeamHumanPlayerCount[DOD_TEAM_ALLIES] ,TeamHumanPlayerCount[DOD_TEAM_AXIS]);
// #else	
// if (g_PlayersCount>=minPlayer_to_start_score && g_PlayersCount<=16 && TeamHumanPlayerCount[DOD_TEAM_ALLIES] != TeamHumanPlayerCount[DOD_TEAM_AXIS] )
// #endif	
	// {
	// int wTeam=0;
	// if (TeamHumanPlayerCount[DOD_TEAM_ALLIES] >TeamHumanPlayerCount[DOD_TEAM_AXIS])	wTeam=DOD_TEAM_ALLIES;else wTeam=DOD_TEAM_AXIS;
	// #if defined DEBUG_WBW
	// DebugLog("wTeam=%d",wTeam);	
	// #endif	
	// bool sendMessage=false;
	// if (IsValidClient(Player_MG[wTeam]))
		// if (PlayerTeam[Player_MG[wTeam]]==wTeam)
			// if (GetDODPlayerClass(Player_MG[wTeam])==DOD_MG)
				// sendMessage=true;
	// if (!sendMessage)	
	// if (IsValidClient(Player_Rocket[wTeam]))
		// if (PlayerTeam[Player_Rocket[wTeam]]==wTeam)
			// if (GetDODPlayerClass(Player_Rocket[wTeam])==DOD_MG)
				// sendMessage=true;
	// if (sendMessage)	
		// for (int client=1;client<=MaxClients;client++)
			// {			
			// if (IsValidClient(client))
			// if (GetClientTeam(client)==wTeam)			
				// {
				// if (client==Player_MG[wTeam]) if (GetDODPlayerClass(Player_MG[wTeam])!=DOD_MG)Player_MG[wTeam]=0;
				//PrintHintText(client,"\x07%XSTOP USE ROCKET OR MACHINE GUN",0xFF4040);
				// PrintToChat(client,"\x07%XSTOP USE ROCKET OR MACHINE GUN",0xFF4040);//DebugLog("[WeaponBalanceWarning] client=%d class=%d",client,GetDODPlayerClass(client));
				//PrintToChat(client,"\n!!!STOP USE ROCKET OR MACHINE GUN!!!\n");//DebugLog("[WeaponBalanceWarning] client=%d class=%d",client,GetDODPlayerClass(client));
				// }
			// }	
	// }
	
	return Plugin_Continue;
}
//**************************************************
public void OnCvar_minPlayer_to_start_score(ConVar convar, char[] oldValue, char[] newValue){
//**************************************************	
	minPlayer_to_start_score=StringToInt(newValue);
	#if defined DEBUG_A
	DebugLog("[OnCvar_minPlayer_to_start_score] minPlayer_to_start_score=%d",minPlayer_to_start_score);
	#endif
	if (!g_Scoring)	
		if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]>=minPlayer_to_start_score)
		{
			#if defined DEBUG_A
			DebugLog("[OnCvar_minPlayer_to_start_score] g_Scoring=true;");
			#endif
			g_Scoring=true;			
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
public void Event_RoundRestart(Event event, const char[] name, bool dontBroadcast){
	#if defined DEBUG
	DebugLog("Event_RoundRestart");
	#endif 	
	EmitSoundToAll(sndGong);
	}
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast){
	#if defined DEBUG
	DebugLog("Event_RoundStart");
	#endif 
	g_RoundStatus=1;
	}
public void Event_RoundActive(Event event, const char[] name, bool dontBroadcast){
#if defined DEBUG
	DebugLog("Event_RoundActive");
#endif 
g_RoundStatus=2;
PrintTime();
if (g_Scoring)
	{
	g_cntRound++;
	PrintCenterTextAll("%t # %d",MSG_Round,g_cntRound);
	#if defined LOG
	LogToGame ("Round # %d. Allies %d player(s) Axis %d player(s)",g_cntRound,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS]);
	LogMessage("Round # %d. Teams:allies %d, axis %d. Score: allies %d(%d), axis %d(%d). ",g_cntRound,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],GetTeamRoundsWon(DOD_TEAM_ALLIES),GetTeamScore(DOD_TEAM_ALLIES),GetTeamRoundsWon(DOD_TEAM_AXIS),GetTeamScore(DOD_TEAM_AXIS));
	if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]<minPlayer_to_start_score && !g_awaitStopScoring)
		{
		LogMessage("[Event_RoundActive] Invalid number  of players to start scoring. Round # %d. Teams:allies %d, axis %d. Needs %d",g_cntRound,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],minPlayer_to_start_score);
		LogError  ("[Event_RoundActive] Invalid number  of players to start scoring. Round # %d. Teams:allies %d, axis %d. Needs %d",g_cntRound,TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],minPlayer_to_start_score);
		}
	#endif 
	int HMS[3];GetTimeHMS(HMS);PrintHintTextToAll("%02d:%02d",HMS[0],HMS[1]);
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
#if defined DEBUG
//***********************************************
public Action Command_Status(int client, int args){
//***********************************************
DebugLog("Status:");
DebugLog("------------------------");
int _PlayerClassCount[DOD_TEAMS_COUNT][DOD_ClassCount];for (int i=0;i!=DOD_ClassCount;i++){_PlayerClassCount[DOD_TEAM_ALLIES][i]=0;_PlayerClassCount[DOD_TEAM_AXIS][i]=0;}
int _g_PlayersCount=0;
int _g_PlayersCountFromClassCount=0;
int _TeamHumanPlayerCount[DOD_TEAMS_COUNT];_TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;_TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
DebugLog("Players: (must my_var=engine_func)");
for (int i=1;i<=MaxClients;i++)
	{			
	if (IsValidClient(i))
		{
		_g_PlayersCount++;		
		char clientName[32];GetClientName(i, clientName, 31);
		DebugLog("#%d %s team %d=%d class %d=%d %s",i,clientName,PlayerTeam[i],GetClientTeam(i),PlayerClass[i],GetDODPlayerClass(i),PlayerTeam[i]!=GetClientTeam(i) || PlayerClass[i]!=GetDODPlayerClass(i)?":ERROR":"");
		if (PlayerClass[i]!=-1)	_PlayerClassCount[PlayerTeam[i]][PlayerClass[i]]++;
		_TeamHumanPlayerCount[PlayerTeam[i]]++;
		
		}
	}
DebugLog("Classes: Allies Axis (must my_var=engine_func)");
for (int i=0;i!=DOD_ClassCount;i++)
	{				
		{
		DebugLog("#%d %d=%d %d=%d %s",i,PlayerClassCount[DOD_TEAM_ALLIES][i],_PlayerClassCount[DOD_TEAM_ALLIES][i],PlayerClassCount[DOD_TEAM_AXIS][i],_PlayerClassCount[DOD_TEAM_AXIS][i],			PlayerClassCount[DOD_TEAM_ALLIES][i]!=_PlayerClassCount[DOD_TEAM_ALLIES][i] || PlayerClassCount[DOD_TEAM_AXIS][i]!=_PlayerClassCount[DOD_TEAM_AXIS][i]?":ERROR":"");
		_g_PlayersCountFromClassCount+=PlayerClassCount[DOD_TEAM_ALLIES][i]+PlayerClassCount[DOD_TEAM_AXIS][i];		
		}
	}
DebugLog("Global vars:");
DebugLog("TeamHumanPlayerCount Allies %d=%d Axis %d=%d ",TeamHumanPlayerCount[DOD_TEAM_ALLIES],_TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS],_TeamHumanPlayerCount[DOD_TEAM_AXIS],TeamHumanPlayerCount[DOD_TEAM_ALLIES]!=_TeamHumanPlayerCount[DOD_TEAM_ALLIES] || TeamHumanPlayerCount[DOD_TEAM_AXIS]!=_TeamHumanPlayerCount[DOD_TEAM_AXIS]?":ERROR":"");
DebugLog("g_PlayersCount var=%d count_from_clinet=%d count_from_class_count=%d %s",g_PlayersCount,_g_PlayersCount,_g_PlayersCountFromClassCount,g_PlayersCount==_g_PlayersCount && g_PlayersCount==_g_PlayersCountFromClassCount?"":":ERROR");

DebugLog("------------------------");
return Plugin_Stop;
}
#endif

#endinput
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
