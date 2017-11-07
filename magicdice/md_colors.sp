/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: colorize player							#
# Created by Philip aka Lightningblade              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin info
#define MODULE_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MODULE_PLUGIN_NAME "MagicDice - Colors"
#define MODULE_PLUGIN_AUTHOR "Philip aka Lightningblade"
#define MODULE_PLUGIN_DESCRIPTION "Colorizes the playermodel"
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
	
	int red = 255;
	int green = 255;
	int blue = 255;
	int alpha = 255;
	
	if(MDIsStringSet(param1)){
		red = MDParseParamInt(param1);
	}
	
	if(MDIsStringSet(param2)){
		green = MDParseParamInt(param2);
	}
	
	if(MDIsStringSet(param1)){
		blue = MDParseParamInt(param3);
	}
	
	if(MDIsStringSet(param1)){
		alpha = MDParseParamInt(param4);
	}
	
	SetEntityRenderColor(client, red, green, blue, alpha);
	
	Format(diceText, sizeof(diceText), "%t", "colored", ((red / 256) * 100), ((green / 256) * 100), ((blue / 256) * 100));
}