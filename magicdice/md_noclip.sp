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
#define MODULE_PLUGIN_NAME "MagicDice - No-Clip Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "The player has no clip for some time"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice

// Keep the current timer handles so we can stop/reset the timers on round end
Handle delayTimers[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
Handle clipTimers[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};


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
	for (int i; i < MAXPLAYERS; i++) {
		// Stop running delay timers
		if(delayTimers[i] != INVALID_HANDLE) {
			KillTimer(delayTimers[i], true);
			delayTimers[i] = INVALID_HANDLE;
		}
		
		// Stop running reset timers
		if(clipTimers[i] != INVALID_HANDLE) {
			KillTimer(clipTimers[i], true);
			clipTimers[i] = INVALID_HANDLE;
		}
	}
}

public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	float noClipTime = MDParseParamFloat(param1);
	if(noClipTime == 0.0) {
		MDReportInvalidParameter(1, "NoClip time", param1);
		return;
	}
	
	// If no start delay is set, this is fine. Just use no delay :)
	float startDelay = MDParseParamFloat(param2);
	
	bool directStarted = StartNoClip(client, noClipTime, startDelay);
	
	if(directStarted){
		Format(diceText, sizeof(diceText), "%t", "noclip_direct", noClipTime);
	} else {
		Format(diceText, sizeof(diceText), "%t", "noclip_delayed", startDelay, noClipTime);
	}	
}

bool StartNoClip(int client, float time, float delay) 
{
	bool direct = delay == 0.0;
	if(direct) {
		// We have no delay, we can change the clip directly
		ToggleNoClip(client, true);
	} else {
		// Delay timer to start
		delayTimers[client] = CreateTimer(delay, Timer_StartDelay, client);
	}
	// start the reset timer
	clipTimers[client] = CreateTimer(delay + time, Timer_StopNoclip, client);
	return direct;
}

public Action Timer_StartDelay(Handle timer, int client){
	ToggleNoClip(client, true);
	delayTimers[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action Timer_StopNoclip(Handle timer, int client) {
	ToggleNoClip(client, false);
	clipTimers[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

void ToggleNoClip(int client, bool turnOn)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (turnOn)
	{
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
	} else {
		SetEntityMoveType(client, MOVETYPE_WALK);
	}

}