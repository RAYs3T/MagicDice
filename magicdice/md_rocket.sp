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
#define MODULE_PLUGIN_NAME "MagicDice - Rocket Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Lets the player reach the moon"
#define MODULE_PLUGIN_WEBSITE "https://gitlab.com/PushTheLimits/Sourcemod/MagicDice"

#include ../include/magicdice
#include sdktools




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

public void OnMapStart()
{
	PrecacheSound("weapons/rpg/rocketfire1.wav");
	PrecacheSound("weapons/rpg/rocket1.wav");
}

public void OnPluginEnd()
{
	MDUnRegisterModule();
}

public DiceStatus Diced(int client, char diceText[255], char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	StartRocket(client);
	Format(diceText, sizeof(diceText), "%t", "diced");
	return DiceStatus_Success;
}

public void StartRocket(int client)
{
	float origin[3];
	
	GetClientAbsOrigin(client, origin);
	
	origin[2] = origin[2] + 20;
	
	//godmode(client, true);
	Shake(client, 10.0, 40.0, 25.0);
	
	EmitSoundToAll("weapons/rpg/rocketfire1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	CreateTimer(1.0, PlayRocketSound, client);
	CreateTimer(3.1, EndRocket, client);
}

public Action PlayRocketSound(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	float origin[3];
	
	GetClientAbsOrigin(client, origin);
	
	origin[2] = origin[2] + 50;
	
	EmitSoundToAll("weapons/rpg/rocket1.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	for (int x = 1; x <= 15; x++)
	CreateTimer(0.2 * x, RocketLoop, client);
	
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
}
public Action RocketLoop(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	float velocity[3];
	
	velocity[2] = 300.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	
	return Plugin_Handled;
}

public Action EndRocket(Handle timer, any client)
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if (IsClientConnected(x))
			StopSound(x, SNDCHAN_AUTO, "weapons/rpg/rocket1.wav");
	}
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	float origin[3];
	
	GetClientAbsOrigin(client, origin);
	
	origin[2] = origin[2] + 50;
	
	
	EmitSoundToAll("weapons/hegrenade/explode3.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	int expl = CreateEntityByName("env_explosion");
	
	TeleportEntity(expl, origin, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(expl, "fireballsprite", "sprites/zerogxplode.spr");
	DispatchKeyValue(expl, "spawnflags", "0");
	DispatchKeyValue(expl, "iMagnitude", "1000");
	DispatchKeyValue(expl, "iRadiusOverride", "100");
	DispatchKeyValue(expl, "rendermode", "0");
	
	DispatchSpawn(expl);
	ActivateEntity(expl);
	
	AcceptEntityInput(expl, "Explode");
	AcceptEntityInput(expl, "Kill");
	
	//godmode(client, false);
	ForcePlayerSuicide(client);
	
	return Plugin_Handled;
}

stock void Shake(int client, float time, float distance, float value)
{
	Handle message = StartMessageOne("Shake", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(message, "command", 0);
		PbSetFloat(message, "local_amplitude", value);
		PbSetFloat(message, "frequency", distance);
		PbSetFloat(message, "duration", time);
	}
	else
	{
		BfWriteByte(message, 0);
		BfWriteFloat(message, value);
		BfWriteFloat(message, distance);
		BfWriteFloat(message, time);
	}
	
	EndMessage();
}