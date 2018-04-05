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

// Plugin info
#define MODULE_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MODULE_PLUGIN_NAME "MagicDice - Throwing Knives"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Gives the players some knives to throw on other palyers"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

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
	// Check if the required plugin is loaded
	if(!LibraryExists("cssthrowingknives")) 
	{
		LogError("Unable to load md_throwingknives! The required libary plugin cssthrowingknives is not loaded.\
			Please download and install the plugin from: https://forums.alliedmods.net/showthread.php?p=1160952");
		SetFailState("Required plugin cssthrowingknives is not loaded!");
		return; // Do not register the module at the core since our dependency plugin is not loaded.
	}
	MDRegisterModule();
}

public void OnPluginEnd()
{
	MDUnRegisterModule();
}


public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	int knives = MDParseParamInt(param1);
	if(knives == 0) {
		MDReportInvalidParameter(1, "Amount of knives", param1);
		return DiceStatus_Failed;
	}
	
	AddKnives(client, knives);
	
	Format(diceText, sizeof(diceText), "%t", "you_got_knives", knives);
	return DiceStatus_Success;
}

void AddKnives(int client, int kniveCount)
{
	int currentCount = GetClientThrowingKnives(client);
	currentCount += kniveCount;
	SetClientThrowingKnives(client, currentCount);
	 
}