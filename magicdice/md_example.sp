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

// This is called when a used diced this module as result
// You can do more random operations here
// Like select a random health value for example.
// diceText is the text reference that is displayer to the client
// You should set a descriptive text
public void Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	MDAddAllowedDices(client, 2); // Allow the player to roll two more times!
	
	Format(diceText, sizeof(diceText), "%t", "diced");
}