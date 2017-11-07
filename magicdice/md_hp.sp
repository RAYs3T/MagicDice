/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: Example                                    #
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

public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	if(!MDIsStringSet(param1)){
		MDReportInvalidParameter(1, "Mode", param1);
		return;
	}
	
	int amount = MDParseParamInt(param2);
	if(amount == 0){
		MDReportInvalidParameter(2, "Amount", param2);
		return;
	}
	
	if(strcmp(param1, "set") == 0) {
		
		UpdateHealth(client, amount, true);
		Format(diceText, sizeof(diceText), "%t", "hp_set", amount);
		
	} else if(strcmp(param1, "add") == 0) {
		
		UpdateHealth(client, amount, false);
		Format(diceText, sizeof(diceText), "%t", "hp_added", amount);
		
	}else if(strcmp(param1, "take") == 0){
		
		UpdateHealth(client, amount * -1, false);
		Format(diceText, sizeof(diceText), "%t", "hp_took", amount);
		
	}
}

void UpdateHealth(int client, int amount, bool onlySet)
{
	int newHealth = 0;
	int currentHealth = GetClientHealth(client);
	if(onlySet){
		// Just set
		newHealth = amount;
	} else {
		// Add / remove
		newHealth = currentHealth + amount;
	}
	
	if(newHealth <= 0) {
		// Since the player could have negative HP, we need to deal with that
		ForcePlayerSuicide(client);
	} else {
		SetEntProp(client, Prop_Data, "m_iMaxHealth", newHealth);
		SetEntityHealth(client, newHealth);
	}	
}