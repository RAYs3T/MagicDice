/* 
###################################################################################
# Copyright © 2017 Kevin Urbainczyk <kevin@rays3t.info> - All Rights Reserved     #
# Unauthorized copying of this file, via any medium is strictly prohibited.       #
# Proprietary and confidential.                                                   #
#                                                                                 #
# This file is part of the MagicDice-Plugin.                                      #
# Written by Kevin 'RAYs3T' Urbainczyk <kevin@rays3t.info>                        #
# Homepage: https://ptl-clan.de                                                   #
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
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

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