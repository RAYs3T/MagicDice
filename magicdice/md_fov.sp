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
#define MODULE_PLUGIN_VERSION "0.1"
#define MODULE_PLUGIN_NAME "MagicDice - Fov Module"
#define MODULE_PLUGIN_AUTHOR "Philip 'Lightningblade'"
#define MODULE_PLUGIN_DESCRIPTION "Changes the field of view of the client"
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

public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	int amount = MDParseParamInt(param1);
	
	if(amount <= 0|| amount == 90){
		MDReportInvalidParameter(1, "value", param1);
		return;
	}
	
	SetEntProp(client, Prop_Send, "m_iFOV", lowFov);
	
	Format(diceText, sizeof(diceText), "%t", "fov_set");
}