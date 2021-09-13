float PlayerSpawnPosition[MAX_PLAYERS][3];
public void Event_PlayerSpawn(Event event, const char[] name,  bool dontBroadcast){
	int client=GetClientOfUserId(event.GetInt("userid"));
	GetClientAbsOrigin(client,PlayerSpawnPosition[client]);		
}