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
#define MODULE_PLUGIN_NAME "MagicDice - WaterBreath"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Prevent the player from drowning"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice
#include <sdkhooks>

static bool g_canPlayerDrown[MAXPLAYERS +1] =  {true, ...};

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
	
	for (int i; i < MAXPLAYERS; i++) {
		AddTakeDamageHook(i);
	}
	
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

public void OnClientPutInServer(int client)
{
	AddTakeDamageHook(client);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		g_canPlayerDrown[i] = true;
	}
}

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	g_canPlayerDrown[client] = false;
	
	Format(diceText, sizeof(diceText), "%t", "diced");
	return DiceStatus_Success;
}

static bool AddTakeDamageHook(int client)
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
	if(g_canPlayerDrown[victim] == true)
	{
		return Plugin_Continue;
	}
	
	if(attacker == 0 && inflictor == 0 && damagetype == DMG_DROWN)
	{
		damage = 0.0;
		return Plugin_Changed;	
	}
	return Plugin_Continue;
}