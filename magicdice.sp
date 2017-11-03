/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/

// Includes
#include <morecolors>


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

int g_probabillities[128];

// How many times has an user rolled the dice?
int g_dices[MAXPLAYERS + 1];
// How many times can an user roll the dice?
int g_allowedDices[MAXPLAYERS + 1];

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
	CreateNative("MDAddAllowedDices", Native_MDAddAllowedDices);
}

public void OnPluginStart()
{
	g_modulesArray = CreateArray(128);
	RegConsoleCmd("md", OnDiceCommand, "Rolls the dice");
	RegConsoleCmd("mdtest", OnDiceCommandFocedValue, "Test command for the dice. Rolls the dice result with the given number", ADMFLAG_ROOT);
	
	LoadProbabillities(g_probabillities);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ResetDiceCounters();
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	UpdateAllAllowedDices(0); // Block any more dices to  the end of the round
}

public void OnClientAuthorized(int client, const char[] auth)
{
	// When still in the round a client may leave the game
	// However an other client could connect and get the same index as the client before
	// so we need to clean counters and other fields
	ResetDiceCounter(client);
}

// Adds a new module to the module list
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

// Removes a module from the module list
public int Native_MDUnRegisterModule(Handle plugin, int params)
{
	char moduleName[255];
	GetPluginInfo(plugin, PlInfo_Name, moduleName, sizeof(moduleName));
	
	// Remove the plugin from the list
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

// Called by modules, pushishes a text from the module. This text is displayed ingame
public int Native_MDPublishDiceResult(Handle plugin, int params)
{
	char diceText[64];
	int client = GetNativeCell(1);
	GetNativeString(2, diceText, sizeof(diceText));
	int dicedResultNumber = GetNativeCell(3);
	
	// TODO Show just in debug mode
	char clientName[128];
	GetClientName(client, clientName, sizeof(clientName));
#if defined DEBUG
	PrintToServer("%s %s rolled %s", MD_PREFIX, clientName, diceText);
#endif
	CPrintToChat(client, "{lightgreen}%s {olive}({green}%i{olive}) {olive}%s", MD_PREFIX, dicedResultNumber, diceText);
}

// Adds additionals dices for a user
// This can be usefull for some modules that wants to manipulate the dice counters
public int Native_MDAddAllowedDices(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	int additionalDiceAmount = GetNativeCell(2);
	g_allowedDices[client] += additionalDiceAmount;
}

// When a use rolls the dice
public Action OnDiceCommand(int client, int params)
{
	if(!hasModules())
	{
		PrintToServer("%s No modules available! You should load at least one module.", MD_PREFIX);	
		CPrintToChat(client, "{lightgreen}%s {default}No dice results available!", MD_PREFIX);
		return Plugin_Continue;
	}
	if(!CanPlayerDice(client)){
		CPrintToChat(client, "{lightgreen}%s {default}All your dices are gone! ({green}%i{default}) - {green}try again in the next round!", 
			MD_PREFIX, g_allowedDices[client]);
		return Plugin_Handled;
	}
	// TODO Replace with real random
	//int choosenIndex = GetRandomInt(0, GetArraySize(g_modulesArray) -1);
	PickResult(client);
	g_dices[client]++;
	return Plugin_Handled;
}

// Rolls a pre choosen result
public Action OnDiceCommandFocedValue(int client, int params)
{
	if(params != 1) {
		CPrintToChat(client, "{lightgreen}%s {default}Parameter (dice number) required for fixed result test", MD_PREFIX);
		return Plugin_Handled;
	}
	char buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	int index = StringToInt(buffer);
	
	if(index > sizeof(g_probabillities) || g_probabillities[index] == 0){
		CPrintToChat(client, "{lightgreen}%s {default}Invalid dice result: %i", MD_PREFIX, index);
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%s Using a fixed result for dice: %i", MD_PREFIX, index);
	LoadResultDeatailsAndProcess(index, client);
	return Plugin_Handled;
}

KeyValues LoadConfig()
{
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/magicdice/results.cfg");
	KeyValues kv = new KeyValues("Results");
	kv.ImportFromFile(file);
	return kv;
}

//TODO Add a parsing method to validate modules specified in the config
// So we can warn the admin if any module is not loaded, but specified in the config

// Load the probabillities from the config and store them in the cache array
void LoadProbabillities(int[] probabillitiesBuffer)
{	
	KeyValues kv = LoadConfig();
	if (!kv.GotoFirstSubKey())
	{
		ThrowError("Unable to load value inside results config. First key not found!");
	}
	
	int lastResultNo = 0;
 
	char resultId[255];
	do {
		kv.GetSectionName(resultId, sizeof(resultId));
		int resultNo = StringToInt(resultId);
		
		// Result NOs need to be in the right order.
		// We check if a result had the correct number
		int expectedResult = lastResultNo++;
		if(resultNo != expectedResult) {
			ThrowError("Results are not in the correct order. Processed no: %i but expected %i", resultNo, expectedResult);
		}
		int probabillity = kv.GetNum("prob");
		if(probabillity < 1 || probabillity > 10) {
			ThrowError("Invalid probabillity (%i) specified for result: %i", probabillity, resultNo);
		}
		probabillitiesBuffer[resultNo] = probabillity;
#if defined DEBUG
		PrintToServer("Result %i with prob: %i", resultNo, probabillity);
#endif
	} while (kv.GotoNextKey());
 
	delete kv;
}

// Picks and processes the result
public void PickResult(int client)
{
	int selectedIndex = SelectByProbability(g_probabillities);
	PrintToServer("Picked result %i", selectedIndex);
	LoadResultDeatailsAndProcess(selectedIndex, client);
}

// Loads the responding feature parameters from the config
// Multiple invocations of different/same features could happen here if specified in the config
bool LoadResultDeatailsAndProcess(int resultNo, int client)
{	
	KeyValues kv = LoadConfig();
 
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		return false;
	}
 
 	char searchedResult[12];
 	IntToString(resultNo, searchedResult, sizeof(searchedResult));
 	
	// Iterate over subsections at the same nesting level
	char buffer[255];
	do {
		kv.GetSectionName(buffer, sizeof(buffer));
		if(strcmp(buffer, searchedResult) == 0) {
		
			int probabillity = kv.GetNum("prob");
			kv.GotoFirstSubKey(false);
			do {
				do {
					char bufferFeature[255];
					kv.GetSectionName(bufferFeature, sizeof(bufferFeature));
					char param1[32];
					char param2[32];
					char param3[32];
					char param4[32];
					char param5[32];
					kv.GetString("param1", param1, sizeof(param1));
					kv.GetString("param2", param2, sizeof(param2));
					kv.GetString("param3", param3, sizeof(param3));
					kv.GetString("param4", param4, sizeof(param4));
					kv.GetString("param5", param5, sizeof(param5));
#if defined DEBUG
					PrintToServer("Result: %s feature: %s prob: %i, p1: %s, p2: %s, p3: %s, p4: %s, p5: %s", 
						buffer, bufferFeature, probabillity, param1, param2, param3, param4, param5);
#endif
						
					Handle module = FindModuleByName(bufferFeature);
					if(module == INVALID_HANDLE) {
						LogError("No matching module found for name '%s' Is the responsible module loaded?", bufferFeature);
						CPrintToChat(client, "{lightgreen}%s {default}Sorry, the responsive module for this result died / or was never alive at all :(", MD_PREFIX);
						CPrintToChat(client, "{lightgreen}%s {default}...but great news! You can roll the dice one more time!", MD_PREFIX);
						// Since we had an internal plugin failure / configuration failure, we give the user one more roll.
						// So there is no reason to be sad :-)
						g_allowedDices[client] += 1;
					}
					ProcessResult(module, resultNo, client, param1, param2, param3, param4, param5);
				} while (kv.GotoNextKey());
			} while (kv.GotoNextKey());
			kv.GoBack();
		} // Not matching the searched result
	} while (kv.GotoNextKey());
 
	delete kv;
	return false;
}

// Searches for a module by its name
Handle FindModuleByName(char[] searched) 
{
	for (int i = 0;  i < GetArraySize(g_modulesArray); i++)
	{
		Handle module = view_as<Handle>(GetArrayCell(g_modulesArray, i));
		char moduleName[255];
		GetPluginInfo(module, PlInfo_Name, moduleName, sizeof(moduleName));
		if (strcmp(searched, moduleName) == 0){
			return module;
		}
	}
	return INVALID_HANDLE;
}

// Process the dice result for a roll
public void ProcessResult(Handle module, int resultNo, int client, char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	// Get the function of the module
	Function id = GetFunctionByName(module, "MDEvaluateResult");
	if(id == INVALID_FUNCTION){
		// TODO Remove invalid modules
		ThrowError("FunctionId is invalid");
	}
	
	// Call the function in the module
	Call_StartFunction(module, id);
	Call_PushCell(resultNo);
	Call_PushCell(client);
	Call_PushString(param1);
	Call_PushString(param2);
	Call_PushString(param3);
	Call_PushString(param4);
	Call_PushString(param5);
	Call_Finish();	
}




// Pickes a result depending on the probability
public int SelectByProbability(int modulePropabilities[128])
{
	int totalSum = 0;
	
	for (int i; i < sizeof(modulePropabilities); i++)
	{	
		totalSum += modulePropabilities[i];
	}
	
	int idx = GetRandomInt(0, totalSum);
	int sum = 0;
	int i = 0;
	while(sum < idx)
	{
		sum += modulePropabilities[i];
		i++;
	}
	
	int picked = i -1;
	if(picked < 0){
		picked = 0;
	}
#if defined DEBUG
	PrintToServer("%s Picked result: %i | probability: %i | results: %i | overall sum: %i", MD_PREFIX, picked, modulePropabilities[picked], i, totalSum);
#endif
	return picked;
}

public bool CanPlayerDice(int client)
{
	// TODO Check if the round is in the ending phase and block
	if(g_dices[client] >= g_allowedDices[client]) {
		return false;
	}
	
	return true;
}

public void UpdateAllAllowedDices(int newAllowedDices)
{
	for (int i = 0; i < MAXPLAYERS; i++){
		g_allowedDices[i] = newAllowedDices;
	} 
}

public void ResetDiceCounters()
{
	for (int i = 0; i < MAXPLAYERS; i++){
		ResetDiceCounter(i);
	} 
}

public void ResetDiceCounter(int client)
{
		g_dices[client] = 0;
		g_allowedDices[client] = 1; // One dice is allowed by default
}

public bool hasModules()
{
	return GetArraySize(g_modulesArray) > 0;
}