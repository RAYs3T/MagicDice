
/* 
###################################################################################
# Copyright © 2017 Kevin Urbainczyk <kevin@rays3t.info> - All Rights Reserved     #
# Unauthorized copying of this file, via any medium is strictly prohibited.       #
# Proprietary and confidential.                                                   #
#                                                                                 #
# This file is part of the RefuseMgr-Plugin.                                      #
# Written by Kevin 'RAYs3T' Urbainczyk <kevin@rays3t.info>                        #
# Homepage: https://gitlab.com/PushTheLimits/Sourcemod/MagicDice                                                   #
###################################################################################
*/

/*
 * Adds additional refuses to a client
 * @param client the client
 * @param amount the amount of additional refuses
 */
native void RefuseAddAmount(int client, int amount);

public SharedPlugin __pl_refusemgr =
{
	name = "refusemgr",
	file = "refusemgr.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
