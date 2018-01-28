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
# File Description: All types of interaction with the database should be place    #
#                   in this file. This file is loaded by the core magicdice.sp    #
#                   in the parent folder.                                         #
###################################################################################
*/

#define MD_DB_PREFIX "[MagicDice DB]"

static Handle m_dbConnectTimer = null;
// Indicator if there is currenly any connection attemp running
static bool m_isConnecting = false;
static Database m_db;

/*
 * Logs a message 
 * @param text the format/message
 * @param debugOnly true, if the message should only be displayed in the debug mode
 * @param any format parameter
 */
static void LogDBMessage(const char[] text, bool debugOnly = false, any ...)
{
	if(debugOnly) // Message should only be displayed, when the debug mode is enabled
	{
		#if !defined DEBUG
			return;
		#endif
	}
	
	int len = strlen(text) + 255;
	char[] message = new char[len];
	VFormat(message, len, text, 3);
	LogMessage("%s %s", MD_DB_PREFIX, message);
}

public void InitializeDatabase()
{
	if(m_isConnecting)
	{
		LogError("%s A Database connection attemp is already running ...", MD_DB_PREFIX);
	}
	if(m_dbConnectTimer == null)
	{
		m_dbConnectTimer = CreateTimer(8.0, Timer_CheckDB, _, TIMER_REPEAT);
	}
	m_isConnecting = true;
	LogDBMessage("Connecting to the database ...");
	Database.Connect(OnDatabaseConnected, "magicdice");
	
}

public void OnDatabaseConnected(Database db, const char[] error, any data)
{
	if(db == null)
	{
		// Connection failed
		LogError("%s %s Unable to connect to the database: %s", MD_PREFIX, MD_DB_PREFIX, error);
		m_db = null;
		return;
	}
	
	// Set UTF-8 character set
	db.SetCharset("UTF-8");
	
	
	// Set this as new database handle
	m_db = db;
	LogDBMessage("Database connection succeded!");
}

public Action Timer_CheckDB(Handle timer, Handle data)
{
	if(m_db == null && !m_isConnecting)
	{
		LogError("%s The database connection died. Reconnecting ...", MD_DB_PREFIX);
		if(m_dbConnectTimer != null)
		{
			KillTimer(m_dbConnectTimer);
			m_dbConnectTimer = null;
		}		
		InitializeDatabase();
	}
}

static void LogQueryFailure(const char[] error)
{
	LogError("%s %s Unable to execute transaction: %s", MD_PREFIX, MD_DB_PREFIX, error);
}

static void AddQuotesAndEscape(char[] param, char[] buffer)
{
	
	m_db.Escape(param, buffer, MODULE_PARAMETER_SIZE + 16);
	Format(buffer, MODULE_PARAMETER_SIZE + 16, "'%s'", buffer);
}

static void AddQuotesOrSetNull(char param[MODULE_PARAMETER_SIZE], char buffer[MODULE_PARAMETER_SIZE + 16])
{
	if(strcmp(param, "") == 0)
	{
		buffer = "NULL";
	} else {
		AddQuotesAndEscape(param, buffer);
	}
}

/*
 * ####################
 * # DATABASE QUERIES #
 * ####################
 */
 
void QLogResult(int serverId, int resultId, const char[] steamId, int userTeam, char moduleNames[MAX_MODULES][MODULE_PARAMETER_SIZE], 
	char moduleParams[MAX_MODULES][MAX_MODULE_FIELDS][MODULE_PARAMETER_SIZE], int moduleCount)
{
	LogDBMessage("Preparing result log transaction ...", true);
	Transaction txn = new Transaction();
	
	//
	// Insert ResultPick
	//
	char cleanSteamId[36];
	m_db.Escape(steamId, cleanSteamId, sizeof(cleanSteamId));
	
	char qInsertResultPick[2048];
	Format(qInsertResultPick, sizeof(qInsertResultPick), "INSERT INTO md_result_picks (server_id, result_id, user_steam_id, user_team) VALUES('%i', '%i', '%s', '%i')",
	serverId, resultId, cleanSteamId, userTeam);
	LogDBMessage("[qInsertResultPick]: %s", true, qInsertResultPick);
	txn.AddQuery(qInsertResultPick);
	
	//
	// A query that sets a mysql variable containing the result id that we need for inserting the modules calls
	//
	txn.AddQuery("SET @result_id = LAST_INSERT_ID()");
	
	//
	// Insert result modules
	//
	char moduleName[64];
	for (int i = 0; i < moduleCount; i++)
	{
		m_db.Escape(moduleNames[i], moduleName, sizeof(moduleName));
		
		// Some extra chars for escape characters
		char p1[MODULE_PARAMETER_SIZE + 16];
		char p2[MODULE_PARAMETER_SIZE + 16];
		char p3[MODULE_PARAMETER_SIZE + 16];
		char p4[MODULE_PARAMETER_SIZE + 16];
		char p5[MODULE_PARAMETER_SIZE + 16];
		
		// Insert null if string is empty, escape otherwise

		AddQuotesOrSetNull(moduleParams[i][0], p1);
		AddQuotesOrSetNull(moduleParams[i][1], p2);
		AddQuotesOrSetNull(moduleParams[i][2], p3);
		AddQuotesOrSetNull(moduleParams[i][3], p4);
		AddQuotesOrSetNull(moduleParams[i][4], p5);
		
		char qInsertModule[2048];
		Format(qInsertModule, sizeof(qInsertModule), 
		"INSERT INTO md_result_module_call_log(result_pick_id, module_name, parameter_1, parameter_2, parameter_3, parameter_4, parameter_5)\
		VALUES (@result_id, '%s', %s, %s, %s, %s, %s)", // Quotes added by function
		moduleName, p1, p2, p3, p4, p5);
		
		LogDBMessage("[qInsertModule]: %s", true, qInsertModule);
		txn.AddQuery(qInsertModule);
	}
	// Fire the query
	LogDBMessage("Executing result log transaction ...", true);
	m_db.Execute(txn, Callback_QLogResult, Callback_QLogResultFailure, _, DBPrio_Low);
}

public void Callback_QLogResultFailure(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogQueryFailure(error);
}

public void Callback_QLogResult(Database db, any data, int numQueries, Handle[] results, any[] queryData)
{
	LogDBMessage("Query execution succeded! Queries executed: %i", true, numQueries);
}