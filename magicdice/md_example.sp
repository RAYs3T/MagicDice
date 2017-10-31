/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Modul: Example                                    #
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


public void OnAllPluginsLoaded()
{
	// Registers the module at the master plugin
	// The parameter is just for log proposes and has no real use
	// Feel free to use a long version of the module name
	MDRegisterModule("Example");
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
public void Diced(int client, char diceText[255])
{
	Format(diceText, sizeof(diceText), "Rolled an example!");
	PrintToServer("Diced me (example)");
}