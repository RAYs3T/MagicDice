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
#define MODULE_PLUGIN_NAME "MagicDice - Gravity"
#define MODULE_PLUGIN_AUTHOR "Philip aka Lightningblade"
#define MODULE_PLUGIN_DESCRIPTION "Changes the clients gravity"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

#include ../include/magicdice
#include <sdktools>

float currentPlayerGravity[MAXPLAYERS + 1] = {-1.0, ...};

Handle g_enforceGravityTimer = INVALID_HANDLE;

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
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
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

public DiceStatus Diced(int client, char diceText[255], char[] mode, char[] gravityParam, char[] param3, char[] param4, char[] param5)
{
	float gravityInput = MDParseParamFloat(gravityParam);
	if(strcmp(mode, "set") == 0) 
	{
		SetGravity(client, gravityInput);
		Format(diceText, sizeof(diceText), "%t", "gravity_set", gravityInput * 100);
	} 
	else if(strcmp(mode, "mult") == 0)
	{
		float newGravity = (gravityInput);
		SetGravity(client, newGravity);
		Format(diceText, sizeof(diceText), "%t", "gravity_mult", gravityInput * 100 , newGravity * 100);
	}
	else
	{
		MDReportFailure("Unknown gravity mode: %s", mode);
		return DiceStatus_Failed;
	}
	return DiceStatus_Success;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ResetAllPlayersGravity();
	g_enforceGravityTimer = CreateTimer(0.1, Timer_EnforceGravityOnAllPlayers, _, TIMER_REPEAT);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_enforceGravityTimer != INVALID_HANDLE)
	{
		KillTimer(g_enforceGravityTimer);
		g_enforceGravityTimer = INVALID_HANDLE;
	}	
	ResetAllPlayersGravity();
}

static void SetGravity(int client, float newGravity)
{
	if (newGravity == 1.0)
	{
		currentPlayerGravity[client] = -1.0;
	} else {
		currentPlayerGravity[client] = newGravity;
	}
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		SetGravityInternal(client, newGravity);
	}
}

static void SetGravityInternal(int client, float newGravity)
{
	SetEntityGravity(client, newGravity);
}


static void ResetAllPlayersGravity()
{
	// Reset the gravity of each player.
	// Since we don't want to force gravity on players not affected by any gravity change
	// We set the default "non-value" to -1
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		SetGravity(i, 1.0);
	}
}

public Action Timer_EnforceGravityOnAllPlayers(Handle timer)
{
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		if(currentPlayerGravity[i] != -1.0) // Is the gravity for that player modified?
		{
			if(IsValidClient(i) && IsPlayerAlive(i))
			{
				SetGravityInternal(i, currentPlayerGravity[i]);
			}
		}
	}
}