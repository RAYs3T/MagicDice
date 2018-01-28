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
#define MODULE_PLUGIN_NAME "MagicDice - Speed"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Increases / Decreases the players speed"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

#include ../include/magicdice


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
}

public void OnAllPluginsLoaded()
{
	MDRegisterModule();
}

public void OnPluginEnd()
{
	MDUnRegisterModule();
}

public DiceStatus Diced(int client, char diceText[255], char[] mode, char[] speedParam, char[] param3, char[] param4, char[] param5)
{
	
	float speedInput = MDParseParamFloat(speedParam);
	
	float currentSpeed = GetSpeed(client);
	
	if(strcmp(mode, "set") == 0) 
	{
		SetSpeed(client, speedInput);
		Format(diceText, sizeof(diceText), "%t", "speed_set", speedInput * 100);
	} 
	else if(strcmp(mode, "mult") == 0)
	{
		float newSpeed = (currentSpeed * speedInput);
		SetSpeed(client, newSpeed);
		Format(diceText, sizeof(diceText), "%t", "speed_mult", speedInput * 100, newSpeed * 100);
	}
	else 
	{
		MDReportFailure("Unknown speed mode: %s", mode);
		return DiceStatus_Failed;
	}
	return DiceStatus_Success;
}

static float GetSpeed(int client) 
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

static void SetSpeed(int client, float newSpeed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);
}
