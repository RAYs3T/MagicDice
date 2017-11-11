/* 
###################################################################################
# Copyright © 2017 Kevin Urbainczyk <kevin@rays3t.info> - All Rights Reserved     #
# Unauthorized copying of this file, via any medium is strictly prohibited.       #
# Proprietary and confidential.                                                   #
#                                                                                 #
# This file is part of the MagicDice-Plugin.                                      #
# Written by Philip 'Lightningblade'                                              #
# Homepage: https://ptl-clan.de                                                   #
###################################################################################
*/

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin info
#define MODULE_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MODULE_PLUGIN_NAME "MagicDice - Gravity"
#define MODULE_PLUGIN_AUTHOR "Philip aka Lightningblade"
#define MODULE_PLUGIN_DESCRIPTION "Changes the clients gravity"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice
#include <sdktools>



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

public void Diced(int client, char diceText[255], char[] mode, char[] gravityParam, char[] param3, char[] param4, char[] param5)
{
	
	float gravityInput = MDParseParamFloat(gravityParam);
	
	float currentGravity = GetGravity(client);
	//TODO remove the line below and find solution for the line above
	currentGravity = 1.0;
	
	if(strcmp(mode, "set") == 0) 
	{
		SetGravity(client, gravityInput);
		Format(diceText, sizeof(diceText), "%t", "gravity_set", gravityInput * 100);
	} 
	else if(strcmp(mode, "mult") == 0)
	{
		float newGravity = (currentGravity * gravityInput);
		SetGravity(client, newGravity);
		Format(diceText, sizeof(diceText), "%t", "gravity_mult", gravityInput * 100 , newGravity * 100);
	}
	else
	{
		LogError("Unknown gravity mode: %s", mode);
	}
}

static float GetGravity(int client)
{
	return GetEntityGravity(client);
}

static void SetGravity(int client, float newGravity)
{
	SetEntityGravity(client, newGravity);
}