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
	Diced(client); // This should be implemented by every module
	
	char text[255];
	GetDiceText(text);
	MDPublishDiceResult(client, text);
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
