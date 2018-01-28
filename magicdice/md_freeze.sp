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
#define MODULE_PLUGIN_NAME "MagicDice - Freeze"
#define MODULE_PLUGIN_AUTHOR "Lightningblade 'Philip'"
#define MODULE_PLUGIN_DESCRIPTION "Module to cause a freezelike effect"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

#include ../include/magicdice
#include ../include/autoexecconfig
#include <sdktools>


static ConVar g_soundStartFreeze;
static ConVar g_soundStartPlayOffset;
static ConVar g_soundEndFreeze;
static ConVar g_soundEndPlayOffset;

#define FREEZE_STEPS 16

static int g_freezeColor[] = {0, 170, 240, 180};

char g_freezeOverlay[] = "Effects/com_shield002a.vmt";

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
	
	AutoExecConfig_SetFile("md_freeze", "magicdice");
	g_soundStartFreeze = 		AutoExecConfig_CreateConVar("md_freeze_start_sound", 
	"magicdice/magicdice_freeze.mp3", "Sound to play when the freeze starts");
	g_soundEndFreeze = 			AutoExecConfig_CreateConVar("md_freeze_end_sound", 
	"magicdice/magicdice_unfreeze.mp3", "Sound to play when the freeze stops");
	g_soundStartPlayOffset = 	AutoExecConfig_CreateConVar("md_freeze_start_sound_offset", "2.0", 
	"Offset (in seconds 0.00) the sound should start before the freeze happens");
	g_soundEndPlayOffset = 		AutoExecConfig_CreateConVar("md_freeze_end_sound_offset", "0.1",
	"Time in seconds (0.00) the end sound should start playing, before the unfreeze happens");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}


public void OnAllPluginsLoaded()
{
	MDRegisterModule();
}

public void OnConfigsExecuted()
{
	// Starting sound
	char startSound[PLATFORM_MAX_PATH];
	g_soundStartFreeze.GetString(startSound, sizeof(startSound));
	char startSoundPath[PLATFORM_MAX_PATH];
	Format(startSoundPath, sizeof(startSoundPath), "sound/%s", startSound);
	PrecacheSound(startSound, true);
	AddFileToDownloadsTable(startSoundPath);
	
	// Ending sound
	char endSound[PLATFORM_MAX_PATH];
	g_soundEndFreeze.GetString(endSound, sizeof(endSound));
	char endSoundPath[PLATFORM_MAX_PATH];
	Format(endSoundPath, sizeof(endSoundPath), "sound/%s", endSound);
	PrecacheSound(endSound, true);
	AddFileToDownloadsTable(endSoundPath);
}
public void OnPluginEnd()
{
	MDUnRegisterModule();
}

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	float duration = MDParseParamFloat(param1);
	
	if(!MDIsStringSet(param1) || duration < 0){
		MDReportInvalidParameter(1, "duration", param1);
		return DiceStatus_Failed;
	}
	
	if (IsValidClient(client))
	{
		char startSound[PLATFORM_MAX_PATH];
		g_soundStartFreeze.GetString(startSound, sizeof(startSound));
		
		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		EmitAmbientSound(startSound, position, client, SNDLEVEL_RAIDSIREN);
		
		int colors[4];
	
		// Save the clients old colors
		GetEntityRenderColor(client, colors[0], colors[1], colors[2], colors[3]);
		
		// Pack the old values in a datapack to pass it to the unfreeze timer
		DataPack dataPack = new DataPack();
		dataPack.WriteCell(colors[0]);
		dataPack.WriteCell(colors[1]);
		dataPack.WriteCell(colors[2]);
		dataPack.WriteCell(colors[3]);
		dataPack.WriteCell(client);
		
		char startOffsetBuffer[11];
		g_soundStartPlayOffset.GetString(startOffsetBuffer, sizeof(startOffsetBuffer));
		float startOffset = StringToFloat(startOffsetBuffer);
		
		char endOffsetBuffer[11];
		g_soundEndPlayOffset.GetString(endOffsetBuffer, sizeof(endOffsetBuffer));
		float endOffset = StringToFloat(endOffsetBuffer);
		
		float freezeStepSize = startOffset / FREEZE_STEPS;
		float newSpeed = 1.0;
		float speedStep = 1.0 / FREEZE_STEPS;
		
		int colorStepSize[4];		
		int newColors[4];
		for (int c = 0; c < 4; c++)
		{
			colorStepSize[c] = (colors[c] - g_freezeColor[c]) / FREEZE_STEPS;
			newColors[c] = colors[c];
		}
		
		int backCounter = FREEZE_STEPS;
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
			
			CreateTimer(i * freezeStepSize, Timer_SlowPlayer, slowPack);
			backCounter--;
		}
		
		CreateTimer(startOffset, Timer_FreezePlayer, client);
		CreateTimer(duration, Timer_PlayUnfreezeSound, client);	
		CreateTimer(duration + endOffset, Timer_UnfreezePlayer, dataPack);	
	
		Format(diceText, sizeof(diceText), "%t", "frozen", duration);
	}
	return DiceStatus_Success;
}

public Action Timer_SlowPlayer(Handle tiemr, any data)
{
	ResetPack(data);
	int client = ReadPackCell(data);
	float newSpeed = ReadPackFloat(data);
	int newColors[4];
	for (int c = 0; c < 4; c++)
	{
		newColors[c] = ReadPackCell(data);
	}
	SetEntityRenderColor(client, newColors[0], newColors[1], newColors[2], newColors[3]);	
	#if defined DEBUG
	PrintToChat(client, "Slowing ... %f, colors: %i %i %i %i", newSpeed, newColors[0], newColors[1], newColors[2], newColors[3]);
	#endif
	SetSpeed(client, newSpeed);
	
	
}
public Action Timer_FreezePlayer(Handle tiemr, any client)
{
	if(!IsValidClient(client))
	{
		return Plugin_Stop;
	}
	// Freeze the player
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	// Set "freezy" color
	SetEntityRenderColor(client, 0, 170, 240, 180);
	SetClientOverlay(client);
	return Plugin_Handled;
}

public Action Timer_PlayUnfreezeSound(Handle tiemr, any client)
{
	if(!IsValidClient(client))
	{
		return Plugin_Stop;
	}
	char endSound[PLATFORM_MAX_PATH];
	g_soundEndFreeze.GetString(endSound, sizeof(endSound));
	
	float position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
	EmitAmbientSound(endSound, position, client, SNDLEVEL_RAIDSIREN);
	return Plugin_Handled;
}

public Action Timer_UnfreezePlayer(Handle timer, Handle dataPack)
{
	ResetPack(dataPack);
	int colors[4];
	colors[0] = ReadPackCell(dataPack);
	colors[1] = ReadPackCell(dataPack);
	colors[2] = ReadPackCell(dataPack);
	colors[3] = ReadPackCell(dataPack);
	
	int client = ReadPackCell(dataPack);
	
	if(!IsValidClient(client))
	{
		return Plugin_Stop;
	}
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetSpeed(client, 1.0);
	SetEntityRenderColor(client, colors[0], colors[1], colors[2], colors[3]);
	ResetClientOverlay(client);
	return Plugin_Handled;
}

static void SetSpeed(int client, float newSpeed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);
}

void SetClientOverlay(int client)
{
	ClientCommand(client, "r_screenoverlay %s", g_freezeOverlay);
}

void ResetClientOverlay(int client)
{
	if(IsValidClient(client)) 
	{
		ClientCommand(client, "r_screenoverlay off");
	}
}