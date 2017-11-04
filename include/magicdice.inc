/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Core include                                      #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/


/**
 * Should be called when the plugin is loaded
 * This will load translations and more
 */
void MDOnPluginStart()
{
	MDInitTranslations();
}

/**
 * Loads the translations based on the plugin file name
 */ 
void MDInitTranslations()
{
	// Get the name of the plugin for building the translations path
	char pluginName[32];
	GetPluginFilename(INVALID_HANDLE, pluginName, sizeof(pluginName));
	ReplaceString(pluginName, sizeof(pluginName), ".smx", "", false);
	
	char translations[sizeof(pluginName) + 16]; // Add some more space for the extension (.phrases)
	Format(translations, sizeof(translations), "%s.phrases", pluginName); // Should end up like: md_example.phrases (.txt is added by sourcemod)
	
	LogMessage("Loading translation for %s from %s", pluginName, translations);
	LoadTranslations(translations);
}

// TODO Add module groups?
/**
 * Register the module
 */
native void MDRegisterModule();

/**
 * Un-Register a module
 */
native void MDUnRegisterModule();

/**
 * Publishes the dice result text from the module
 *
 */
native void MDPublishDiceResult(int client, char[] diceText, int dicedResultNumber);

/**
 * Adds the specified amount of dices, so the user can roll x times more
 * @param diceAmount the additional amount of dices to add
 */
native void MDAddAllowedDices(int client, int diceAmount);

public void MDReportFailure(char[] text, any ...) {
	int len = strlen(text) + 255;
	char[] message = new char[len];
	VFormat(message, len, text, 2);
	LogError("%s", message);
}

/**
 * Complains about a missing / invalid parameter
 * @param paramPos The position of the parameter
 * @param paramDesc The name / description of the parameter
 * @param invalid The invalid value the parameter had
 */
public void MDReportInvalidParameter(int paramPos, char[] paramDesc, char[] invalid) {
	MDReportFailure("Parameter param%i (%s) has an invalid value (%s)", paramPos, paramDesc, invalid);
}

/**
 * Checks if the String is set
 * @param str The string
 * @return true, if not empty
 */
public bool MDIsStringSet(char[] str)
{
	return !(strcmp(str, "") == 0);
}

/**
 * Parses an integer parameter
 * @param param the parameter to parse
 * @return the parsed int, 0 if no param set or invalid.
 */
public int MDParseParamInt(char[] param)
{
	if(!MDIsStringSet(param)) {
		return 0;
	}
	return StringToInt(param);
}

/**
 * Parses an float parameter
 * @param param the parameter to parse
 * @return the parsed float, 0.0 if no param set or invalid.
 */
public float MDParseParamFloat(char[] param)
{
	if(!MDIsStringSet(param)) {
		return 0.0;
	}
	return StringToFloat(param);
}


public bool MDEvaluateResult(int idx, int client, char[] param1, char[] param2, char[] param3, char[] param4, char[] param5){
	char diceText[255];
	Diced(client, diceText, param1, param2, param3, param4, param5); // This should be implemented by every module
	MDPublishDiceResult(client, diceText, idx);
}


stock bool IsValidClient(int client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
    {
        return false; 
    }
    return IsClientInGame(client); 
}  


public SharedPlugin __pl_magicdice =
{
	name = "magicdice",
	file = "magicdice.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
