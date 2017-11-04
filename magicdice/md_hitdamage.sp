/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: HitDamage                                 #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin info
#define MODULE_PLUGIN_VERSION "0.1"
#define MODULE_PLUGIN_NAME "MagicDice - HitDamage Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Controls the amount of damage a player does against another"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

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
	for (int i; i <= MAXPLAYERS; i++) {
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

public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{	
	float damageMultiplier = MDParseParamFloat(param1);
	if(damageMultiplier == 0.0) {
		MDReportInvalidParameter(1, "Damage multiplier", param1);
	}
	
	g_playerDamageMultiplier[client] = damageMultiplier;
	
	if(damageMultiplier >= 1.0) {
		Format(diceText, sizeof(diceText), "%t", "more_damage", damageMultiplier);
	} else {
		Format(diceText, sizeof(diceText), "%t", "less_damage", damageMultiplier);
	}
	
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Reset player damage multiplier
	for (int i; i <= MAXPLAYERS; i++) {
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
	// Do we have to modify the damage of the git player?
	if(g_playerDamageMultiplier[attacker] != 0.0) {
		damage *= g_playerDamageMultiplier[attacker];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}