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

int activeOffset = -1;
//int clip1Offset = -1;
int priAmmoTypeOffset = -1;
//int clip2Offset = -1;
int secAmmoTypeOffset = -1;


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
	activeOffset = FindSendPropInfo("CAI_BaseNPC", "m_hActiveWeapon");
	
	//clip1Offset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	priAmmoTypeOffset = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoCount");
		
	//clip2Offset = FindSendPropInfo("CBaseCombatWeapon", "m_iClip2");
	secAmmoTypeOffset = FindSendPropInfo("CBaseCombatWeapon", "m_iSecondaryAmmoCount");
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
	if(MDIsStringSet(p_weaponId)) {
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
		GiveItem(client, p_weaponId);
	}
	
	// Only set the ammo if mag size given
	if(primaryMagSize > 0 && secondaryMagSize > 0) {
			SetAmmo(client, primaryMagSize, secondaryMagSize);
	}
	
	Format(diceText, sizeof(diceText), "You got a weapon!");
}

int GiveItem(int client, char[] weaponId)
{
	int entryIndex = GivePlayerItem(client, weaponId);
	return entryIndex;
}

void SetAmmo(int client, int primarySpare, int secondSpare)
{
	int zomg = GetEntDataEnt2(client, activeOffset);
	if(zomg != -1) {
		//if (clip1Offset != -1){ // Primary loaded ammo
		//	SetEntData(zomg, clip1Offset, primaryLoaded, 4, true);
		//}
		if (priAmmoTypeOffset != -1) { // Primary spare ammo
			SetEntData(zomg, priAmmoTypeOffset, primarySpare, 4, true);
		}
		//if (clip2Offset != -1) { // Secondary loaded ammo
		//	SetEntData(zomg, clip2Offset, secondLoaded, 4, true);
		//}
		if (secAmmoTypeOffset != -1) { // Secondary spare ammo
			SetEntData(zomg, secAmmoTypeOffset, secondSpare, 4, true);
		}
	}
}
