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
#define MODULE_PLUGIN_NAME "MagicDice - Colors"
#define MODULE_PLUGIN_AUTHOR "Philip aka Lightningblade"
#define MODULE_PLUGIN_DESCRIPTION "Colorizes the playermodel"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

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
	
	if((red != 255 || green != 255 || blue != 255) && alpha == 255 )
	{
		Format(diceText, sizeof(diceText), "%t", "colored", ((red / 255) * 100), ((green / 255) * 100), ((blue / 255) * 100));
	}
	else if(red == 255 && green == 255 && blue == 255)
	{
		Format(diceText, sizeof(diceText), "%t", "transparented", ((alpha / 255) * 100));
	}
	else
	{
		Format(diceText, sizeof(diceText), "%t", "both", ((red / 255) * 100), ((green / 255) * 100), ((blue / 255) * 100), ((alpha / 255) * 100));
	}
	
	
	return DiceStatus_Success;
}