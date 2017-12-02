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
#include ../include/autoexecconfig
#include <sdkhooks>
#include <sdktools>

// Fire
static float g_effectStrengthFire[MAXPLAYERS + 1] 				= {0.0, ...};

// Freeze
static float g_effectStrengthFreeze[MAXPLAYERS + 1]				= {0.0, ...};

// Timers for removing the slowdown effect, require for multiple hits
static Handle g_playerSlowRemoveTimers[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
static int g_playerSlowOriginalColors[MAXPLAYERS + 1][4];
static float g_playerOriginalSpeed[MAXPLAYERS + 1];
static int g_freezeColor[] = {0, 170, 240, 180};

static ConVar g_soundFire;
static ConVar g_soundFreeze;

#define FREEZE_STEPS 5

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
	
	AutoExecConfig_SetFile("md_aftermath", "magicdice");
	g_soundFire = 		AutoExecConfig_CreateConVar("md_aftermath_fire_sound", 
	"magicdice/magicdice_aftermath_fire.mp3", "Sound to play if a player dices fire");
	g_soundFreeze = 		AutoExecConfig_CreateConVar("md_aftermath_freeze_sound", 
	"magicdice/magicdice_aftermath_freeze.mp3", "Sound to play if a player dices freeze");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnConfigsExecuted()
{
	// Precache sounds
	char fireSound[PLATFORM_MAX_PATH];
	g_soundFire.GetString(fireSound, sizeof(fireSound));
	char fireSoundPath[PLATFORM_MAX_PATH];
	Format(fireSoundPath, sizeof(fireSoundPath), "sound/%s", fireSound);
	PrecacheSound(fireSound, true);
	AddFileToDownloadsTable(fireSoundPath);
	
	char freezeSound[PLATFORM_MAX_PATH];
	g_soundFreeze.GetString(freezeSound, sizeof(freezeSound));
	char freezeSoundPath[PLATFORM_MAX_PATH];
	Format(freezeSoundPath, sizeof(freezeSoundPath), "sound/%s", freezeSound);
	PrecacheSound(freezeSound, true);
	AddFileToDownloadsTable(freezeSoundPath);
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

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		// Reset all properties
		g_effectStrengthFire[i] = 0.0;
		g_effectStrengthFreeze[i] = 0.0;
	}
}

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	if(!MDIsStringSet(param1))
	{
		MDReportInvalidParameter(1, "Mode", param1);
		return DiceStatus_Failed;
	}
	
	float strength = MDParseParamFloat(param2);
	if(strength == 0.0)
	{
		MDReportInvalidParameter(2, "Strength (time) of the effect", param2);
		return DiceStatus_Failed;
	}
	
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		
	if(strcmp(param1, "fire") == 0)
	{
		g_effectStrengthFire[client] = strength;
		
		char fireSound[PLATFORM_MAX_PATH];
		g_soundFire.GetString(fireSound, sizeof(fireSound));
		
		EmitAmbientSound(fireSound, position, client, SNDLEVEL_RAIDSIREN);
		
		Format(diceText, sizeof(diceText), "%t", "fire", strength);		
	} 
	else if(strcmp(param1, "freeze") == 0)
	{
		g_effectStrengthFreeze[client] = strength;
		
		char freezeSound[PLATFORM_MAX_PATH];
		g_soundFreeze.GetString(freezeSound, sizeof(freezeSound));
		
		
		EmitAmbientSound(freezeSound, position, client, SNDLEVEL_RAIDSIREN);
		Format(diceText, sizeof(diceText), "%t", "freezed", strength);
	} 
	else 
{
		MDReportInvalidParameter(1, "Mode (fire or freeze)", param1);
		return DiceStatus_Failed;
	}
	return DiceStatus_Success;
}


static void SlowPlayer(int client, float time)
{
	// Check if there is a remove slowness timer is running
	// If this is the case, just stop that, and spawn a new one
	// with the new slow remove value
	// This will keep the player "slow" while more and more bullets hit'em
	if(g_playerSlowRemoveTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_playerSlowRemoveTimers[client]);
		g_playerSlowRemoveTimers[client] = CreateTimer(time + 0.2, Timer_ResetSlowPlayer, client);
		// STOP HERE, END TIMER WAS RESETTET AND CLIENT IS STILL SLOW (OR SLOWING DOWN!)
		return;
	}
	
	int colors[4];
	
	// Save the clients old colors
	GetEntityRenderColor(client, colors[0], colors[1], colors[2], colors[3]);
	
		
	float freezeStepSize = time / FREEZE_STEPS;
	float newSpeed = GetSpeed(client);
	float speedStep = newSpeed / FREEZE_STEPS;
	
	int colorStepSize[4];		
	int newColors[4];
	for (int c = 0; c < 4; c++)
	{
		colorStepSize[c] = (colors[c] - g_freezeColor[c]) / FREEZE_STEPS;
		newColors[c] = colors[c];
		g_playerSlowOriginalColors[client][c] = colors[c];
	}
	g_playerOriginalSpeed[client] = GetSpeed(client);
	
	for (int i = 1; i <= FREEZE_STEPS; i++)
	{
		
		newSpeed -= speedStep;
		DataPack slowPack = new DataPack();
		slowPack.WriteCell(client);
		slowPack.WriteFloat(newSpeed);
		for (int c = 0; c < 4; c++)
		{
			newColors[c] -= colorStepSize[c];
			slowPack.WriteCell(newColors[c]);
		}
		// Slowly slow down the player
		CreateTimer(i * freezeStepSize, Timer_SlowPlayer, slowPack);
	}
	// Create a new reset timer
	g_playerSlowRemoveTimers[client] = CreateTimer(time + 0.2, Timer_ResetSlowPlayer, client);
}


public Action Timer_SlowPlayer(Handle timer, any data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	if(!IsValidClient(client, false) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	float newSpeed = ReadPackFloat(data);
	int newColors[4];
	for (int c = 0; c < 4; c++)
	{
		newColors[c] = ReadPackCell(data);
	}
	SetEntityRenderColor(client, newColors[0], newColors[1], newColors[2], newColors[3]);	
	#if defined DEBUG
	PrintToServer("Slowing ... %f, colors: %i %i %i %i", newSpeed, newColors[0], newColors[1], newColors[2], newColors[3]);
	#endif
	SetSpeed(client, newSpeed);
	return Plugin_Handled;	
}

public Action Timer_ResetSlowPlayer(Handle timer, any client)
{
	g_playerSlowRemoveTimers[client] = INVALID_HANDLE;
	if(!IsValidClient(client, false) && !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	// Reset speed
	SetSpeed(client, g_playerOriginalSpeed[client]);
	// Reset color
	SetEntityRenderColor(client, 
		g_playerSlowOriginalColors[client][0], 
		g_playerSlowOriginalColors[client][1], 
		g_playerSlowOriginalColors[client][2], 
		g_playerSlowOriginalColors[client][3]);
	return Plugin_Handled;
}

static void SetSpeed(int client, float newSpeed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);
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
	
	if(g_effectStrengthFire[attacker] != 0.0 || g_effectStrengthFreeze[attacker] != 0.0)
	{
		if(!IsValidClient(victim) || !IsValidClient(attacker))
		{
			// Invalid clients
			return Plugin_Continue;
		}
		if(GetClientTeam(victim) == GetClientTeam(attacker))
		{
			// Same team!
			return Plugin_Continue;
		}
	}
	// Check if the attacker has fire effect
	if(g_effectStrengthFire[attacker] != 0.0)
	{
		IgniteEntity(victim, g_effectStrengthFire[attacker]);	
	}
	if(g_effectStrengthFreeze[attacker] != 0.0)
	{
		SlowPlayer(victim, g_effectStrengthFreeze[attacker]);
	}

	
	return Plugin_Continue;
}

static float GetSpeed(int client) 
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}