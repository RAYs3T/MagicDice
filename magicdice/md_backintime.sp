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
#define MODULE_PLUGIN_NAME "MagicDice - Back in Time"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "The Example module as reference"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice
#include <sdktools>

#define WARP_PAD_TIME 0.03
#define MAX_WARP_POINTS 512

enum WrapPointInfo 
{
	WP_X,
	WP_Y,
	WP_Z,
	WP_V1,
	WP_V2,
	WP_v3,
	WP_SET_FLG,
	WrapPointInfoSize
};

static int g_tickCounter = 0;
static bool g_playerIsWarping[MAXPLAYERS + 1] =  { false, ... };
static int g_playerWarpIndex[MAXPLAYERS + 1];

static float g_playerHistoryWarpPoints[MAXPLAYERS + 1][MAX_WARP_POINTS][WrapPointInfoSize];


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
	ResetWarpPoints();
	PrintToChatAll("Att1: %i", IN_ATTACK);
	PrintToChatAll("Att2: %i", IN_ATTACK2);
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
	MDAddAllowedDices(client, 2); // Allow the player to roll two more times!
	
	Format(diceText, sizeof(diceText), "%t", "diced");

	return DiceStatus_Success;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if((buttons & IN_ATTACK) && (buttons & IN_ATTACK2))
	{
		if(!g_playerIsWarping[client])
		{
			g_playerIsWarping[client] = true;
			PrintToChatAll("Client, %i Buttons: %i impulse: %i weapon: %i", client, buttons, impulse, weapon);
			
			g_playerWarpIndex[client] = MAX_WARP_POINTS - 1;
			CreateTimer(0.01, Timer_WarpPlayerBack, client, TIMER_REPEAT);
			SetEntityMoveType(client, MOVETYPE_NONE);
		}	
	}
	
	return Plugin_Continue;
}

public void OnGameFrame()
{
	if(g_tickCounter == TICK_PAD)
	{
		// Every TICK_PAD tick we track the players positions
		TrackWarpPoints();
		g_tickCounter = -1;
	}
	g_tickCounter++;
}

/*
 * Reset all player warp points to zero
 */
static void ResetWarpPoints()
{
	for (int client = 0; client < MaxClients; client++)
	{
		for (int point = 0; point < MAX_WARP_POINTS; point++)
		{
			for (int val = 0; val < view_as<int>(WrapPointInfoSize); val ++)
			{
				g_playerHistoryWarpPoints[client][point][val] = 0.0;
			}				
		}
	}
}

static void TrackWarpPoints()
{
	float position[3];
	float viewAngle[3];
	float newWarpPoint[WrapPointInfoSize];
	for (int client = 0; client < MaxClients; client++) // TODO Check if the feature is enabled for this client
	{
		if(g_playerIsWarping[client] || !IsValidClient(client) || !IsPlayerAlive(client))
		{
			continue;
		}
		
		GetClientAbsOrigin(client, position);
		//GetEntPropVector(client, Prop_Data, "m_angRotation", viewAngle);
		//GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", weaponOrigin);
		newWarpPoint[0] = position[0];
		newWarpPoint[1] = position[1];
		newWarpPoint[2] = position[2];
		//newWarpPoint[3] = viewAngle[0];
		//newWarpPoint[4] = viewAngle[1];
		//newWarpPoint[5] = viewAngle[2];
		newWarpPoint[6] = 1.0;
		AddWrapPointAndUpdateHistoryChain(client, newWarpPoint);
	} 
}

static void AddWrapPointAndUpdateHistoryChain(int client, float warpPoint[WrapPointInfoSize])
{
	// First we need to shift all old warp points one index to the left
	float value[WrapPointInfoSize];
	float valueBefore[WrapPointInfoSize] = {0.0, ...};
	for (int i = MAX_WARP_POINTS - 1; i >= 0; i--)
	{
		value = g_playerHistoryWarpPoints[client][i];
		if(valueBefore[6] == 0.0)
		{
			// Add the new point here
			g_playerHistoryWarpPoints[client][i] = warpPoint;
			//PrintToServer("Added warp point %f|%f|%f %f|%f|%f for %i", warpPoint[0], warpPoint[1], warpPoint[2], warpPoint[3], warpPoint[4], warpPoint[5], client);
		}
		else
		{
			// Set this to the value before
			g_playerHistoryWarpPoints[client][i] = valueBefore;
			valueBefore[6] = 1.0;
		}
		valueBefore = value;
	}	
}

public Action Timer_WarpPlayerBack(Handle timer, int client)
{
	int warpIndex = g_playerWarpIndex[client];
	
	float pos[3];
	pos[0] = g_playerHistoryWarpPoints[client][warpIndex][0];
	pos[1] = g_playerHistoryWarpPoints[client][warpIndex][1];
	pos[2] = g_playerHistoryWarpPoints[client][warpIndex][2];
	
	//PrintToChatAll("Warping... %f %f %f for index: %i", pos[0], pos[1], pos[2], warpIndex);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	
	if(warpIndex == 0)
	{
		// We reached the end of our warp history, no new timer is required
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
		return Plugin_Stop;
	}
	
	g_playerWarpIndex[client] = warpIndex - 1;
	
	return Plugin_Continue;
}