/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin Info
#define MD_PLUGIN_VERSION "0.1"
#define MD_PLUGIN_NAME "MagicDice - Modular Roll The Dice Plugin"
#define MD_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MD_PLUGIN_DESCRIPTION "A Modular Roll The Dice Plugin. Supporting on the fly feature un/re-load"
#define MD_PLUGIN_WEBSITE "https://ptl-clan.de"



#define DEBUG true

char MD_PREFIX[12] = "[MagicDice]";

Handle g_modulesArray;

public Plugin myinfo =
{
	name = MD_PLUGIN_NAME,
	author = MD_PLUGIN_AUTHOR,
	description = MD_PLUGIN_DESCRIPTION,
	version = MD_PLUGIN_VERSION,
	url = MD_PLUGIN_WEBSITE
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	RegPluginLibrary("magicdice");
	CreateNative("MDRegisterModule", Native_MDRegisterModule);
	CreateNative("MDUnRegisterModule", Native_MDUnRegisterModule);
	CreateNative("MDPublishDiceResult", Native_MDPublishDiceResult);
}

public void OnPluginStart()
{
	g_modulesArray = CreateArray(128);
	RegConsoleCmd("md", OnDiceCommand);
}

//public void MDLog(const char[] format, any...)
//{
//
	////Format("%s %s", MD_PREFIX, params);
	//char buffer[300];
	//VFormat(buffer, sizeof(buffer), format, 2);
	////PrintToServer("%s %s", MD_PREFIX, buffer);
//}

// A new module want to be added	
public int Native_MDRegisterModule(Handle plugin, int params)
{
	char moduleName[255];
	GetPluginInfo(plugin, PlInfo_Name, moduleName, sizeof(moduleName));
	
	char fullModuleName[64];
	GetNativeString(1, fullModuleName, sizeof(fullModuleName));
	
	// Add the plugin to our list
	PushArrayCell(g_modulesArray, plugin);
	
	PrintToServer("%s Registered %s [%s]", MD_PREFIX, moduleName, fullModuleName);	
}

public int Native_MDUnRegisterModule(Handle plugin, int params)
{
	char moduleName[255];
	GetPluginInfo(plugin, PlInfo_Name, moduleName, sizeof(moduleName));
	
	// Add the plugin to our list
	PushArrayCell(g_modulesArray, plugin);
	for (int i = 0;  i < GetArraySize(g_modulesArray); i++)
	{
		Handle module = view_as<Handle>(GetArrayCell(g_modulesArray, i));
		if(module == plugin)
		{
			RemoveFromArray(g_modulesArray, i);
			PrintToServer("%s Un-Registered %s", MD_PREFIX, moduleName);	
			break;
		}
	}
}

public int Native_MDPublishDiceResult(Handle plugin, int params)
{
	char diceText[64];
	int client = GetNativeCell(1);
	GetNativeString(2, diceText, sizeof(diceText));
	
	// TODO Show just in debug mode
	char clientName[128];
	GetClientName(client, clientName, sizeof(clientName));
	PrintToServer("%s %s rolled %", MD_PREFIX, clientName, diceText);
}

public void ProcessResult(int choosenModuleIndex, int client)
{
	Handle module = view_as<Handle>(GetArrayCell(g_modulesArray, choosenModuleIndex));
	
	// Get the function of the module
	Function id = GetFunctionByName(module, "MDEvaluateResult");
	if(id == INVALID_FUNCTION){
		// TODO Remove invalid modules
		ThrowError("The selected result index %i is not registred. FunctionId is invalid", choosenModuleIndex);
	}
	
	// Call the function in the module
	Call_StartFunction(module, id);
	Call_PushCell(choosenModuleIndex);
	Call_PushCell(client);
	Call_Finish();	
}

public Action OnDiceCommand(int client, int params)
{
	if(!hasModules())
	{
		PrintToServer("%s No modules available! You should load at least one module.", MD_PREFIX);	
		PrintToChat(client, "%s No dice results available!");
		return Plugin_Continue;
	}
	// TODO Replace with real random
	int choosenIndex = GetRandomInt(0, GetArraySize(g_modulesArray) -1);
	ProcessResult(choosenIndex, client);
	return Plugin_Handled;
}

public bool hasModules()
{
	return GetArraySize(g_modulesArray) > 0;
}