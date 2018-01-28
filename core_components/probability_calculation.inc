/* 
###################################################################################
# This file is part of MagicDice.                                                 #
# Copyright (C) 2018 Kevin 'RAYs3T' Urbainczyk                                    #
#                                                                                 #
# MagicDice is free software: you can redistribute it and/or modify               #
# it under the terms of the GNU General Public License as published by            #
# the Free Software Foundation, either version 3 of the License, or               #
# (at your option) any later version.                                             #
#                                                                                 #
# MagicDice is distributed in the hope that it will be useful,                    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                  #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                   #
# GNU General Public License for more details.                                    #
#                                                                                 #
# You should have received a copy of the GNU General Public License               #
# along with MagicDice. If not, see <http://www.gnu.org/licenses/>.               #
#                                                                                 #
# MagicDice Website: https://gitlab.com/PushTheLimits/Sourcemod/MagicDice         #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# File Description: File for probability calculations                             #
###################################################################################
*/

/*
 * Returns all probabillities for results that matches the given team
 * @param team	The requested team for the probabillities
 * @retun bool false if no results for that team exist
 */
stock bool GetTeamProbabillities(int teamResults[256][2], int team)
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

/*
 * Selects a result (index) depending on its probability.
 * @param moduleProbabilities int[] of the probabilities to choose from, 
 * where the key is the index that is returned.
 */
stock int SelectByProbability(int modulePropabilities[256])
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