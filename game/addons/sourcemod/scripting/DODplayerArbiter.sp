#define DEBUG 1
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "DoD player arbiter"
#define GAME_DOD
#define SND_GONG "k64t\\knifefinal\\knifefinal.mp3" 
#define MSG1 "It`s time"
#include "k64t"
// Global Var
float PlayerSpawnPosition[MAX_PLAYERS][3];
int PlayerTeam[MAX_PLAYERS];
int TeamHumanPlayerCount[DOD_TEAM_AXIS+1];
//ConVar 
ConVar sm_arbiter_minPlayer_to_start_score;
int minPlayer_to_start_score=0;
public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "Kom64t",
    description = "",
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
//char buffer[MAX_FILENAME_LENGHT];
//Format(buffer, MAX_FILENAME_LENGHT, /*"download\\*/"sound\\%s",SND_GONG);	
//AddFileToDownloadsTable(buffer);
//PrecacheSound(sndGong,true);
sm_arbiter_minPlayer_to_start_score = CreateConVar("sm_arbiter_minPlayer_to_start_score", "0", "Count of player to start score",_,true,0.0/*,true,float(MaxClients)*/);
if (sm_arbiter_minPlayer_to_start_score != null)
{
	sm_arbiter_minPlayer_to_start_score.AddChangeHook(OnCvar_minPlayer_to_start_score);
	AutoExecConfig(true, "DODplayerArbiter");
	minPlayer_to_start_score=GetConVarInt(sm_arbiter_minPlayer_to_start_score);
}
//HookEvent("dod_round_win", Event_RoundWin, EventHookMode_Post);
//HookEvent("player_spawn",		Event_PlayerSpawn,		EventHookMode_Post);
HookEvent("player_team",	Event_PlayerTeam,	EventHookMode_Post);// A player changed his team  https://wiki.alliedmods.net/Generic_Source_Events#player_team
HookEvent("player_changeclass",	Event_PlayerClass,	EventHookMode_Post);
//HookEvent("player_death", Event_RoundWin, EventHookMode_Post);
}
//public void OnPluginEnd(){}
public void OnMapStart(){
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
	for (int client = 1; client <=MaxClients ; client++)PlayerTeam[client]=0;	
	#if defined DEBUG
	CalculateTeamHumanPlayerCount();
	#endif
}
//public void Event_PlayerSpawn(Event event, const char[] name,  bool dontBroadcast){}
void CalculateTeamHumanPlayerCount(){
	TeamHumanPlayerCount[DOD_TEAM_ALLIES]=0;
	TeamHumanPlayerCount[DOD_TEAM_AXIS]=0;
	int Team;
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
		{
			#if !defined DEBUG
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
public void Event_PlayerClass(Event event, const char[] name,  bool dontBroadcast){
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if !defined DEBUG
	if (!IsFakeClient(client))
	#endif	
	{
		#if defined DEBUG
		PrintToServer("PlayerTeam[%d]=%d",client,PlayerTeam[client]);
		#endif	
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
			if (TeamHumanPlayerCount[DOD_TEAM_ALLIES]+TeamHumanPlayerCount[DOD_TEAM_AXIS]==minPlayer_to_start_score)
			{		
			
				//SetTeamScore(DOD_TEAM_ALLIES, 0);//Reset score
				//SetTeamScore(DOD_TEAM_AXIS, 0);				
				//SetTeamRoundsWon(DOD_TEAM_ALLIES, 0);
				//SetTeamRoundsWon(DOD_TEAM_AXIS, 0);		


				//Если состояние раунда между старт и победа. Если состояние раунда бонус, то только очистить счет		
				ServerCommand("mp_clan_restartround 10");//Restart round
			}
		}
	}
	#if defined DEBUG
	ShowTeamHumanPlayerCount();
	#endif
}	
public void Event_PlayerTeam(Event event, const char[] name,  bool dontBroadcast){
	int client=GetClientOfUserId(event.GetInt("userid"));
	#if !defined DEBUG
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
		}	
	}	
}
public void OnCvar_minPlayer_to_start_score(ConVar convar, char[] oldValue, char[] newValue){
	minPlayer_to_start_score=StringToInt(newValue);
	if (StringToInt(oldValue)!=minPlayer_to_start_score)
	{
		minPlayer_to_start_score=minPlayer_to_start_score;
	}	
}
#if defined DEBUG
public  Action cmdShowTeamHumanPlayerCount (int client, int args){
	ShowTeamHumanPlayerCount();	
	return Plugin_Handled;
}
void ShowTeamHumanPlayerCount (){	PrintToServer("ALLIES=%d\tAXIS=%d",TeamHumanPlayerCount[DOD_TEAM_ALLIES],TeamHumanPlayerCount[DOD_TEAM_AXIS]);}

#endif 
#endinput
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 













public void Event_PlayerClass(Event event, const char[] name,  bool dontBroadcast){	
	char EventName[MAX_CLIENT_NAME];
	GetEventName(event,EventName,MAX_CLIENT_NAME);
	char ClientName[MAX_CLIENT_NAME];
	GetClientName(GetClientOfUserId(event.GetInt("userid")), ClientName, MAX_CLIENT_NAME);
	DebugPrint("<%s> %d - %s.",EventName,GetClientOfUserId(event.GetInt("userid")),ClientName);	

	TeamHumanPlayerCount[GetClientTeam(GetClientOfUserId(event.GetInt("userid")))]++;
	ShowTeamHumanPlayerCount();

	DebugPrint("%d - %d.",GetClientOfUserId(event.GetInt("userid")),
	GetClientTeam(GetClientOfUserId(event.GetInt("userid"))));	
}	
public void Event_PlayerTeam(Event event, const char[] name,  bool dontBroadcast){	
	char ClientName[MAX_CLIENT_NAME];
	GetClientName(GetClientOfUserId(event.GetInt("userid")), ClientName, MAX_CLIENT_NAME);
	char EventName[MAX_CLIENT_NAME];
	GetEventName(event,EventName,MAX_CLIENT_NAME);
	DebugPrint("<%s> %d - %s.",EventName,GetClientOfUserId(event.GetInt("userid")),ClientName);	
	int oldTeam=event.GetInt("oldteam");	
	int newTeam=event.GetInt("team");	
	if ((oldTeam==DOD_TEAM_ALLIES || oldTeam==DOD_TEAM_AXIS) && newTeam!=oldTeam )	
	{
		TeamHumanPlayerCount[oldTeam]--;
	    ShowTeamHumanPlayerCount();
	}
}























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


