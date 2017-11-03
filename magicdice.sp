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
#include <autoexecconfig>
#include <cstrike>


// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin Info
#define MD_PLUGIN_VERSION "0.1"
#define MD_PLUGIN_NAME "MagicDice - Modular Roll The Dice Plugin"
#define MD_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MD_PLUGIN_DESCRIPTION "A Modular Roll The Dice Plugin. Supporting on the fly feature un/re-load"
#define MD_PLUGIN_WEBSITE "https://ptl-clan.de"

// Config cvars
#define CONF_CVAR_DICES_PER_ROUND 		"sm_md_dices_per_round"
ConVar g_cvar_dicesPerRound;

#define CONF_CVAR_ALLOW_DICE_TEAM_T 	"sm_md_allow_dice_team_t"
ConVar g_cvar_allowDiceTeamT;

#define CONF_CVAR_ALLOW_DICE_TEAM_CT 	"sm_md_allow_dice_team_ct"
ConVar g_cvar_allowDiceTeamCT;



#define DEBUG true

char MD_PREFIX[12] = "[MagicDice]";

Handle g_modulesArray;

int g_probabillities[128];

// How many times has an user rolled the dice?
int g_dices[MAXPLAYERS + 1];
// How many times can an user roll the dice?
int g_allowedDices[MAXPLAYERS + 1];

// A switch to block general dices while the game / round is ending
bool g_cannotDice = true;

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

void PrepareAndLoadConfig()
{
	AutoExecConfig_SetFile("general", "magicdice");

	// Dices per round
	g_cvar_dicesPerRound = 		AutoExecConfig_CreateConVar(CONF_CVAR_DICES_PER_ROUND, "1", "Starting amount of dices allowed each round");
	
	// Team dice restrictions
	g_cvar_allowDiceTeamT = 	AutoExecConfig_CreateConVar(CONF_CVAR_ALLOW_DICE_TEAM_T, "1", "Can the T-team dice?");
	g_cvar_allowDiceTeamCT = 	AutoExecConfig_CreateConVar(CONF_CVAR_ALLOW_DICE_TEAM_CT, "0", "Can the CT-team dice?");
	
	LoadTranslations("magicdice.phrases");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnPluginStart()
{
	g_modulesArray = CreateArray(128);
	RegConsoleCmd("md", OnDiceCommand, "Rolls the dice");
	RegConsoleCmd("mdtest", OnDiceCommandFocedValue, "Test command for the dice. Rolls the dice result with the given number", ADMFLAG_CHEATS);
	
	LoadProbabillities(g_probabillities);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	PrepareAndLoadConfig();
	
	g_cannotDice = false;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	ResetDiceCounters();
	g_cannotDice = false;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	UpdateAllAllowedDices(0); // Block any more dices to  the end of the round
	g_cannotDice = true; // Disable dice in round end phase to prevent round overlapping bugs (like rockets)
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
	char moduleName[128];
	GetPluginInfo(plugin, PlInfo_Name, moduleName, sizeof(moduleName));
	
	char moduleFileName[64];
	GetPluginFilename(plugin, moduleFileName, sizeof(moduleFileName));
	
	// Add the plugin to our list
	PushArrayCell(g_modulesArray, plugin);
	
	PrintToServer("%s Registered [%s] from: %s", MD_PREFIX, moduleName, moduleFileName);	
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
	char diceText[255];
	int client = GetNativeCell(1);
	GetNativeString(2, diceText, sizeof(diceText));
	int dicedResultNumber = GetNativeCell(3);
	
	// TODO Show just in debug mode
	char clientName[128];
	GetClientName(client, clientName, sizeof(clientName));
#if defined DEBUG
	PrintToServer("%s %s rolled %s", MD_PREFIX, clientName, diceText);
#endif
	CReplyToCommand(client, "{lightgreen}%s {default}({grey}%i{default}) {mediumvioletred}%s", MD_PREFIX, dicedResultNumber, diceText);
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
		CReplyToCommand(client, "{lightgreen}%s {default}%t", MD_PREFIX, "no_modules_registered");
		return Plugin_Continue;
	}
	
	if(!CanPlayerDiceInTeam(client)){
		CReplyToCommand(client, "{lightgreen}%s {orange}%t", MD_PREFIX, "dice_not_allowed_for_your_team");
		return Plugin_Handled;
	}
	if(!CanPlayerDice(client)){
		CReplyToCommand(client, "{lightgreen}%s %t", 
			MD_PREFIX, "all_dices_are_gone", g_allowedDices[client]);
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
		CReplyToCommand(client, "{lightgreen}%s %t", MD_PREFIX, "missing_fixed_result_test_parameter");
		return Plugin_Handled;
	}
	char buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	int index = StringToInt(buffer);
	
	if(index > sizeof(g_probabillities) || g_probabillities[index] == 0){
		CReplyToCommand(client, "{lightgreen}%s %t", MD_PREFIX, "not_found_fixed_result", index);
		return Plugin_Handled;
	}
	
	CReplyToCommand(client, "%s %t", MD_PREFIX, "using_fixed_dice_result", index);
	LoadResultDeatailsAndProcess(index, client);
	return Plugin_Handled;
}

KeyValues LoadConfig()
{
	KeyValues kv = new KeyValues("Results");
	kv.ImportFromFile("cfg/magicdice/results.cfg");
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
						CReplyToCommand(client, "{lightgreen}%s {default}Sorry, the responsible module for this result died / or was never alive at all :(", MD_PREFIX);
						CReplyToCommand(client, "{lightgreen}%s {default}...but great news! You can roll the dice one more time!", MD_PREFIX);
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
	// Adds .smx to the seached module name
	char searchedWithExtension[32];
	Format(searchedWithExtension, sizeof(searchedWithExtension), "%s.smx", searched);
	
	// Search for a module matching with matching filename
	for (int i = 0;  i < GetArraySize(g_modulesArray); i++)
	{
		Handle module = view_as<Handle>(GetArrayCell(g_modulesArray, i));
		char moduleFileName[64];
		// Compare name of the current module with the search string
		GetPluginFilename(module, moduleFileName, sizeof(moduleFileName));
		if (strcmp(searchedWithExtension, moduleFileName) == 0){
			// Found a matching module!
			return module;
		}
	}
	// NO matching modules found :(
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

public bool CanPlayerDiceInTeam(int client)
{
	// Can the player dice within its team?
	int team = GetClientTeam(client);
	char buffer[11];
	if(team == CS_TEAM_T) {
		g_cvar_allowDiceTeamT.GetString(buffer, sizeof(buffer));
		int allowed = StringToInt(buffer);
		if(allowed == 1) {

			return true;
		}
	}else if(team == CS_TEAM_CT) {
		g_cvar_allowDiceTeamCT.GetString(buffer, sizeof(buffer));
		int allowed = StringToInt(buffer);
		if(allowed == 1) {
			return true;
		}
	} 
	return false; // Unknown team // not allowed
}

public bool CanPlayerDice(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) {
		CReplyToCommand(client, "{lightgreen}%s %t", MD_PREFIX, "dice_not_possible_when_dead");
		return false;
	}
	
	if(g_cannotDice) {
		CReplyToCommand(client, "{lightgreen}%s %t", MD_PREFIX, "dice_not_possible_in_this_game_phase");
		return false;
	}
	
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
		// Get the allowed amout of dices from teh cvar
		char buffer[11];
		g_cvar_dicesPerRound.GetString(buffer, sizeof(buffer));
		int allowed = StringToInt(buffer);
		
		g_dices[client] = 0; // Reset current dices of the player
		g_allowedDices[client] = allowed; // Set new limit
}

public bool hasModules()
{
	return GetArraySize(g_modulesArray) > 0;
}