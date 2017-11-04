/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: Example                                   #
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
#define MODULE_PLUGIN_NAME "MagicDice - Freeze"
#define MODULE_PLUGIN_AUTHOR "Lightningblade 'Philip'"
#define MODULE_PLUGIN_DESCRIPTION "Module to cause a freezelike effect on the player"
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
	float duration = MDParseParamFloat(param1);
	
	if(!MDIsStringSet(param1) || duration < 0){
		MDReportInvalidParameter(1, "duration", param1);
		return;
	}
	
	GetEntityRenderColor(int client, int &r, int &g, int &b, int &a);
	
	if (IsClientInGame(client))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		CreateTimer(duration, freezeOff, client, r, g, b, a);
	}
	
	SetEntityRenderColor(client, 0, 170, 240, 180);
	
	Format(diceText, sizeof(diceText), "%t", "frozen");
}


public Action:freezeOff(Handle:timer, any:client, int r, int g, int b, int a)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	SetEntityRenderColor(client, 188, 255, 188, 210);
	
	return Plugin_Handled;
}
