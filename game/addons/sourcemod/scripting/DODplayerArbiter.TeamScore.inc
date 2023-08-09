int TeamScore[DOD_TEAMS_COUNT][4];
#define TEAM_SCORE		0
#define TEAM_WINS		1
#define TEAM_KILLS		2
#define TEAM_DEATHS		3

int PlayerScore[MAXPLAYERS+1][3];
#define PLAYER_POINTS		0
#define PLAYER_KILLS		1
#define PLAYER_DEATHS		2
//**************************************************
void ReStoreTeamsScore(){
//**************************************************	
PrintTime();
#if defined DEBUG
DebugLog("ReStoreTeamsScore");			
//#elseif defined LOG
//LogMessage("ReStoreTeamsScore");
#endif	
SetTeamScore(DOD_TEAM_ALLIES,	TeamScore[DOD_TEAM_ALLIES]	[TEAM_SCORE]);
SetTeamScore(DOD_TEAM_AXIS,		TeamScore[DOD_TEAM_AXIS]	[TEAM_SCORE]);
SetTeamRoundsWon(DOD_TEAM_ALLIES,	TeamScore[DOD_TEAM_ALLIES]	[TEAM_WINS]);
SetTeamRoundsWon(DOD_TEAM_AXIS,		TeamScore[DOD_TEAM_AXIS]	[TEAM_WINS]);
SetTeamFrag(DOD_TEAM_ALLIES,TeamScore[DOD_TEAM_ALLIES]	[TEAM_KILLS]);
SetTeamFrag(DOD_TEAM_AXIS,	TeamScore[DOD_TEAM_AXIS]	[TEAM_KILLS]);
SetTeamDeaths(DOD_TEAM_AXIS,	TeamScore[DOD_TEAM_AXIS]	[TEAM_DEATHS]);
SetTeamDeaths(DOD_TEAM_ALLIES,	TeamScore[DOD_TEAM_ALLIES]	[TEAM_DEATHS]);
/*SetTeamScore(DOD_TEAM_ALLIES, GetRandomInt(10,100));
SetTeamScore(DOD_TEAM_AXIS, GetRandomInt(10,100));
SetTeamRoundsWon(DOD_TEAM_ALLIES,GetRandomInt(10,100));
SetTeamRoundsWon(DOD_TEAM_AXIS, GetRandomInt(10,100));	
*/
for (int client = 1; client !=MAXPLAYERS; client++)
	{
		if (IsValidClient(client)) 
		{
			SetDODClientFrag(client,PlayerScore[client][PLAYER_KILLS]);
			SetDODClientDeaths(client,PlayerScore[client][PLAYER_DEATHS]);
			SetDODClientPoints(client,PlayerScore[client][PLAYER_POINTS]);			
		}		
	}
}
//**************************************************
void StoreTeamsScore(){
//**************************************************	
PrintTime();
#if defined DEBUG
DebugLog("StoreTeamsScore");
//#elseif defined LOG
//LogMessage("StoreTeamsScore");			
#endif	

TeamScore[DOD_TEAM_ALLIES][TEAM_SCORE]=GetTeamScore(DOD_TEAM_ALLIES);	
TeamScore[DOD_TEAM_AXIS][TEAM_SCORE]=GetTeamScore(DOD_TEAM_AXIS);	
TeamScore[DOD_TEAM_ALLIES][TEAM_WINS]=GetTeamRoundsWon(DOD_TEAM_ALLIES);	
TeamScore[DOD_TEAM_AXIS][TEAM_WINS]=GetTeamRoundsWon(DOD_TEAM_AXIS);
TeamScore[DOD_TEAM_ALLIES]	[TEAM_KILLS] = GetTeamFrag(DOD_TEAM_ALLIES);
TeamScore[DOD_TEAM_AXIS]	[TEAM_KILLS] = GetTeamFrag(DOD_TEAM_AXIS);
TeamScore[DOD_TEAM_ALLIES]	[TEAM_DEATHS] = GetTeamDeaths(DOD_TEAM_ALLIES);
TeamScore[DOD_TEAM_AXIS]	[TEAM_DEATHS] = GetTeamDeaths(DOD_TEAM_AXIS);
for (int client = 1; client !=MAXPLAYERS ; client++)
	{
		if (IsValidClient(client)) 
		{
			PlayerScore[client][PLAYER_POINTS]=	GetDODClientPoints(client);
			PlayerScore[client][PLAYER_KILLS]=	GetClientFrags(client);
			PlayerScore[client][PLAYER_DEATHS]=	GetClientDeaths(client);
		}
		else 
		{
			PlayerScore[client][PLAYER_POINTS]=0;
			PlayerScore[client][PLAYER_KILLS]=0;
			PlayerScore[client][PLAYER_DEATHS]=0;			
		}
	}
}
//**************************************************
void ReSetTeamsScore(){
//**************************************************	
PrintTime();
#if defined DEBUG
DebugLog("ReSetTeamsScore");			
//#elseif defined LOG
//LogMessage("ReSetTeamsScore");	
#endif	
SetTeamScore(DOD_TEAM_ALLIES, 0);
SetTeamScore(DOD_TEAM_AXIS, 0);
SetTeamRoundsWon(DOD_TEAM_ALLIES,0);
SetTeamRoundsWon(DOD_TEAM_AXIS, 0);	
SetTeamFrag(DOD_TEAM_ALLIES,0);
SetTeamFrag(DOD_TEAM_AXIS,0);
SetTeamDeaths(DOD_TEAM_AXIS,0);
SetTeamDeaths(DOD_TEAM_ALLIES,	0);
for (int client = 1; client !=MAXPLAYERS ; client++)
	{
		PlayerScore[client][PLAYER_POINTS]=0;
		PlayerScore[client][PLAYER_KILLS]=0;
		PlayerScore[client][PLAYER_DEATHS]=0;
	if (IsValidClient(client)) 
		{
		SetDODClientFrag(client,0);
		SetDODClientDeaths(client,0);
		SetDODClientPoints(client,0);				
		}	
	}	
}

//**************************************************
public void OnClientConnected(int client){
//**************************************************
PlayerScore[client][PLAYER_POINTS]=0;			
PlayerScore[client][PLAYER_KILLS]=0;			
PlayerScore[client][PLAYER_DEATHS]=0;	
PrintTime();
}
