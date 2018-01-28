/* 
###################################################################################
# This file is part of MagicDice.                                                 #
# Copyright (C) 2018 Kevin 'RAYs3T' Urbainczyk                                    #
#                                                                                 #
# MagicDice is free software: you can redistribute it and/or modify               #
# it under the terms of the GNU General Public License as published by            #
# the Free Software Foundation, either version 3 of the License, or               #
# (at your option) any later version.                                             #
#                                                                                 #
# MagicDice is distributed in the hope that it will be useful,                    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                  #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                   #
# GNU General Public License for more details.                                    #
#                                                                                 #
# You should have received a copy of the GNU General Public License               #
# along with MagicDice. If not, see <http://www.gnu.org/licenses/>.               #
#                                                                                 #
# MagicDice Website: https://gitlab.com/PushTheLimits/Sourcemod/MagicDice         #
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
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

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
		Format(diceText, sizeof(diceText), "%t", "hp_set", amount);
	}
	else if(strcmp(param1, "add") == 0)
	{
		amount = MDParseParamInt(param2);
		AddHealth(client, amount);
		Format(diceText, sizeof(diceText), "%t", "hp_add", amount);
	}
	else if(strcmp(param1, "mult") == 0)
	{
		multiplier = MDParseParamFloat(param2);
		MultHealth(client, multiplier);
		Format(diceText, sizeof(diceText), "%t", "hp_mult", multiplier * 100);
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
