/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Module: Weapon                                    #
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
#define MODULE_PLUGIN_NAME "MagicDice - Weapon Module"
#define MODULE_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MODULE_PLUGIN_DESCRIPTION "Gives a player a weapon"
#define MODULE_PLUGIN_WEBSITE "https://ptl-clan.de"

#include ../include/magicdice
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

int m_iClip1 = -1;
int m_iClip2 = -1;
int m_iAmmo = -1;
int m_iPrimaryAmmoType = -1;

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
	m_iClip1 			= FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	m_iClip2 			= FindSendPropInfo("CBaseCombatWeapon", "m_iClip2");
	m_iAmmo  			= FindSendPropInfo("CBasePlayer",     	"m_iAmmo");
	m_iPrimaryAmmoType  = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
}
public void OnAllPluginsLoaded()
{
	MDRegisterModule("Weapon");
}

public void OnPluginEnd()
{
	MDUnRegisterModule();
}

public void Diced(int client, char diceText[255], char[] p_weaponId, char[] p_amount, char[] p_primaryMagSize, char[] p_secondaryMagSize, char[] p_5)
{
	// Validate parameter
	if(!MDIsStringSet(p_weaponId)) {
		MDReportInvalidParameter(1, "weaponId", p_weaponId);
		return;
	}
	
	int amount = MDParseParamInt(p_amount);
	if (amount == 0) {
		MDReportInvalidParameter(2, "amount", p_amount);
		return;
	}
	
	int primaryMagSize = MDParseParamInt(p_primaryMagSize);
	int secondaryMagSize = MDParseParamInt(p_secondaryMagSize);


	// Give the player the requested amount of weapons
	for (int i = 0; i < amount; i++) {
		int weaponIndex = GiveItem(client, p_weaponId);
		// To find weaponId in m_iAmmo array we should add multiplied m_iPrimaryAmmoType datamap offset by 4 onto m_iAmmo player array, meh
		int weaponId = GetEntData(weaponIndex, m_iPrimaryAmmoType) * 4;
		if(primaryMagSize > 0) {
			SetEntData(weaponIndex, m_iClip1, primaryMagSize);
			SetEntData(weaponIndex, m_iClip2, primaryMagSize); // What does the second clip?!
		}
		if(secondaryMagSize > 0) {
			SetEntData(client, m_iAmmo + weaponId, secondaryMagSize);
		}
	}
	
	char weaponName[32];
	strcopy(weaponName, sizeof(weaponName), p_weaponId);
	// Strip the weapon_ from the id of the weapon
	ReplaceString(weaponName, 32, "weapon_", "");
	weaponName[0] = CharToUpper(weaponName[0]);
	
	if(primaryMagSize == 0 || secondaryMagSize == 0) 
	{
		Format(diceText, sizeof(diceText), "%i %s", amount, weaponName);
	} else {
		Format(diceText, sizeof(diceText), "%i %s with %i/%i ammunation", amount, weaponName, primaryMagSize, secondaryMagSize);
	}
}

int GiveItem(int client, char[] weaponId)
{
	int entryIndex = GivePlayerItem(client, weaponId);
	return entryIndex;
}