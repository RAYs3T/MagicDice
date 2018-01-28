/* 
###################################################################################
# This file is part of MagicDice.                                                 #
# Copyright (C) 2018 Kevin 'RAYs3T' Urbainczyk                                    #
#                                                                                 #
# MagicDice is free software: you can redistribute it and/or modify               #
# it under the terms of the GNU General Public License as published by            #
# the Free Software Foundation, either version 3 of the License, or               #
# (at your option) any later version.                                             #
#                                                                                 #
# MagicDice is distributed in the hope that it will be useful,                    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                  #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                   #
# GNU General Public License for more details.                                    #
#                                                                                 #
# You should have received a copy of the GNU General Public License               #
# along with MagicDice. If not, see <http://www.gnu.org/licenses/>.               #
#                                                                                 #
# MagicDice Website: https://gitlab.com/PushTheLimits/Sourcemod/MagicDice         #
###################################################################################
*/

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin info
#define MODULE_PLUGIN_VERSION "${-version-}"
#define MODULE_PLUGIN_NAME "MagicDice - Nervous"
#define MODULE_PLUGIN_AUTHOR "Philip aka Lightningblade"
#define MODULE_PLUGIN_DESCRIPTION "Changes the players aim"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice
#include <sdktools>

Handle nervous_timer[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = MODULE_PLUGIN_NAME,
	author = MODULE_PLUGIN_AUTHOR,
	description = MODULE_PLUGIN_DESCRIPTION,
	version = MODULE_PLUGIN_VERSION,
	url = MODULE_PLUGIN_WEBSITE
};

public void OnPluginStart()
{
	MDOnPluginStart();
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}


public void OnAllPluginsLoaded()
{
	MDRegisterModule();
}

public void OnPluginEnd()
{
	MDUnRegisterModule();
}

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	float intensity = 2.0;
	float ticktime = 1.0;
	
	if(MDIsStringSet(param1)){
		intensity = MDParseParamFloat(param1);
	}
	
	if(MDIsStringSet(param2)){
		ticktime = MDParseParamFloat(param2);
	}
	
	DataPack pack = new DataPack();
	
	nervous_timer[client] = CreateTimer(ticktime, nervous_loop, pack, TIMER_REPEAT);
	
	pack.WriteCell(client);
	pack.WriteFloat(intensity);
	
	Format(diceText, sizeof(diceText), "%t", "nervous", intensity,ticktime );
	return DiceStatus_Success;
}

public Action nervous_loop(Handle timer, Handle pack)
{
	ResetPack(pack, false);
	int client = ReadPackCell(pack);
	
	if (!IsValidClient(client) || !IsPlayerAlive(client) || nervous_timer[client] == INVALID_HANDLE)
	{
		return Plugin_Stop;
	}
	
	float intensity = ReadPackFloat(pack);
	
	float vAngles[3];
	GetClientEyeAngles(client, vAngles);
	int rnd;
	rnd = GetURandomInt();
	if (rnd % 2 == 0) {
		vAngles[0] -= GetURandomFloat() * intensity;
	} else {
		vAngles[0] += GetURandomFloat() * intensity * 2;
	}
	rnd = GetURandomInt();
	if (rnd % 2 == 0) {
		vAngles[1] += GetURandomFloat();
	} else {
		vAngles[1] -= GetURandomFloat();
	}
	TeleportEntity(client, NULL_VECTOR, vAngles, NULL_VECTOR);
	
	return Plugin_Continue;
}


public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i < MaxClients + 1; i++)
	{
		nervous_timer[i] = INVALID_HANDLE;
	}
}