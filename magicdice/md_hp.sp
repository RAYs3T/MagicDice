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
#define MODULE_PLUGIN_NAME "MagicDice - HP module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Module to manipulate the clients HP"
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

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	if(!MDIsStringSet(param1)){
		MDReportInvalidParameter(1, "Mode", param1);
		return DiceStatus_Failed;
	}
	
	float multiplier = 1.0;
	int amount = 0;
	
	if(strcmp(param1, "set") == 0)
	{
		amount = MDParseParamInt(param2);
		SetHealth(client, amount);
	}
	else if(strcmp(param1, "add") == 0)
	{
		amount = MDParseParamInt(param2);
		AddHealth(client, amount);
	}
	else if(strcmp(param1, "mult") == 0)
	{
		multiplier = MDParseParamFloat(param2);
		MultHealth(client, multiplier);
	}
	else
	{
		MDReportInvalidParameter(1, "Mode", param1);
		return DiceStatus_Failed;
	}
	return DiceStatus_Success;
}

void SetHealth(int client, int amount)
{
	UpdateHealth(client, amount, amount);
}

void AddHealth(int client, int amount)
{
	int newHealth = 0;
	int newMaxHealth = 0;
	int currentHealth = GetClientHealth(client);
	int currentMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth", currentMaxHealth);
	
	newHealth = currentHealth + amount;
	newMaxHealth = currentMaxHealth + amount;
	
	UpdateHealth(client, newHealth, newMaxHealth);
}

void MultHealth(int client, float multiplier)
{
	int newHealth = 0;
	int newMaxHealth = 0;
	int currentHealth = GetClientHealth(client);
	int currentMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth", currentMaxHealth);
	
	newHealth = RoundToNearest(currentHealth * multiplier);
	newMaxHealth = RoundToNearest(currentMaxHealth * multiplier);
	
	UpdateHealth(client, newHealth, newMaxHealth);
}

void UpdateHealth(int client, int newHealth, int newMaxHealth)
{
	if(newHealth <= 0 || newMaxHealth <= 0) 
	{
		// Since the player could have negative HP, we need to deal with that
		ForcePlayerSuicide(client);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_iMaxHealth", newMaxHealth);
		SetEntityHealth(client, newHealth);
	}
}