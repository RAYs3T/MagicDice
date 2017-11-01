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
 *
 * @param name    Full name
 */
native void MDRegisterModule(char[] name);

/**
 * Un-Register a module
 */
native void MDUnRegisterModule();

/**
 * Publishes the dice result text from the module
 *
 */
native void MDPublishDiceResult(int client, char[] diceText);

/**
 * Adds the specified amount of dices, so the user can roll x times more
 * @param diceAmount the additional amount of dices to add
 */
native void MDAddAllowedDices(int client, int diceAmount);


public bool MDEvaluateResult(int idx, int client, char[] param1, char[] param2, char[] param3, char[] param4, char[] param5){
	char diceText[255];
	Diced(client, diceText, param1, param2, param3, param4, param5); // This should be implemented by every module
	MDPublishDiceResult(client, diceText);
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
