#define DEBUG 1
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "DoD player arbiter"
#define GAME_DOD
#define SND_GONG "k64t\\knifefinal\\knifefinal.mp3" 
#define MSG1 "It`s time"
#include "k64t"

// Global Var
//int g_1stChange=0;
//ConVar Cvar_mp_limitteams;
float PlayerSpawnPosition[MAX_PLAYERS][3];

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
#endif 
LoadTranslations("DODplayerArbiter.phrases");
//char buffer[MAX_FILENAME_LENGHT];
//Format(buffer, MAX_FILENAME_LENGHT, /*"download\\*/"sound\\%s",SND_GONG);	
//AddFileToDownloadsTable(buffer);
//PrecacheSound(sndGong,true);
//AutoExecConfig(true, "knifeFinal");
//HookEvent("dod_round_win", Event_RoundWin, EventHookMode_Post);
HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
//HookEvent("player_death", Event_RoundWin, EventHookMode_Post);
}
//public void OnPluginEnd(){}
//public void OnMapStart(){}
public void Event_PlayerSpawn(Event event, const char[] name,  bool dontBroadcast){	
	
}

public void Event_RoundWin(Event event, const char[] name,  bool dontBroadcast){	
	if (Cvar_dod_bonusroundtime.IntValue==0)teamsSwap(0);
	else
	{		
		PrintToChatAll("\x01\x04Teams will be swapped in %i seconds", Cvar_dod_bonusroundtime.IntValue);
		CreateTimer(float(Cvar_dod_bonusroundtime.IntValue),Delay_teamsSwap,_,TIMER_FLAG_NO_MAPCHANGE);		
	}
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


