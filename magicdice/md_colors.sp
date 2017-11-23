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

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	
	float red = 255.0;
	float green = 255.0;
	float blue = 255.0;
	float alpha = 255.0;
	
	if(MDIsStringSet(param1)){
		red = MDParseParamFloat(param1);
	}
	
	if(MDIsStringSet(param2)){
		green = MDParseParamFloat(param2);
	}
	
	if(MDIsStringSet(param3)){
		blue = MDParseParamFloat(param3);
	}
	
	if(MDIsStringSet(param4)){
		alpha = MDParseParamFloat(param4);
	}
	
	RenderMode renderMode;
	if(alpha < 255.0) {
		renderMode = RENDER_TRANSCOLOR;
	}
	else
	{
		renderMode = RENDER_NORMAL;
	}
	SetEntityRenderMode(client, renderMode);
	SetEntityRenderColor(client, RoundToCeil(red), RoundToCeil(green), RoundToCeil(blue), RoundToCeil(alpha));
	
	Format(diceText, sizeof(diceText), "%t", "colored", ((red / 255) * 100), ((green / 255) * 100), ((blue / 255) * 100), ((alpha / 255) * 100));
	return DiceStatus_Success;
}