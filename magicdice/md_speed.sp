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
#define MODULE_PLUGIN_NAME "MagicDice - Speed"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Increases / Decreases the players speed"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

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

public void Diced(int client, char diceText[255], char[] mode, char[] speedParam, char[] param3, char[] param4, char[] param5)
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
		PrintToChat(client, "Du stinkst asd %f", currentSpeed);
		float newSpeed = (currentSpeed * speedInput);
		SetSpeed(client, newSpeed);
		Format(diceText, sizeof(diceText), "%t", "speed_mult", speedInput * 100, newSpeed * 100);
	}
	else 
	{
		LogError("Unknown speed mode: %s", mode);
	}
}

static float GetSpeed(int client) 
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

static void SetSpeed(int client, float newSpeed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);
}
