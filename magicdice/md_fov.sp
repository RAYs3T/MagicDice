/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: Field of view								#
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
#define MODULE_PLUGIN_NAME "MagicDice - Fov Module"
#define MODULE_PLUGIN_AUTHOR "Philip 'Lightningblade'"
#define MODULE_PLUGIN_DESCRIPTION "Changes the field of view of the client"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice


int g_fovClients[MAXPLAYERS + 1] =  { false, 0 };
Handle g_fovTimer;

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

public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	int amount = MDParseParamInt(param1);
	
	if(amount <= 0|| amount == 90){
		MDReportInvalidParameter(1, "value", param1);
		return;
	}
	
	g_fovClients[client] = amount;
	
	Format(diceText, sizeof(diceText), "%t", "fov_set", amount);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Reset player damage multiplier
	for (int i; i < MAXPLAYERS; i++) {
		g_fovClients[i] = 0;
	}
	// Start a timer that is setting the fov every .5 seconds
	CreateTimer(0.5, Timer_UpdateFOV, _, TIMER_REPEAT);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	StopTimer();
}

public Action Timer_UpdateFOV(Handle timer)
{
	for (int i; i < MAXPLAYERS; i++) {
			if(g_fovClients[i] != 0)
			{
				if(!IsValidClient(i) || !IsPlayerAlive(i))
				{
					continue; // Skip this dead player
				}
				SetEntProp(i, Prop_Send, "m_iFOV", g_fovClients[i]);
			}
	}
	return Plugin_Continue;
}

void StopTimer()
{
	if(g_fovTimer != INVALID_HANDLE) {
		KillTimer(g_fovTimer);
	}
}