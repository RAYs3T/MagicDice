/* 
###################################################################################
# Copyright © 2017 Kevin Urbainczyk <kevin@rays3t.info> - All Rights Reserved     #
# Unauthorized copying of this file, via any medium is strictly prohibited.       #
# Proprietary and confidential.                                                   #
#                                                                                 #
# This file is part of the MagicDice-Plugin.                                      #
# Written by Kevin 'RAYs3T' Urbainczyk <kevin@rays3t.info>                        #
# Homepage: https://ptl-clan.de                                                   #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# File Description: This is the core plugin. All other components are loaded      #
#                   by this file.                                                 #
###################################################################################
*/

// Includes
#include <morecolors>
#include <autoexecconfig>
#include <cstrike>
#include <sdktools>

// Switch to enable / disable debugging 
#define DEBUG true

// Code style rules
#pragma semicolon 1
#pragma newdecls required

// Plugin Info
#define MD_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MD_PLUGIN_NAME "MagicDice - Modular Roll The Dice Plugin"
#define MD_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MD_PLUGIN_DESCRIPTION "A Modular Roll The Dice Plugin. Supporting on the fly feature un/re-load"
#define MD_PLUGIN_WEBSITE "https://ptl-clan.de"

// Config cvars
static ConVar g_cvar_dicesPerRound;
static ConVar g_cvar_allowDiceTeamT;
static ConVar g_cvar_allowDiceTeamCT;
static ConVar g_keepEmptyTeamDices;
static ConVar g_serverId;

// Plugin prefixes used by console and chat outputs
public char MD_PREFIX[12] = "[MagicDice]";
public char MD_PREFIX_COLORED[64] = "{white}[{cyan}MagicDice{white}]";

// Array size definitions
#define MAX_MODULES 6 //
#define MODULE_PARAMETER_SIZE 128

enum ModuleField // Helper enum for array access
{
	ModuleField_ModuleName, // Virtual field for the module name (from layer before)
	ModuleField_Probability, // Virtual field for the module probability (from layer before)
	ModuleField_Team, // Virtual field for the module's team (from layer before)
	ModuleField_Param1,
	ModuleField_Param2,
	ModuleField_Param3,
	ModuleField_Param4,
	ModuleField_Param5,
	MAX_MODULE_FIELDS // Fake last position to get the number of params
};

char g_results[256][MAX_MODULES][MAX_MODULE_FIELDS][MODULE_PARAMETER_SIZE]; // [result][modules][module_name|probability|params][param values]
int g_probabillities[256];
static Handle g_modulesArray;

// How many times has an user rolled the dice?
static int g_dices[MAXPLAYERS + 1];
// How many times can an user roll the dice?
static int g_allowedDices[MAXPLAYERS + 1];

// A switch to block general dices while the game / round is ending
static bool g_cannotDice = true;


// Core components include
#include core_components/configuration.inc
#include core_components/probability_calculation.inc
#include core_components/random_string_parser.inc
//#include core_components/database.inc


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
	g_cvar_dicesPerRound = 		AutoExecConfig_CreateConVar("sm_md_dices_per_round", "1", "Starting amount of dices allowed each round");
	
	// Team dice restrictions
	g_cvar_allowDiceTeamT = 	AutoExecConfig_CreateConVar("sm_md_allow_dice_team_t", "1", "Can the T-team dice?");
	g_cvar_allowDiceTeamCT = 	AutoExecConfig_CreateConVar("sm_md_allow_dice_team_ct", "0", "Can the CT-team dice?");
	
	g_keepEmptyTeamDices =		AutoExecConfig_CreateConVar("sm_md_keep_empty_team_dices", "1", "Do not count dices when one team is empty");
	
	g_serverId = 				AutoExecConfig_CreateConVar("sm_md_server_id", "-1", "ID of the Server for logging");
	
	LoadTranslations("magicdice.phrases");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnPluginStart()
{
	g_modulesArray = CreateArray(128);
	RegAdminCmd("mdtest", OnDiceCommandFocedValue, ADMFLAG_CHEATS, "Test command for the dice. Rolls the dice result with the given number");
	RegAdminCmd("md_reconfigure", OnReconfigureCommand, ADMFLAG_CONFIG, "Reloads and reconfigures the result configurations");
	
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	PrepareAndLoadConfig();
	
	g_cannotDice = false;
	PrintToServer("%s Plugin start", MD_PREFIX);
	
	//InitializeDatabase();
}


public void OnMapStart()
{
	LoadResults();
	LoadModules();	
}

public void OnPluginEnd()
{
	UnloadModules();
}

static void LoadModules() 
{
	char modules[256][MODULE_PARAMETER_SIZE];
	GetAllMyKnownModules(modules);
	for (int i = 0; i < sizeof(modules); i++)
	{	
		if(strcmp(modules[i], "") == 0)
		{
			continue; // empty / not an md module
		}
		ServerCommand("sm plugins load %s", modules[i]);
	}
}

static void UnloadModules()
{
	char modules[256][MODULE_PARAMETER_SIZE];
	GetAllMyKnownModules(modules);
	for (int i = 0; i < sizeof(modules); i++)
	{	if(strcmp(modules[i], "") == 0)
		{
			continue; // empty / not an md module
		}
		ServerCommand("sm plugins unload %s", modules[i]);
	}
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

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (strcmp(sArgs, "!w", false) == 0)
	{
		return OnDiceCommand(client);
	}
 
	/* Let say continue normally */
	return Plugin_Continue;
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
	CPrintToChat(client, "{lightgreen}%s {default}({grey}%i{default}) {mediumvioletred}%s", MD_PREFIX_COLORED, dicedResultNumber, diceText);
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
public Action OnDiceCommand(int client)
{
	if(!hasModules())
	{
		PrintToServer("%s No modules available! You should load at least one module.", MD_PREFIX);	
		CPrintToChat(client, "{lightgreen}%s {default}%t", MD_PREFIX_COLORED, "no_modules_registered");
		return Plugin_Continue;
	}
	
	if(!CanPlayerDiceInTeam(client)){
		CPrintToChat(client, "{lightgreen}%s {orange}%t", MD_PREFIX_COLORED, "dice_not_allowed_for_your_team");
		return Plugin_Handled;
	}
	if(!CanPlayerDice(client)){
		// We expect that the method for checking this condition is reporting any failure to the player
		// So we don't display another message here
		return Plugin_Handled;
	}
	// TODO Replace with real random
	//int choosenIndex = GetRandomInt(0, GetArraySize(g_modulesArray) -1);
	PickResult(client);
	
	if(GetConVarBool(g_keepEmptyTeamDices) == true && IsSingleTeamEmpty()) 
	{
		CPrintToChat(client, "%s %t", MD_PREFIX_COLORED, "dices_are_keept_empty_team");
	}
	else
	{
		g_dices[client]++;
	}
	return Plugin_Handled;
}

// Rolls a pre choosen result
public Action OnDiceCommandFocedValue(int client, int params)
{
	if(params != 1) {
		CPrintToChat(client, "{lightgreen}%s %t", MD_PREFIX_COLORED, "missing_fixed_result_test_parameter");
		return Plugin_Handled;
	}
	char buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	int index = StringToInt(buffer);
	
	if(index > sizeof(g_probabillities) || g_probabillities[index] == 0){
		CPrintToChat(client, "{lightgreen}%s %t", MD_PREFIX_COLORED, "not_found_fixed_result", index);
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "%s %t", MD_PREFIX_COLORED, "using_fixed_dice_result", index);
	PickResult(client, index);
	return Plugin_Handled;
}

public Action OnReconfigureCommand(int client, int params)
{
	// Ensure that nobody can dice while the plugin is reloading the configuration
	// This config reload could happen in the game end phase
	// We need to ensure that the blocking switch is restored with the status it had before
	// This could lead into trouble if the reloading happens when the round restarts
	bool oldBlockState = g_cannotDice;
	// now change the switch - We block any dice attemps
	g_cannotDice = true;
	
	// Fetch configs
	LoadResults();
	
	PrintToServer("%s Checking for new added, but not loaded plugins ...", MD_PREFIX);
	char modules[256][MODULE_PARAMETER_SIZE];
	GetAllMyKnownModules(modules);
	for (int i = 0; i < sizeof(modules); i++)
	{	if(strcmp(modules[i], "") == 0 || StrContains(modules[i], "md_", true) == -1)
		{
			continue; // empty / not an md module
		}
		if(FindModuleByName(modules[i]) == INVALID_HANDLE)
		{
			// This plugin is specified in the config but not loaded yet, loading ...
			ServerCommand("sm plugins load %s", modules[i]);
		}
	}
	
	// May release the block, depending on the old state
	g_cannotDice = oldBlockState;
}

// Picks and processes the result
static void PickResult(int client, int forcedResult = -1)
{
	int selectedIndex;
	int team = GetClientTeam(client);
	
	if(forcedResult != -1)
	{
		selectedIndex = forcedResult;
	} 
	else
	{
		// Now things getting complicated:
		// We store all results by index, but when it comes to team selection
		// this indexes are no loger valid for our probability selection.
		// So we need to remap them to get only the ones matching for the requested team
		// (othwewise we would mess up the probability selection)
		// At the end (when a result for a team is choosen), we need to get its original index again.
				
		int teamProbabillities[256][2];
		bool hasResults = GetTeamProbabillities(teamProbabillities, team);
		if(!hasResults)
		{
			// No results for the clients team
			CPrintToChat(client, "%s %t", MD_PREFIX_COLORED, "no_dice_results_for_your_team");
			return;
		}
		
		int selectableProbabillities[256];
		for (int i = 0; i < sizeof(teamProbabillities); i++)
		{
			selectableProbabillities[i] = teamProbabillities[i][1];
		}
		
		int selectedTeamProbability = SelectByProbability(selectableProbabillities);
		// Get the real result index
		selectedIndex = teamProbabillities[selectedTeamProbability][0];
	}
	
	int moduleCount = 0;
	char moduleNames[MAX_MODULES][MODULE_PARAMETER_SIZE];
	char moduleParams[MAX_MODULES][MAX_MODULE_FIELDS][MODULE_PARAMETER_SIZE];
	
	PrintToServer("Picked result %i", selectedIndex);
	for (int i = 0; i < MAX_MODULES; i++)
	{
		if(strcmp(g_results[selectedIndex][i][1], "") != 0)
		{
			Handle module = FindModuleByName(g_results[selectedIndex][i][ModuleField_ModuleName]);
			bool success = ProcessResult(module, selectedIndex, client, 
			g_results[selectedIndex][i][ModuleField_Param1], 
			g_results[selectedIndex][i][ModuleField_Param2], 
			g_results[selectedIndex][i][ModuleField_Param3], 
			g_results[selectedIndex][i][ModuleField_Param4], 
			g_results[selectedIndex][i][ModuleField_Param5]);
			if(!success)
			{
				LogError("%s Unable to process with result module: %s", MD_PREFIX, g_results[selectedIndex][i][ModuleField_ModuleName]);
				CPrintToChat(client, "%s %t", MD_PREFIX_COLORED, "dice_module_error");
			}
			
			moduleNames[moduleCount] = g_results[selectedIndex][i][ModuleField_ModuleName];
			moduleParams[moduleCount][0] = g_results[selectedIndex][i][ModuleField_Param1];
			moduleParams[moduleCount][1] = g_results[selectedIndex][i][ModuleField_Param2];
			moduleParams[moduleCount][2] = g_results[selectedIndex][i][ModuleField_Param3];
			moduleParams[moduleCount][3] = g_results[selectedIndex][i][ModuleField_Param4];
			moduleParams[moduleCount][4] = g_results[selectedIndex][i][ModuleField_Param5];
			moduleCount++;
		} else {
			break; // No more modules to process for this result
		}
	}
	
	// Get the steamId for logging ...
	char steamId[32];
	if(!GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId)))
	{
		LogError("Unable to get client AuthID: %i", client);
	}
	
	int serverId = GetConVarInt(g_serverId);
	//QLogResult(serverId, selectedIndex, steamId, team, moduleNames, moduleParams, moduleCount);
}

/*
 * Find all the module names of the modules that are currently registered at the core
 * @param collectedModules buffer for the module names to
 */
static void GetAllMyKnownModules(char collectedModules[256][MODULE_PARAMETER_SIZE])
{
	int addedModules = 0;
	for (int r = 0; r < 256; r++) // Loop trough the results
	{
		for (int m = 0; m < MAX_MODULES; m++) // Loop trough the modules of a result
		{
			bool inList = false;
			char currentModule[MODULE_PARAMETER_SIZE];
			for (int c = 0; c < sizeof(collectedModules); c++) // Loop trough all the results we have allready collected
			{
				if(strcmp(g_results[r][m][ModuleField_ModuleName], collectedModules[c]) == 0)
				{
					inList = true;
					break;
				}else {
					currentModule = g_results[r][m][ModuleField_ModuleName];
				}
			}
			if(!inList 	// Not in the list yet 
				&& strcmp(g_results[r][m][ModuleField_ModuleName], "") != 0 // Not empty
				&& StrContains(g_results[r][m][ModuleField_ModuleName], "md_", true) != -1) // is a module 
			{
				// The current module is not in the collected list yet, add it
				collectedModules[addedModules++] = g_results[r][m][ModuleField_ModuleName];		
			}
		}
	}
}

// Searches for a module by its name
static Handle FindModuleByName(char[] searched) 
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
public bool ProcessResult(Handle module, int resultNo, int client, char[] param1, char[] param2, char[] param3, char[] param4, char[] param5)
{
	// Get the function of the module
	Function id = GetFunctionByName(module, "MDEvaluateResult");
	if(id == INVALID_FUNCTION){
		// TODO Remove invalid modules
		ThrowError("FunctionId is invalid");
	}
	
	char selectedValue1[MODULE_PARAMETER_SIZE];
	bool isParamRandom1 = ParseRandomParameter(param1, selectedValue1);
	char selectedValue2[MODULE_PARAMETER_SIZE];
	bool isParamRandom2 = ParseRandomParameter(param2, selectedValue2);
	char selectedValue3[MODULE_PARAMETER_SIZE];
	bool isParamRandom3 = ParseRandomParameter(param3, selectedValue3);
	char selectedValue4[MODULE_PARAMETER_SIZE];
	bool isParamRandom4 = ParseRandomParameter(param4, selectedValue4);
	char selectedValue5[MODULE_PARAMETER_SIZE];
	bool isParamRandom5 = ParseRandomParameter(param5, selectedValue5);
				
	// Call the function in the module
	Call_StartFunction(module, id);
	Call_PushCell(resultNo);
	Call_PushCell(client);
	Call_PushString(isParamRandom1 ? selectedValue1 : param1);
	Call_PushString(isParamRandom2 ? selectedValue2 : param2);
	Call_PushString(isParamRandom3 ? selectedValue3 : param3);
	Call_PushString(isParamRandom4 ? selectedValue4 : param4);
	Call_PushString(isParamRandom5 ? selectedValue5 : param5);
	
	bool wasDiceSuccessfully;
	Call_Finish(wasDiceSuccessfully);
	
	return wasDiceSuccessfully;
}


static bool CanPlayerDiceInTeam(int client)
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

static bool CanPlayerDice(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) {
		CPrintToChat(client, "%s {red}%t", MD_PREFIX_COLORED, "dice_not_possible_when_dead");
		return false;
	}
	
	if(g_cannotDice) {
		CPrintToChat(client, "%s {red}%t", MD_PREFIX_COLORED, "dice_not_possible_in_this_game_phase");
		return false;
	}
	
	if(g_dices[client] >= g_allowedDices[client]) {
		CPrintToChat(client, "{lightgreen}%s %t", MD_PREFIX_COLORED, "all_dices_are_gone", g_allowedDices[client]);
		return false;
	}
	return true;
}

static void UpdateAllAllowedDices(int newAllowedDices)
{
	for (int i = 0; i < MAXPLAYERS; i++){
		g_allowedDices[i] = newAllowedDices;
	} 
}

static void ResetDiceCounters()
{
	for (int i = 0; i < MAXPLAYERS; i++){
		ResetDiceCounter(i);
	} 
}

static void ResetDiceCounter(int client)
{
		// Get the allowed amout of dices from the cvar
		char buffer[11];
		g_cvar_dicesPerRound.GetString(buffer, sizeof(buffer));
		int allowed = StringToInt(buffer);
		
		g_dices[client] = 0; // Reset current dices of the player
		g_allowedDices[client] = allowed; // Set new limit
}

static bool hasModules()
{
	return GetArraySize(g_modulesArray) > 0;
}

/*
 * Check if one of the both (playing) teams is empty
 * @return bool true, if one team is emoty
 */
static bool IsSingleTeamEmpty()
{
	return GetTeamClientCount(CS_TEAM_CT) == 0 || GetTeamClientCount(CS_TEAM_T) == 0;
}