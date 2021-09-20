int TeamScore[DOD_TEAMS_COUNT][4];
#define TEAM_SCORE		0
#define TEAM_ROUNDWINS	1
#define TEAM_KILLS		2
#define TEAM_DEATHS		3

int PlayerScore[MAXPLAYERS][3];
#define PLAYER_POINTS		0
#define PLAYER_KILLS		1
#define PLAYER_DEATHS		2

stock void ReSetTeamsScore(){
	#if defined DEBUG
	PrintToServer("ReSetTeamsScore");
	#endif
	TeamScore[DOD_TEAM_ALLIES][TEAM_SCORE]=0;
	TeamScore[DOD_TEAM_ALLIES][TEAM_ROUNDWINS]=0;
	TeamScore[DOD_TEAM_ALLIES][TEAM_KILLS]=0;
	TeamScore[DOD_TEAM_ALLIES][TEAM_DEATHS]=0;
	TeamScore[DOD_TEAM_AXIS][TEAM_SCORE]=0;
	TeamScore[DOD_TEAM_AXIS][TEAM_ROUNDWINS]=0;
	TeamScore[DOD_TEAM_AXIS][TEAM_KILLS]=0;
	TeamScore[DOD_TEAM_AXIS][TEAM_DEATHS]=0;
	SetTeamScore(DOD_TEAM_ALLIES, 0);
	SetTeamScore(DOD_TEAM_AXIS, 0);				
	SetTeamRoundsWon(DOD_TEAM_ALLIES, 0);
	SetTeamRoundsWon(DOD_TEAM_AXIS, 0);
	for (int client = 1; client <=MAXPLAYERS ; client++)
	{
		PlayerScore[client][PLAYER_POINTS]=0;
		PlayerScore[client][PLAYER_KILLS]=0;
		PlayerScore[client][PLAYER_DEATHS]=0;
	}
}
stock void StoreTeamsScore(){
	TeamScore[DOD_TEAM_ALLIES][TEAM_SCORE]=GetTeamScore(DOD_TEAM_ALLIES);
	TeamScore[DOD_TEAM_ALLIES][TEAM_ROUNDWINS]=GetTeamRoundsWon(DOD_TEAM_ALLIES);
	//TeamScore[DOD_TEAM_ALLIES][TEAM_KILLS]=0;
	//TeamScore[DOD_TEAM_ALLIES][TEAM_DEATHS]=0;
	TeamScore[DOD_TEAM_AXIS][TEAM_SCORE]=GetTeamScore(DOD_TEAM_AXIS);
	TeamScore[DOD_TEAM_AXIS][TEAM_ROUNDWINS]=GetTeamRoundsWon(DOD_TEAM_AXIS);
	//TeamScore[DOD_TEAM_AXIS][TEAM_KILLS]=0;
	//TeamScore[DOD_TEAM_AXIS][TEAM_DEATHS]=0;
	for (int client = 1; client <=MAXPLAYERS ; client++)
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
stock void ReStoreTeamsScore(){
	SetTeamScore(DOD_TEAM_ALLIES,		TeamScore[DOD_TEAM_ALLIES]	[TEAM_SCORE]);
	SetTeamScore(DOD_TEAM_AXIS,			TeamScore[DOD_TEAM_AXIS]	[TEAM_ROUNDWINS]);	
	SetTeamRoundsWon(DOD_TEAM_ALLIES,	TeamScore[DOD_TEAM_ALLIES]	[TEAM_SCORE]);
	SetTeamRoundsWon(DOD_TEAM_AXIS,		TeamScore[DOD_TEAM_AXIS]	[TEAM_ROUNDWINS]);
	//SetTeamKills(DOD_TEAM_ALLIES,		TeamScore[DOD_TEAM_ALLIES]	[TEAM_KILLS]);
	//SetTeamKills(DOD_TEAM_AXIS,			TeamScore[DOD_TEAM_AXIS]	[TEAM_KILLS]);
	//SetTeamDeaths(DOD_TEAM_ALLIES,		TeamScore[DOD_TEAM_ALLIES]	[TEAM_ROUNDWINS]);
	//SetTeamDeaths(DOD_TEAM_AXIS,		TeamScore[DOD_TEAM_AXIS]	[TEAM_ROUNDWINS]);	
	for (int client = 1; client <=MaxClients; client++)
	{
		if (IsValidClient(client)) 
		{
			SetDODClientFrag(client,PlayerScore[client][PLAYER_KILLS]);
			SetDODClientDeaths(client,PlayerScore[client][PLAYER_DEATHS]);
			SetDODClientPoints(client,PlayerScore[client][PLAYER_POINTS]);			
		}		
	}
}	
public void OnClientConnected(int client){	PlayerScore[client][PLAYER_POINTS]=0;			PlayerScore[client][PLAYER_KILLS]=0;			PlayerScore[client][PLAYER_DEATHS]=0;	}
	
