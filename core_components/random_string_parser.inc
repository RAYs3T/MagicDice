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
# File Description: This file hold all methods for parsing random parameters.     #
###################################################################################
*/

/*
 We wanted a way to give a module a random parameter in the configuration.
 So we just created this little parser class. It can prase a string and generate
 random values for:
 Int: <|random:float 5.0,15.0|>
 Float: <|random:float 5.0,15.0|>
 Values: <|random:values ONE,TWO,THREE|>
 Values with probabillity respected: <|random:values ONE:6,TWO:3,THREE:1|>
*/

/*
 * Prases a random paremeter and selects a random value.
 * @param parameter the value to parse.
 * @param selectedValue the buffer to store the selected value in.
 * @return bool true, if the random parameter was parsed successfully, false if not.
 */
bool ParseRandomParameter(char[] parameter, char selectedValue[MODULE_PARAMETER_SIZE])
{
	Regex randomRegex = CompileRegex("^\\<\\|rnd:(int|float|val|pval)\\ (.*)\\|\\>$");
	RegexError error;
	int subStrings = randomRegex.Match(parameter, error);
	
	if(subStrings == -1)
	{
		// Parameter not matching the regex, just using as regular parameter
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
		if(!probSelect)
		{
			map[i][0] = parts[i];
		} else {
			ExplodeString(parts[i], ":", entry, 2, MODULE_PARAMETER_SIZE);
			map[i][0] = entry[0];
			map[i][1] = entry[1];
		}
		entries++;
	}	
	
	if(!probSelect)
	{
		// We just need to return any entry, prob does not matter
		selectedValue = map[GetRandomInt(0, entries -1)][0];
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
	
	return GetRandomFloat(min, max);
}