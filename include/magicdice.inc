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


public bool MDEvaluateResult(int idx, int client){
	char diceText[255];
	Diced(client, diceText); // This should be implemented by every module
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
