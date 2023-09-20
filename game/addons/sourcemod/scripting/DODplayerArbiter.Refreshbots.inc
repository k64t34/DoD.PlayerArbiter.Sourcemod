#if defined REFRESH_BOT
int BotKills[MAX_PLAYERS+1];				// Number usefull action of bot in last minute (frags, flag capture/blocking,bomb plant/defusing)
bool BotToKick[MAX_PLAYERS+1];				// Bot in the kick queue(by random timer)
//**************************************************
public Action Refreshbot(Handle timer, int client){
//**************************************************
#if defined DEBUG
	PrintToServer("-----------");
	PrintToServer("Refresh bot");
	PrintToServer("-----------");
#endif
int tDiff=	TeamHumanPlayerCount[DOD_TEAM_ALLIES] +	TeamBotPlayerCount[DOD_TEAM_ALLIES] - TeamHumanPlayerCount[DOD_TEAM_AXIS] - 	TeamBotPlayerCount[DOD_TEAM_AXIS];
int TeamToClear=0;
if (tDiff>1) TeamToClear=DOD_TEAM_ALLIES;
else if (tDiff<-1)TeamToClear=DOD_TEAM_AXIS;
for (int i = 1;  i<=MaxClients ; i++) 
	if (IsClientConnected(i)) 
	if (!IsClientSourceTV(i))	
	if (IsFakeClient(i)) 	
		{			
		if (TeamToClear!=0) {if (PlayerTeam[i]==TeamToClear){BotKills[i]=0;	TeamToClear=0;}}
		#if defined DEBUG
		char clientName[32];
		GetClientName(i, clientName, 31);
		PrintToServer("%d.%s kills=%d",i,clientName, BotKills[i]);	
		#endif
		if (BotKills[i]==0){BotToKick[i]=true;CreateTimer(GetRandomFloat(0.1,1.0)*59,Kickbot,i,TIMER_FLAG_NO_MAPCHANGE);}else {BotKills[i]=0;
		}
	}
return Plugin_Continue;
}	
//**************************************************
public  Action Kickbot(Handle timer, int client){
//**************************************************	
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
return Plugin_Continue;	
}
//**************************************************
public  void Event_player_killed(Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
BotKills[attacker]++;	
//#if defined DEBUG
//	char clientName[32];
//	GetClientName(attacker, clientName, 31)	;
//	PrintToServer("[%s] #%d %s %d",g_PLUGIN_NAME,attacker,clientName,BotKills[attacker] );
//#endif
int victim = GetClientOfUserId(GetEventInt(event, "victim"));	
if (BotToKick[victim]) 
if (IsClientConnected(victim)) 
if (IsFakeClient(victim)) KickClient(victim);	
}
//**************************************************
public  void Event_capture_blocked (Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
int blocker = GetClientOfUserId(GetEventInt(event, "blocker"));	
BotKills[blocker]++;	
}
//**************************************************
public  void Event_point_captured (Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
char cappers[32] ;	
GetEventString(event, "cappers", cappers, 31, "");
//PrintToServer("-----------------------------------------------------------");
//PrintToServer("[%s]:[Event_point_captured] %s ",g_PLUGIN_NAME,cappers);
for (int i=0;i!=31;i++)
	{
	int id=cappers[i];
	if (id==0) break;
	BotKills[id]++;	
	//#if defined DEBUG
	//char clientName[32];
	//GetClientName(id, clientName, 31);
	//PrintToServer("[%s]:[Event_point_captured] #%d %d %s",g_PLUGIN_NAME,i,id,clientName);
	//#endif
	}

}
//**************************************************
public  void Event_bomb (Event event, const char[] name,  bool dontBroadcast){
//**************************************************	
int userid=GetClientOfUserId(GetEventInt(event, "userid"));	
BotKills[userid]++;	
//#if defined DEBUG
//	char clientName[32];
//	GetClientName(userid, clientName, 31)	;
//	char eventName[32];
//	GetEventName(event, eventName, 31);
//	PrintToServer("[%s]:[%s] #%d %s %d",g_PLUGIN_NAME,eventName,userid,clientName,BotKills[userid] );
//#endif
}
#endif 