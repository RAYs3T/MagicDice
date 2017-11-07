/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: Throwingknives                            #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/

// Code style rules
#pragma semicolon 1

// Plugin info
#define MODULE_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MODULE_PLUGIN_NAME "MagicDice - Throwing Knives"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Gives the players some knives to throw on other palyers"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice
#include ../include/cssthrowingknives

#pragma newdecls required

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
	int knives = MDParseParamInt(param1);
	if(knives == 0) {
		MDReportInvalidParameter(1, "Amount of knives", param1);
		return;
	}
	
	AddKnives(client, knives);
	
	Format(diceText, sizeof(diceText), "%t", "you_got_knives", knives);
}

void AddKnives(int client, int kniveCount)
{
	int currentCount = GetClientThrowingKnives(client);
	currentCount += kniveCount;
	SetClientThrowingKnives(client, currentCount);
	 
}