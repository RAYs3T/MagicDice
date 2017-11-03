/* 
#####################################################
# Push The Limits's MagicDice Roll The Dice Plugin' #
# Core include                                      #
# Created by Kevin 'RAYs3T' Urbainczyk              #
# Copyright (C) 2017 by Push The Limits             #
# Homepage: https://ptl-clan.de                     #
#####################################################
*/



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


public bool MDEvaluateResult(int idx, int client, char[] param1, char[] param2, char[] param3, char[] param4, char[] param5){
	char diceText[255];
	Diced(client, diceText, param1, param2, param3, param4, param5); // This should be implemented by every module
	MDPublishDiceResult(client, diceText, idx);
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
