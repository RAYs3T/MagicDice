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
#define MODULE_PLUGIN_NAME "MagicDice - Example Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "The Example module as reference"
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
	// This is required to load translations and more
	MDOnPluginStart();
}


public void OnAllPluginsLoaded()
{
	// Registers the module at the master plugin
	MDRegisterModule();
}

public void OnPluginEnd()
{
	// THIS IS IMPORTANT!
	// DO NOT REMOVE / FORGET TO IMPLEMENT THIS IN YOUR MODULE
	// This ensures that the plugin is unregisterd correctly, so the main plugin 
	// can continue running smooth and fine
	MDUnRegisterModule();
}

// This is called when a user diced this module as result
// You can do more random operations here
// Like select a random health value for example.
// diceText is the text reference that is displayed to the client
// You should set a descriptive text
// The @return DiceStatus value represents if the dice was successfull or not
public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	MDAddAllowedDices(client, 2); // Allow the player to roll two more times!
	
	Format(diceText, sizeof(diceText), "%t", "diced");
	
	// This tells the core that the dice result has been processed without errors
	// If you notice any kinds of errors you should return DiceStatus_Failed
	// This will ensure that the player can dice again
	return DiceStatus_Success;
}