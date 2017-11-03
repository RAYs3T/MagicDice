/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: Speed                                     #
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


public void OnAllPluginsLoaded()
{
	MDRegisterModule("Speed");
}

public void OnPluginEnd()
{
	MDUnRegisterModule();
}

public void Diced(int client, char diceText[255], char[] mode, char[] speedParam, char[] param3, char[] param4, char[] param5)
{
	
	float speed = StringToFloat(speedParam);
	if(strcmp(mode, "set") == 0) 
	{
		SetSpeed(client, speed);
		Format(diceText, sizeof(diceText), "Speed set to %f", speed);
	} else if(strcmp(mode, "add") == 0) {
		SetSpeed(client, GetSpeed(client) + speed);
		Format(diceText, sizeof(diceText), "Added %f of speed", speed);
	} else if(strcmp(mode, "take") == 0) {
		SetSpeed(client, GetSpeed(client) - speed);
		Format(diceText, sizeof(diceText), "Took %f of speed", speed);
	} else {
		LogError("Unknown speed mode: %s", mode);
	}
}

float GetSpeed(int client) 
{
	return GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
}

void SetSpeed(int client, float newSpeed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", newSpeed);
}