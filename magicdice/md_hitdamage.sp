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
#define MODULE_PLUGIN_NAME "MagicDice - HitDamage Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Controls the amount of damage a player does against another"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

#include ../include/magicdice
#include <sdkhooks>

float g_playerDamageMultiplier[MAXPLAYERS + 1] = {0.0, ...};

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
		
	// When the  plugin is getting loaded, hook allready connected players. 
	// Otherwise the plugin would only work at the text map for some players
	for (int i; i < MAXPLAYERS; i++) {
		if(IsValidClient(i, false)) {
			AddTakeDamageHook(i);
		}
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

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{	
	float damageMultiplier = MDParseParamFloat(param1);
	if(damageMultiplier == 0.0) {
		MDReportInvalidParameter(1, "Damage multiplier", param1);
		return DiceStatus_Failed;
	}
	
	g_playerDamageMultiplier[client] = damageMultiplier;
	
	if(damageMultiplier >= 1.0) {
		Format(diceText, sizeof(diceText), "%t", "more_damage", damageMultiplier * 100);
	} else {
		Format(diceText, sizeof(diceText), "%t", "less_damage", damageMultiplier * 100);
	}
	return DiceStatus_Success;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Reset player damage multiplier
	for (int i; i < MAXPLAYERS; i++) {
		g_playerDamageMultiplier[i] = 0.0;
	}
}

public void OnClientPutInServer(int client)
{
	AddTakeDamageHook(client);
}

void AddTakeDamageHook(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(attacker > MAXPLAYERS) {
		// Damage not caused by another player
		return Plugin_Continue;
	}
	// Do we have to modify the damage of the git player?
	if(g_playerDamageMultiplier[attacker] != 0.0) {
		damage *= g_playerDamageMultiplier[attacker];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}