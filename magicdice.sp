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
#define MD_PLUGIN_VERSION "${-version-}" // Version is replaced by the GitLab-Runner compile script
#define MD_PLUGIN_NAME "MagicDice - Modular Roll The Dice Plugin"
#define MD_PLUGIN_AUTHOR "Kevin 'RAYs3T' Urbainczyk"
#define MD_PLUGIN_DESCRIPTION "A Modular Roll The Dice Plugin. Supporting on the fly feature un/re-load"
#define MD_PLUGIN_WEBSITE "https://ptl-clan.de"

// Config cvars
#define CONF_CVAR_DICES_PER_ROUND 		"sm_md_dices_per_round"
static ConVar g_cvar_dicesPerRound;

#define CONF_CVAR_ALLOW_DICE_TEAM_T 	"sm_md_allow_dice_team_t"
static ConVar g_cvar_allowDiceTeamT;

#define CONF_CVAR_ALLOW_DICE_TEAM_CT 	"sm_md_allow_dice_team_ct"
static ConVar g_cvar_allowDiceTeamCT;



#define DEBUG true



public char MD_PREFIX[12] = "[MagicDice]";
public char MD_PREFIX_COLORED[64] = "{default}[{fuchsia}Magic{haunted}Dice{default}]";

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

static char g_results[256][MAX_MODULES][MAX_MODULE_FIELDS][MODULE_PARAMETER_SIZE]; // [result][modules][module_name|probability|params][param values]

static int g_probabillities[256];

static Handle g_modulesArray;



// How many times has an user rolled the dice?
static int g_dices[MAXPLAYERS + 1];
// How many times can an user roll the dice?
static int g_allowedDices[MAXPLAYERS + 1];

// A switch to block general dices while the game / round is ending
static bool g_cannotDice = true;

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
	RegConsoleCmd("md_reconfigure", OnReconfigureCommand, "Reloads and reconfigures the result configurations", ADMFLAG_CONFIG);
	
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	
	PrepareAndLoadConfig();
	
	g_cannotDice = false;
	PrintToServer("%s Plugin start", MD_PREFIX);
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
	CReplyToCommand(client, "{lightgreen}%s {default}({grey}%i{default}) {mediumvioletred}%s", MD_PREFIX_COLORED, dicedResultNumber, diceText);
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
		CReplyToCommand(client, "{lightgreen}%s {default}%t", MD_PREFIX_COLORED, "no_modules_registered");
		return Plugin_Continue;
	}
	
	if(!CanPlayerDiceInTeam(client)){
		CReplyToCommand(client, "{lightgreen}%s {orange}%t", MD_PREFIX_COLORED, "dice_not_allowed_for_your_team");
		return Plugin_Handled;
	}
	if(!CanPlayerDice(client)){
		CReplyToCommand(client, "{lightgreen}%s %t", 
			MD_PREFIX_COLORED, "all_dices_are_gone", g_allowedDices[client]);
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
		CReplyToCommand(client, "{lightgreen}%s %t", MD_PREFIX_COLORED, "missing_fixed_result_test_parameter");
		return Plugin_Handled;
	}
	char buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	int index = StringToInt(buffer);
	
	if(index > sizeof(g_probabillities) || g_probabillities[index] == 0){
		CReplyToCommand(client, "{lightgreen}%s %t", MD_PREFIX_COLORED, "not_found_fixed_result", index);
		return Plugin_Handled;
	}
	
	CReplyToCommand(client, "%s %t", MD_PREFIX_COLORED, "using_fixed_dice_result", index);
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

static bool LoadResults()
{	
	KeyValues kv = new KeyValues("Results");
	kv.ImportFromFile("cfg/magicdice/results.cfg");
	int resultCount = 0;

	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		return false;
	}
 	
	// Iterate over subsections at the same nesting level
	char buffer[255];
	do {
		kv.GetSectionName(buffer, sizeof(buffer));
	
		char probabilityValue[32];
		kv.GetString("prob", probabilityValue, sizeof(probabilityValue));
		
		int probability = kv.GetNum("prob");
		g_probabillities[resultCount] = probability;
		
		char team[32];
		kv.GetString("team", team, sizeof(team));
		 
		kv.GotoFirstSubKey(false);
		do {
			PrintToServer("%s Loading result: %s", MD_PREFIX, buffer);
			int moduleCount = 0;
			do {
				// TODO validate if the specified module is available (avoid typos etc.)
				char bufferFeature[MODULE_PARAMETER_SIZE];
				kv.GetSectionName(bufferFeature, sizeof(bufferFeature));
				char param1[MODULE_PARAMETER_SIZE];
				char param2[MODULE_PARAMETER_SIZE];
				char param3[MODULE_PARAMETER_SIZE];
				char param4[MODULE_PARAMETER_SIZE];
				char param5[MODULE_PARAMETER_SIZE];
				
				kv.GetString("param1", param1, sizeof(param1));
				kv.GetString("param2", param2, sizeof(param2));
				kv.GetString("param3", param3, sizeof(param3));
				kv.GetString("param4", param4, sizeof(param4));
				kv.GetString("param5", param5, sizeof(param5));
				
				char selectedValue1[MODULE_PARAMETER_SIZE];
				ParseRandomParameter(param1, selectedValue1);
				char selectedValue2[MODULE_PARAMETER_SIZE];
				ParseRandomParameter(param2, selectedValue2);
				char selectedValue3[MODULE_PARAMETER_SIZE];
				ParseRandomParameter(param3, selectedValue3);
				char selectedValue4[MODULE_PARAMETER_SIZE];
				ParseRandomParameter(param4, selectedValue4);
				char selectedValue5[MODULE_PARAMETER_SIZE];
				ParseRandomParameter(param5, selectedValue5);
				PrintToServer("Selected random1: %s", selectedValue1);
				PrintToServer("Selected random2: %s", selectedValue2);
				PrintToServer("Selected random3: %s", selectedValue3);
				PrintToServer("Selected random4: %s", selectedValue4);
				PrintToServer("Selected random5: %s", selectedValue5);
				
				g_results[resultCount][moduleCount][ModuleField_Probability] = probabilityValue;
				g_results[resultCount][moduleCount][ModuleField_ModuleName] = bufferFeature;
				g_results[resultCount][moduleCount][ModuleField_Team] = team;
				g_results[resultCount][moduleCount][ModuleField_Param1] = param1;
				g_results[resultCount][moduleCount][ModuleField_Param2] = param2;
				g_results[resultCount][moduleCount][ModuleField_Param3] = param3;
				g_results[resultCount][moduleCount][ModuleField_Param4] = param4;
				g_results[resultCount][moduleCount][ModuleField_Param5] = param5;
				
				moduleCount++;
#if defined DEBUG
					PrintToServer("%s\tModule[%s] probability[%i]", MD_PREFIX, bufferFeature, probability);
					if(strcmp(param1, "") != 0) PrintToServer("%s\t\tParam1: '%s'", MD_PREFIX, param1);
					if(strcmp(param2, "") != 0) PrintToServer("%s\t\tParam2: '%s'", MD_PREFIX, param2);
					if(strcmp(param3, "") != 0) PrintToServer("%s\t\tParam3: '%s'", MD_PREFIX, param3);
					if(strcmp(param4, "") != 0) PrintToServer("%s\t\tParam4: '%s'", MD_PREFIX, param4);
					if(strcmp(param5, "") != 0) PrintToServer("%s\t\tParam5: '%s'", MD_PREFIX, param5);
#endif
			} while (kv.GotoNextKey());
			resultCount++;
		} while (kv.GotoNextKey());
		kv.GoBack();
	} while (kv.GotoNextKey());
	delete kv;
	PrintToServer("%s Loaded %i results", MD_PREFIX, resultCount);
	return true;
}



// Picks and processes the result
static void PickResult(int client, int forcedResult = -1)
{
	int selectedIndex;
	if(forcedResult != -1)
	{
		selectedIndex = forcedResult;
	} else {
		// Now things getting complicated:
		// We store all results by index, but when it comes to team selection
		// this indexes are no loger valid for our probability selection.
		// So we need to remap them to get only the ones matching for the requested team
		// (othwewise we would mess up the probability selection)
		// At the end (when a result for a team is choosen), we need to get its original index again.
		
		int team = GetClientTeam(client);
		
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
	
	PrintToServer("Picked result %i", selectedIndex);
	for (int i = 0; i < MAX_MODULES; i++)
	{
		if(strcmp(g_results[selectedIndex][i][1], "") != 0)
		{
			Handle module = FindModuleByName(g_results[selectedIndex][i][ModuleField_ModuleName]);
			ProcessResult(module, selectedIndex, client, 
			g_results[selectedIndex][i][ModuleField_Param1], 
			g_results[selectedIndex][i][ModuleField_Param2], 
			g_results[selectedIndex][i][ModuleField_Param3], 
			g_results[selectedIndex][i][ModuleField_Param4], 
			g_results[selectedIndex][i][ModuleField_Param5]);
		} else {
			break; // No more modules to process for this result
		}
	}
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

/*
 * Returns all probabillities for results that matches the given team
 * @param team	The requested team for the probabillities
 * @retun bool false if no results for that team exist
 */
static bool GetTeamProbabillities(int teamResults[256][2], int team)
{
	bool foundResults = false;
	int newResultCount = 0;
	char resultTeamBuffer[MODULE_PARAMETER_SIZE];
	for (int i = 0; i < sizeof(g_results); i++)
	{
		if(strcmp(g_results[i][0][ModuleField_ModuleName], "") == 0)
		{
			// We reached the end of results.
			// There was no module name
			break;
		}
		
		resultTeamBuffer = g_results[i][0][ModuleField_Team];
		int resultTeam = StringToInt(resultTeamBuffer);
		if(strcmp(resultTeamBuffer, "") == 0 || resultTeam == team) // Empty (all teams) or matching the team
		{
			int prob = StringToInt(g_results[i][0][ModuleField_Probability]); // Since every module has the prob field we just use the first (0))

			teamResults[newResultCount][0] = i;
			teamResults[newResultCount][1] = prob;
			newResultCount++;
			foundResults = true;
		}		
	}
	return foundResults;
}

// Pickes a result depending on the probability
static int SelectByProbability(int modulePropabilities[256])
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

// Values: <|random:values ONE:6,TWO:3,THREE:1|>
// Float: <|random:float 5.0,15.0|>

static bool ParseRandomParameter(char[] parameter, char selectedValue[MODULE_PARAMETER_SIZE])
{
	Regex randomRegex = CompileRegex("^\\<\\|rnd:(int|float|val|pval)\\ (.*)\\|\\>$");
	RegexError error;
	int subStrings = randomRegex.Match(parameter, error);
	
	if(subStrings == -1)
	{
		// Parameter not matching the regex, just using as regular parameter
		PrintToServer("NOT MATCHING! %s", parameter);
		return false;
	}
	
	char typeBuffer[64];
	char valueBuffer[256];
	bool hasType = randomRegex.GetSubString(1, typeBuffer, sizeof(typeBuffer));
	bool hasValues = randomRegex.GetSubString(2, valueBuffer, sizeof(valueBuffer));
	
	if(!hasType || !hasValues)
	{	
		return false;
	}
	
	if(strcmp(typeBuffer, "pval") == 0)
	{
		ParseRandomValueList(valueBuffer, selectedValue, true);
		return true;
	}
	if(strcmp(typeBuffer, "val") == 0)
	{
		ParseRandomValueList(valueBuffer, selectedValue, false);
		return true;
	}
	else if (strcmp(typeBuffer, "int") == 0)
	{
		 IntToString(ParseRandomInt(valueBuffer), selectedValue, sizeof(selectedValue));
		 return true;
	}
	else if (strcmp(typeBuffer, "float") == 0)
	{
		FloatToString(ParseRandomFloat(valueBuffer), selectedValue, sizeof(selectedValue));
		return true;
	}

	// Nothing replaced
	return false;
}

/*
 * Parses a parameter and may replace random placeholer with real values
 * @param list The random string from the parameter
 * @param selectedValue The (by random) choosen  value
 * @param probSelect bool switch, true means we have to deal with a KEY:PROB list instead of 
 * a normal list (false)
 * @return bool true, if we replaced something, false if not
 */
static bool ParseRandomValueList(char[] list, char selectedValue[MODULE_PARAMETER_SIZE], bool probSelect = false)
{
	char map[10][2][MODULE_PARAMETER_SIZE];
	char parts[10][MODULE_PARAMETER_SIZE];
	
	int partCount = ExplodeString(list, ",", parts, 10, MODULE_PARAMETER_SIZE);
	int entries = 0;
	for (int i = 0; i < partCount; i++)
	{
		char entry[2][MODULE_PARAMETER_SIZE];
		ExplodeString(parts[i], ":", entry, 2, MODULE_PARAMETER_SIZE);
		map[i][0] = entry[0];
		map[i][1] = entry[1];
		entries++;
	}	
	
	if(!probSelect)
	{
		// We just need to return any entry, prob does not matter
		IntToString(GetRandomInt(0, entries), selectedValue, sizeof(selectedValue));
		return true;
	}
	
	int probMap[256];
	for (int i = 0; i < sizeof(map); i++)
	{
		probMap[i] = StringToInt(map[i][1]);
	}
	int selected = SelectByProbability(probMap);
	selectedValue = map[selected][0];
	return true;
}

/*
 * Simple int random selector
 * Parses: 1,5 (where 1 is min and 5 max, for example)
 * @param values the string containing the min,max values
 * @return int the (by random) choosen int
 */
static int ParseRandomInt(char values[256])
{
	// 5,15
	char buffer[2][11];
	if(ExplodeString(values, ",", buffer, 2, 11) != 2)
	{
		LogError("Unable to parse random int with values: %s", values);
		return 0;		
	}
	int min = StringToInt(buffer[0]);
	int max = StringToInt(buffer[1]);
	
	return GetRandomInt(min, max);
}

/*
 * Simple float random selector
 * Parses: 2.5,6.09 (where 2.5 is min and 6.09 max, for example)
 * @param values the string containing the min,max values
 * @return float the (by random) choosen float
 */
static float ParseRandomFloat(char values[256])
{
	char buffer[2][11];
	if(ExplodeString(values, ",", buffer, 2, 11) != 2)
	{
		LogError("Unable to parse random float with values: %s", values);
		return 0.0;		
	}
	float min = StringToFloat(buffer[0]);
	float max = StringToFloat(buffer[1]);
	
	PrintToServer("RANDOM MINMAX: %i, %i", min, max);
	return GetRandomFloat(min, max);
	
}