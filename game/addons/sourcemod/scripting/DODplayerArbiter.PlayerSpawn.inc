float PlayerSpawnAbs[MAX_PLAYERS][3];
float PlayerSpawnTime[MAX_PLAYERS];

public void Event_PlayerSpawn(Event event, const char[] name,  bool dontBroadcast){
	int client=GetClientOfUserId(event.GetInt("userid"));
	GetClientAbsOrigin(client,PlayerSpawnAbs[client]);	
	PlayerSpawnTime[client]=GetGameTime(); 	
}