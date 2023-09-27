//DoD Anti Bot (RCBOT2) TK
//https://forums.alliedmods.net/showthread.php?p=2803521

public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
new attackerID = GetEventInt(event, "attacker");
new clientID = GetEventInt(event, "userid");
if	(attackerID != clientID)	
{			
	new client = GetClientOfUserId(clientID);	
	if	(IsValidClient(client))	
	{		
		new attacker = GetClientOfUserId(attackerID);	
		if	(IsValidClient(attacker))
		{		
			int TeamClient = GetClientTeam(client);
			int TeamAttacker = GetClientTeam(attacker);	
			if(TeamAttacker == TeamClient)
			{									
				if	(IsFakeClient(attacker) && !IsFakeClient(client))	
				{						
					return Plugin_Handled;
				}
				else if (!IsFakeClient(attacker))	
				{
				char strWeapon[MAX_WEAPON_NAME];
				GetEventString(event,"weapon",strWeapon,MAX_WEAPON_NAME);				
				if	(StrEqual(strWeapon,"frag_us",false)) return Plugin_Continue;	
				if	(StrEqual(strWeapon,"frag_ger",false)) return Plugin_Continue;	
				if	(StrEqual(strWeapon,"smoke_us",false)) return Plugin_Continue;	
				if	(StrEqual(strWeapon,"smoke_ger",false)) return Plugin_Continue;	
				if	(StrEqual(strWeapon,"bazooka",false)) return Plugin_Continue;	
				if	(StrEqual(strWeapon,"pschreck",false)) return Plugin_Continue;	
				if	(StrEqual(strWeapon,"riflegren_us",false)) return Plugin_Continue;	
				if	(StrEqual(strWeapon,"riflegren_ger",false)) return Plugin_Continue;	
				//TODO: Add damge from bomb if	(StrEqual(strWeapon,"bomb",false)) return Plugin_Continue;	
				float angs[3]; // 0 - вертикальный угол ; 1- горизонтальный ; 2- поворот взгляда ( угол по оси перпендикулярно плоскости экрана монитора)
				GetClientEyeAngles(attacker, angs);			
				if (GetRandomInt(0,1)==0) angs[1] += 10.0; //GetRandomFloat(-45.0,45.0);
				else angs[1] -= 10.0;
				if (angs[1] < -180.0) {angs[1]+=360.0;}
				else if (angs[1] > 180.0) {angs[1]-=360.0;}
				if (GetRandomInt(0,1)==0) angs[0] += 5.0;//GetRandomFloat(-45.0,45.0);
				else angs[0] -= 5.0;
				if (angs[0] < -180.0) {angs[0]+=360.0;}
				else if (angs[0] > 180.0) {angs[0]-=360.0;}			
				TeleportEntity(attacker, NULL_VECTOR, angs, NULL_VECTOR);
				//TODO:Massage from victim Stop fire
				}
			}
		}
	
	}
}
return Plugin_Continue;	
}
	
	

#endinput	

#include <sdkhooks>
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType)
{	
	if	(client != iAttacker)
	if	(IsValidClient(client))	
	if	(IsValidClient(iAttacker))
	{
		int TeamClient = GetClientTeam(client);
		int TeamAttacker = GetClientTeam(iAttacker);		
		if(/*(TeamClient == 2 || TeamClient == 3) && (TeamAttacker == 2 || TeamAttacker == 3) && */TeamAttacker == TeamClient)
		{			
			#if defined DEBUG
			DebugPrint("OnTakeDamage teamate");
			#endif			
			if	(!IsFakeClient(iAttacker) /*&& !IsFakeClient(client))*/)
			{
				//TODO: IF оружие слот 2 или 3
				#if defined DEBUG
				DebugPrint("Teammate hurt");
				#endif 
				float angs[3]; // 0 - вертикальный угол ; 1- горизонтальный ; 2- поворот взгляда ( угол по оси перпендикулярно плоскости экрана монитора)
				GetClientEyeAngles(iAttacker, angs);			
				if (GetRandomInt(0,1)==0) angs[1] += 10.0; //GetRandomFloat(-45.0,45.0);
				else angs[1] -= 10.0;
				if (angs[1] < -180.0) {angs[1]+=360.0;}
				else if (angs[1] > 180.0) {angs[1]-=360.0;}
				if (GetRandomInt(0,1)==0) angs[0] += 5.0;//GetRandomFloat(-45.0,45.0);
				else angs[0] -= 5.0;
				if (angs[0] < -180.0) {angs[0]+=360.0;}
				else if (angs[0] > 180.0) {angs[0]-=360.0;}			
				TeleportEntity(iAttacker, NULL_VECTOR, angs, NULL_VECTOR);
				//TODO:Massage from victim Stop fire
			}
			else if	(IsFakeClient(iAttacker && !IsFakeClient(client)))	
			{				
				return Plugin_Handled;
			}
		}		
	}	
	return Plugin_Continue;
}

