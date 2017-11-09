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
# File Description: All types of interaction with the database should be place    #
#                   in this file. This file is loaded by the core magicdice.sp    #
#                   in the parent folder.                                         #
###################################################################################
*/

#define MD_DB_PREFIX "[DB]"
#define MD_DB_TABLE_PREFIX "md_"

// Indicator if there is currenly any connection attemp running
static bool m_isConnecting = false;
static Database m_db;

// Queries
DBStatement m_qInsertResultPick;

public void InitializeDatabase()
{
	m_isConnecting = true;
	Database.Connect(OnDatabaseConnected, "magicdice");
}

public void OnDatabaseConnected(Database db, const char[] error, any data)
{
	if(db == INVALID_HANDLE)
	{
		// Connection failed
		LogError("%s %s Unable to connect to the database: %s", MD_PREFIX, MD_DB_PREFIX, error);
		m_db = INVALID_HANDLE;
		return;
	}
	
	// Set UTF-8 character set
	db.SetCharset("UTF-8");
	
	
	// Set this as new database handle
	m_db = db;
	
	// TODO REMOVE
	char moduleNames[MAX_MODULES][MODULE_PARAMETER_SIZE];
	QLogResult(1, 2, "test", 0, moduleNames, moduleNames, 0); 
}

/*
 * Added the table prefix by replacing all __prefix__ strings with the actual prefix for tables.
 */
static void AddTablePrefix(char query[2048])
{
	if(ReplaceString(query, sizeof(query), "__prefix__", MD_DB_TABLE_PREFIX) < 1)
	{
		// Fail when no names has been replaced
		ThrowError("%s %s no table names (__prefix__) to replace in query: %s", MD_PREFIX, MD_DB_PREFIX, query);
	}
}

static void LogQueryFailure(const char[] error)
{
	LogError("%s %s Unable to execute transaction: %s", MD_PREFIX, MD_DB_PREFIX, error);
}

static void AddQuotesAndEscape(char[] param, char[] buffer)
{
	char dirtyBuffer[MODULE_PARAMETER_SIZE + 16];
	Format(dirtyBuffer, MODULE_PARAMETER_SIZE + 16, "'%s'", param);
	m_db.Escape(dirtyBuffer, buffer, MODULE_PARAMETER_SIZE + 16);
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
 
void QLogResult(int serverId, int resultId, const char steamId[20], int userTeam, char moduleNames[MAX_MODULES][MODULE_PARAMETER_SIZE], 
	char moduleParams[MAX_MODULES][MODULE_PARAMETER_SIZE], int moduleCount)
{
	Transaction txn = new Transaction();
	
	//
	// Insert ResultPick
	//
	char cleanSteamId[sizeof(steamId)+2];
	m_db.Escape(steamId, cleanSteamId, sizeof(cleanSteamId));
	
	char qInsertResultPick[2048];
	Format(qInsertResultPick, sizeof(qInsertResultPick), "INSERT INTO __prefix__result_picks (server_id, result_id, user_steam_id, user_team) VALUES('%i', '%i', '%s', '%i')",
	serverId, resultId, cleanSteamId, userTeam);
	AddTablePrefix(qInsertResultPick);
	#if defined DEBUG
	PrintToServer("Query: %s", qInsertResultPick);
	#endif
	
	txn.AddQuery(qInsertResultPick);
	
	//
	// A query that sets a mysql variable containing the result id that we need for inserting the modules calls
	//
	char[] qDefineResultId = "SET @result_id = LAST_INSERT_ID()";
	txn.AddQuery(qDefineResultId);
	
	//
	// Insert result module ca
	//
	char moduleQuery[2048];
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
	}
	// Fire the query
	m_db.Execute(txn, Callback_QLogResult, Callback_QLogResultFailure, _, DBPrio_Low);
}

public void Callback_QLogResultFailure(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogQueryFailure(error);
}

public void Callback_QLogResult(Database db, any data, int numQueries, Handle[] results, any[] queryData)
{
	
}