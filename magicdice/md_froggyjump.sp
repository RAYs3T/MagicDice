/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: FroggyJump                                #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin info
#define MODULE_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MODULE_PLUGIN_NAME "MagicDice - FroggyJump Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Lets you jump multiple times mid air"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice

int g_froggyJumpAllowedCount[MAXPLAYERS + 1] =  { 0, ... };
int g_froggyJumpCount[MAXPLAYERS + 1] =  { 0, ... };

static bool bPressed[MAXPLAYERS + 1] = { false, ... };

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
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
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
	int possibleJumps = MDParseParamInt(param1);
	if(possibleJumps == 0)
	{
		MDReportInvalidParameter(1, "Jump count", param1);
		return;
	}
	g_froggyJumpAllowedCount[client] = possibleJumps;
	
	Format(diceText, sizeof(diceText), "%t", "froggy_jump", possibleJumps);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	// Reset all allowed jump counters
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		g_froggyJumpAllowedCount[i] = 0;
	}
}

public void FroggyJump(int client)
{
	float velocity[3];
	float velocity0;
	float velocity1;
	float velocity2;
	float velocity2_new;
	
	velocity0 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	velocity1 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	velocity2 = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	
	velocity2_new = 260.0;
	
	// TODO May replace this with a propper calculation 
	if (velocity2 < 150.0)
		velocity2_new = 270.0;
	if (velocity2 < 100.0)
		velocity2_new = 300.0;
	if (velocity2 < 50.0)
		velocity2_new = 330.0;
	if (velocity2 < 0.0)
		velocity2_new = 380.0;
	if (velocity2 < -50.0)
		velocity2_new = 400.0;
	if (velocity2 < -100.0)
		velocity2_new = 430.0;
	if (velocity2 < -150.0)
		velocity2_new = 450.0;
	if (velocity2 < -200.0)
		velocity2_new = 470.0;
	
	velocity[0] = velocity0 * 0.1;
	velocity[1] = velocity1 * 0.1;
	velocity[2] = velocity2_new;
	
	SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", velocity);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_froggyJumpAllowedCount[client] <= 0)
		return Plugin_Continue;
	
	
	if (GetEntityFlags(client) & FL_ONGROUND)
	{
		g_froggyJumpCount[client] = 0;
		bPressed[client] = false;
	}
	else
	{
		if (buttons & IN_JUMP)
		{
			if (!bPressed[client])
			{
				if (g_froggyJumpCount[client] > 0 && g_froggyJumpCount[client] <= g_froggyJumpAllowedCount[client])
				{
					FroggyJump(client);
				}
				g_froggyJumpCount[client]++;
			}
			
			bPressed[client] = true;
		}
		else 
		{
			bPressed[client] = false;
		}
	}
	
	
	return Plugin_Continue;
}