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
#define MODULE_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MODULE_PLUGIN_NAME "MagicDice - LongJump Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Jump longer"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

#include ../include/magicdice

// Holds the "if longjump enabled for this player" state
bool g_longJump[MAXPLAYERS + 1] = {false, ...};


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
	
	HookEvent("player_jump", PlayerJump);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
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
	g_longJump[client] = true;
	Format(diceText, sizeof(diceText), "%t", "diced");
	return DiceStatus_Success;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Reset all players longjump
	for (int i; i < MAXPLAYERS; i++){
		g_longJump[i] = false;
	}
}

public void PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_longJump[client]) {
		LongJump(client);
	}
}


public void LongJump(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	}
	
	float velocity[3];
	float velocity0;
	float velocity1;
	
	velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	
	velocity[0] = (7.0 * velocity0) * (1.0 / 4.1);
	velocity[1] = (7.0 * velocity1) * (1.0 / 4.1);
	velocity[2] = 0.0;
	
	SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
}