/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: Longjump                                  #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin info
#define MODULE_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MODULE_PLUGIN_NAME "MagicDice - LongJump Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Jump longer"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

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

public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	g_longJump[client] = true;
	Format(diceText, sizeof(diceText), "%t", "diced");
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