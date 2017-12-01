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
	
	float multAmount = 1.0;
	int amount = 0;
	
	if(strcmp(param1, "mult") == 0)
	{
		multAmount = MDParseParamFloat(param2);
	}
	else
	{
		amount = MDParseParamInt(param2);
	}
	
	
	if(amount == 0){
		MDReportInvalidParameter(2, "Amount", param2);
		return DiceStatus_Failed;
	}
	
	if(strcmp(param1, "set") == 0)
	{
		UpdateHealth(client, amount, true, false);
		Format(diceText, sizeof(diceText), "%t", "hp_set", amount);
	}
	else if(strcmp(param1, "add") == 0) 
	{
		UpdateHealth(client, amount, false, false);
		Format(diceText, sizeof(diceText), "%t", "hp_added", amount);
	}
	else if(strcmp(param1, "take") == 0)
	{
		UpdateHealth(client, amount * -1, false, false);
		Format(diceText, sizeof(diceText), "%t", "hp_took", amount);
	}
	else if(strcmp(param1, "mult") == 0)
	{
		UpdateHealth(client, RoundToNearest(GetClientHealth(client) * multAmount), false, true);
		Format(diceText, sizeof(diceText), "%t", "hp_mult", multAmount * 100);
	}
	else
	{
		MDReportInvalidParameter(1, "Mode", param1);
		return DiceStatus_Failed;
	}
	return DiceStatus_Success;
}

void UpdateHealth(int client, int amount, bool onlySet, bool multiplied)
{
	int newHealth = 0;
	int newMaxHealth = 0;
	int currentHealth = GetClientHealth(client);
	int currentMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth", currentMaxHealth);
	
	if(onlySet){
		// Just set
		newHealth = amount;
		newMaxHealth = amount;
	}else if(multiplied){
		newHealth = amount * currentHealth;
		newMaxHealth = amount * currentMaxHealth;
	}else{
		// Add / remove
		newHealth = amount;
		newMaxHealth = amount;
	}
	
	if(newHealth <= 0 || newMaxHealth <= 0) {
		// Since the player could have negative HP, we need to deal with that
		ForcePlayerSuicide(client);
	} else {
		SetEntProp(client, Prop_Data, "m_iMaxHealth", newMaxHealth);
		SetEntityHealth(client, newHealth);
	}	
}