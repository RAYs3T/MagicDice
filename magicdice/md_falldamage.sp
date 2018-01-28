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
#define MODULE_PLUGIN_NAME "MagicDice - FallDamage"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Players won't get hurt by falling down"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

#include ../include/magicdice
#include <sdktools>
#include <sdkhooks>

#define DMG_FALL (1 << 5)

static g_hasNoFallDamage[MAXPLAYERS + 1] =  { false, ... };

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
	
	for (int i = 0; i < MaxClients; i++)
	{
		if(!IsValidClient(i))
		{
			continue; // Skip invalid clients
		}
		HookOnTakeDamage(i);
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Reset all
	for (int i = 0; i < MaxClients; i++)
	{
		g_hasNoFallDamage[i] = false;
	}
}

public void OnAllPluginsLoaded()
{
	MDRegisterModule();
}

public void OnPluginEnd()
{
	MDUnRegisterModule();
}

public void OnClientPutInServer(int client)
{
	HookOnTakeDamage(client);
}

public void HookOnTakeDamage(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	g_hasNoFallDamage[client] = true;
	
	Format(diceText, sizeof(diceText), "%t", "diced");
	return DiceStatus_Success;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(!g_hasNoFallDamage[client])
	{
		return Plugin_Continue;
	}
	
	if (damagetype & DMG_FALL)
	{
		return Plugin_Handled; // Suppress the damage event
	}
	
	return Plugin_Continue;
}