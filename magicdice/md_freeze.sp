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
#define MODULE_PLUGIN_NAME "MagicDice - Freeze"
#define MODULE_PLUGIN_AUTHOR "Lightningblade 'Philip'"
#define MODULE_PLUGIN_DESCRIPTION "Module to cause a freezelike effect"
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
	
	if (IsClientInGame(client))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		
		DataPack dataPack = new DataPack();
		
		int colors[4];
		
		GetEntityRenderColor(client, colors[0], colors[1], colors[2], colors[3]);
		
		dataPack.WriteCell(colors[0]);
		dataPack.WriteCell(colors[1]);
		dataPack.WriteCell(colors[2]);
		dataPack.WriteCell(colors[3]);
		dataPack.WriteCell(client);
		
		CreateTimer(duration, freezeOff, dataPack);

		SetEntityRenderColor(client, 0, 170, 240, 180);
		Format(diceText, sizeof(diceText), "%t", "frozen", duration);
	}
}


public Action freezeOff(Handle timer, Handle dataPack)
{
	ResetPack(dataPack);
	int colors[4];
	colors[0] = ReadPackCell(dataPack);
	colors[1] = ReadPackCell(dataPack);
	colors[2] = ReadPackCell(dataPack);
	colors[3] = ReadPackCell(dataPack);
	
	int client = ReadPackCell(dataPack);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	SetEntityRenderColor(client, colors[0], colors[1], colors[2], colors[3]);
	
	return Plugin_Handled;
}
