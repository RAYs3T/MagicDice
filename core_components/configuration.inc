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
# File Description: All types of configurations that are read/written from/to     #
#                   files should be in that file                                  #
###################################################################################
*/


bool LoadResults()
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
		
		if(probability == 0)
		{
			SetFailState("Unable to load a dice result without probability in range (1-100)");
		}
		
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
				
				kv.GotoFirstSubKey(false);
				do {
					char levelBuffer[MODULE_PARAMETER_SIZE];
					char param1[MODULE_PARAMETER_SIZE];
					char param2[MODULE_PARAMETER_SIZE];
					char param3[MODULE_PARAMETER_SIZE];
					char param4[MODULE_PARAMETER_SIZE];
					char param5[MODULE_PARAMETER_SIZE];
					
					kv.GetString("level", levelBuffer, sizeof(levelBuffer));
					kv.GetString("param1", param1, sizeof(param1));
					kv.GetString("param2", param2, sizeof(param2));
					kv.GetString("param3", param3, sizeof(param3));
					kv.GetString("param4", param4, sizeof(param4));
					kv.GetString("param5", param5, sizeof(param5));
					
					int level = StringToInt(levelBuffer);
					if(!IsValidLevel(level, resultCount, bufferFeature))
					{
						SetFailState("Unable to load module with incorrect level config. See error logs before for more details");
					}
					
					g_results[resultCount][moduleCount][ModuleField_Probability] = probabilityValue;
					g_results[resultCount][moduleCount][ModuleField_ModuleName] = bufferFeature;
					g_results[resultCount][moduleCount][ModuleField_Team] = team;
					
					// TODO create function for this
					char b_p1[MODULE_PARAMETER_SIZE];
					int i_p1 = GetMatchingParameterValue(resultCount, moduleCount, level, 0, b_p1);
					g_results[resultCount][moduleCount][i_p1] = b_p1;
					 
					//g_results[resultCount][moduleCount][ModuleField_Param1] = param1;
					//g_results[resultCount][moduleCount][ModuleField_Param2] = param2;
					//g_results[resultCount][moduleCount][ModuleField_Param3] = param3;
					//g_results[resultCount][moduleCount][ModuleField_Param4] = param4;
					//g_results[resultCount][moduleCount][ModuleField_Param5] = param5;
					
					
					#if defined DEBUG
						PrintToServer("%s\tModule[%s] probability[%i]", MD_PREFIX, bufferFeature, probability);
						if(strcmp(param1, "") != 0) PrintToServer("%s\t\tParam1: '%s'", MD_PREFIX, param1);
						if(strcmp(param2, "") != 0) PrintToServer("%s\t\tParam2: '%s'", MD_PREFIX, param2);
						if(strcmp(param3, "") != 0) PrintToServer("%s\t\tParam3: '%s'", MD_PREFIX, param3);
						if(strcmp(param4, "") != 0) PrintToServer("%s\t\tParam4: '%s'", MD_PREFIX, param4);
						if(strcmp(param5, "") != 0) PrintToServer("%s\t\tParam5: '%s'", MD_PREFIX, param5);
					#endif
				} while (kv.GotoNextKey());
				kv.GoBack();
				moduleCount++;
			} while (kv.GotoNextKey());
			resultCount++;
		} while (kv.GotoNextKey());
		kv.GoBack();
	} while (kv.GotoNextKey());
	delete kv;
	PrintToServer("%s Loaded %i results", MD_PREFIX, resultCount);
	return true;
}

static bool IsValidLevel(int level, int resultId, char featureName[MODULE_PARAMETER_SIZE])
{
	if(level == 0)
	{
		LogError("%s Unable to load level for module %s in result: %i. Is the level string missing / invalid?", MD_PREFIX, featureName, resultId);
		return false;
	}
	if(level < 0 || level > MAX_MODULE_LEVELS)
	{
		LogError("%s The provided level (%i) for module: %s in result: %i is out of range. Max level is %i", MD_PREFIX, level, featureName, resultId, MAX_MODULE_LEVELS);
		return false;
	}
	return true;
}