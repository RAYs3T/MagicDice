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
#define MODULE_PLUGIN_NAME "MagicDice - Aftermath"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Has some effects on players that was hit"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice
#include <sdkhooks>
#include <sdktools>

// Fire
static float g_effectStrengthFire[MAXPLAYERS + 1] 				= {0.0, ...};


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
	
	// Hook takeDame for all connected players
	for (int i; i < MAXPLAYERS; i++) {
		AddTakeDamageHook(i);
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

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		// Reset all properties
		g_effectStrengthFire[i] = 0.0;
	}
}

public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	
	float strength = MDParseParamFloat(param2);
	if(strength == 0.0)
	{
		MDReportInvalidParameter(2, "Strength (time) of the effect", param2);
		return;
	}
	
	g_effectStrengthFire[client] = strength;
	Format(diceText, sizeof(diceText), "AFTERMAAAAAAAATH!");
}

public void OnClientPutInServer(int client)
{
	AddTakeDamageHook(client);
}

bool AddTakeDamageHook(int client)
{
	if(!IsValidClient(client, false))
	{
		return false;
	}
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	return true;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(attacker > MAXPLAYERS) {
		// Damage not caused by another player
		return Plugin_Continue;
	}

	// Check if the attacker has fire effect
	if(g_effectStrengthFire[attacker] != 0.0)
	{
		IgniteEntity(victim, g_effectStrengthFire[attacker]);
		
	}
	
	return Plugin_Continue;
}