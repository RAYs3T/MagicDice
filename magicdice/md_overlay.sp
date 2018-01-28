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
#define MODULE_PLUGIN_NAME "MagicDice - ScreenOverlay Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Sets a special overlay like the player took drugs or alc"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice

int g_playerOverlays[MAXPLAYERS + 1] = {-1, ...}; // Store the current overlay of a player

char g_overlays[64][2][256]; // [Overlays][name|file][string]
int g_loadedOverlays = 0;


Handle g_overlaySetTimer;


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
	
	InitializeOverlays();
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
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
	if(g_loadedOverlays == 0)
	{
		MDReportFailure("No overlays configured");
		return DiceStatus_Failed;
	}
	
	int selectedOverlay = GetRandomInt(0, g_loadedOverlays -1);
	g_playerOverlays[client] = selectedOverlay;
	
	// Set the overlay after the player diced
	SetClientOverlay(client, g_overlays[selectedOverlay][1]);
	
	Format(diceText, sizeof(diceText), "%t", "using_overlay", g_overlays[selectedOverlay][0]);
	return DiceStatus_Success;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// We use the timer to ensure the client cannot remove the overlay
	// If you type "record <demo_name>" for example, the overlay will be reset
	// This way the overlay is set every 1.8 seconds
	g_overlaySetTimer = CreateTimer(1.8, Timer_SetOverlay, _, TIMER_REPEAT);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_overlaySetTimer != INVALID_HANDLE)
	{
		KillTimer(g_overlaySetTimer);
	}
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		ResetClientOverlay(i);		
	}	
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	// Disable the overlay for the diead player
	int dieadPlayer = GetClientOfUserId(GetEventInt(event, "userId"));
	if(g_playerOverlays[dieadPlayer] != -1)
	{
		ResetClientOverlay(dieadPlayer);
	}
}

public Action Timer_SetOverlay(Handle timer)
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if(g_playerOverlays[i] != -1)
		{
			if(!IsValidClient(i) || !IsPlayerAlive(i))
			{
				continue; // Skip invalid / dead players
			}
			SetClientOverlay(i, g_overlays[g_playerOverlays[i]][1]);
		}
	}
	return Plugin_Continue;
}

/**
 * Loads all overlays from the config
 */
void InitializeOverlays()
{
	g_loadedOverlays = 0;
	KeyValues kv = new KeyValues("Overlays");
	kv.ImportFromFile("cfg/magicdice/md_overlay.cfg");
	if(!kv.GotoFirstSubKey())
	{
		MDReportFailure("No overlays configured! Please check: cfg/magicdice/md_overlay.cfg");
		return;
	}
	do {
		char name[255];
		char path[255];
		kv.GetString("name", name, sizeof(name));
		kv.GetString("file", path, sizeof(path));

		// Load the model
		PrecacheModel(path);
		
		g_overlays[g_loadedOverlays][0] = name;
		g_overlays[g_loadedOverlays][1] = path;
		g_loadedOverlays++;
	} while (kv.GotoNextKey());
	delete kv; 
}

void SetClientOverlay(int client, const char[] file)
{
	ClientCommand(client, "r_screenoverlay %s", file);
}

void ResetClientOverlay(int client)
{
	g_playerOverlays[client] = -1;
	if(IsValidClient(client)) 
	{
		ClientCommand(client, "r_screenoverlay off");
	}
}