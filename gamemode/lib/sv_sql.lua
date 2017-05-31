-- SQL database interface.
bash.sql = bash.sql or {};
bash.sql.obj = bash.sql.obj or nil;
bash.sql.connected = bash.sql.connected or false;
bash.sql.tables = bash.sql.tables or {};

-- tmysql4 is the required SQL module.
if !tmysql then
    local status, mod = pcall(require, "tmysql4");
    if !status then
        MsgErr("No tmysql4 module found! Resolve this before continuing.");
    else
        MsgCon(color_sql, "tmysql4 module loaded.");
    end
end

-- Include neccessary sql credenials.
bash.util.includeFile("bash-base/gamemode/config/sv_sql.lua");

function bash.sql.addTable(tab)
    if !tab or !tab.Name then return; end
    if bash.sql.tables[tab.Name] then
        MsgErr("[bash.sql.addTable] -> A table with the name '%s' already exists!", tab.Name);
        return;
    end

    tab.Name = tab.Name;
    tab.Reference = tab.Reference or REF_NONE;
    tab.Struct = tab.Struct or {};
    tab.Struct["EntryNum"] = "INT(10) UNSIGNED NOT NULL AUTO_INCREMENT";
    if tab.Reference == REF_PLY then
        tab.Struct["SteamID"] = "TEXT NOT NULL";
    elseif tab.Reference == REF_CHAR then
        tab.Struct["SteamID"] = "TEXT NOT NULL";
        tab.Struct["CharID"] = "TEXT NOT NULL";
    end
    tab.Key = "EntryNum";

    bash.sql.tables[tab.Name] = tab;
    MsgDebug("SQL table registered with name '%s'.", tab.Name);
end

function bash.sql.addColumn(tabName, colName, col, override)
    if !tabName or !colName or !col then return; end
    if !bash.sql.tables[tabName] then
        MsgErr("[bash.sql.addColumn] -> No table with the name '%s' exists!", tabName);
        return;
    end

    if bash.sql.tables[tabName].Struct[colName] then
        if override then
            MsgDebug("Overriding column '%s' in table '%s'.", colName, tabName);
        else
            MsgErr("[bash.sql.addColumn] -> The column '%s' already exists in the table '%s'! To override this, provide the override argument to this function.", colName, tabName);
            return;
        end
    else
        MsgDebug("Adding column '%s' to table '%s'.", colName, tabName);
    end

    bash.sql.tables[tabName].Struct[colName] = col;
end

-- Local function to report query errors.
local function QueryErr(query, err)
    MsgErr("Query failed!\n" .. query .. '\n' .. err);
end

function bash.sql.query(query, callback, obj)
    if bash.sql.obj and bash.sql.connected then
        bash.sql.obj:Query(query, function(resultsTab)
            if #resultsTab == 1 then
                if !resultsTab[1].status then
                    QueryErr(query, resultsTab[1].error);
                    return;
                end
            else
                for index, results in ipairs(resultsTab) do
                    if !results.status then
                        MsgErr("Query #%d in the query string failed!", index);
                        MsgErr(results.error);
                    end
                end
            end

            local firstArg = obj or resultsTab;
            local secondArg = (firstArg != resultsTab and resultsTab) or nil;
            callback(firstArg, secondArg);
        end);
    end
end

function bash.sql.escape(str)
    if bash.sql.obj then
        return bash.sql.obj:Escape(str);
    end
    return (tmysql and tmysql.escape and tmysql.escape(str)) or sql.SQLStr(str, true);
end

-- Local function for checking existance of all registered columns.
local function columnCheck()
    local missing = {};
    for name, tab in pairs(bash.sql.tables) do
        missing[name] = {};
        for colName, col in pairs(tab.Struct) do
            missing[name][colName] = col;
        end
    end

    local query = Fmt("SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = \'%s\';", bash.sql.database);
    bash.sql.query(query, function(results)
        results = results[1];

        local tabName, colName;
        for _, result in pairs(results.data) do
            tabName = result["TABLE_NAME"];
            colName = result["COLUMN_NAME"];
            if missing[tabName] then
                missing[tabName][colName] = nil;
            end
        end
        tabName, colName = nil, nil;

        local _query = "";
        for name, tab in pairs(missing) do
            if table.IsEmpty(tab) then continue; end

            for colName, col in pairs(tab) do
                _query = _query .. Fmt(
                    "ALTER TABLE %s ADD %s %s %s; ", name, colName, col, (bash.sql.tables[name].Key == colName and "PRIMARY KEY" or "")
                );
            end
        end

        if _query != "" then
            bash.sql.query(_query, function(results)
                MsgDebug("Missing columns created in DB.");
                MsgCon(color_sql, "Database initialization complete!");
            end);
        else
            MsgDebug("No missing columns to be made in DB.");
            MsgCon(color_sql, "Database initialization complete!");
        end
    end);
end

-- Local function for checking existance of all registered tables.
local function tableCheck()
    local query = "";
    for name, tab in pairs(bash.sql.tables) do
        query = query .. Fmt("CREATE TABLE IF NOT EXISTS %s(", name);
        for colName, col in pairs(tab.Struct) do
            query = query .. Fmt("`%s` %s, ", colName, col);
        end
        query = query .. Fmt("PRIMARY KEY(`%s`)); ", tab.Key);
    end

    bash.sql.query(query, function(results)
        MsgDebug("Missing tables were checked in DB.");
        columnCheck();
    end);
end

function bash.sql.connect()
    -- Create default table structure first!
    bash.sql.addTable{
        Name = "bash_plys",
        Reference = REF_PLY,
        Struct = {
            ["Name"] = SQL_TYPE["string"]
        }
    };

    bash.sql.addTable{
        Name = "bash_chars",
        Reference = REF_CHAR,
        Struct = {}
    };

    bash.sql.addTable{
        Name = "bash_invs",
        Reference = REF_NONE,
        Struct = {}
    };

    bash.sql.addTable{
        Name = "bash_items",
        Reference = REF_NONE,
        Struct = {}
    };

    bash.sql.addTable{
        Name = "bash_bans",
        Reference = REF_NONE,
        Struct = {
            ["VictimName"] = SQL_TYPE["string"],
            ["VictimSteamID"] = SQL_TYPE["string"],
            ["BannerName"] = SQL_TYPE["string"],
            ["BannerSteamID"] = SQL_TYPE["string"],
            ["BanTime"] = SQL_TYPE["number"],
            ["BanLength"] = SQL_TYPE["number"],
            ["BanReason"] = SQL_TYPE["string"]
        }
    };

    -- Gather all external structures too!
    hook.Call("AddSQLTables");
    hook.Call("EditSQLTables");

    -- Gather all external registry variables so we can add them to the table
    -- structures!
    hook.Call("AddRegistryVariables");

    -- Now that we have all the info of our DB, we connect.
    local obj, err = tmysql.initialize(
        bash.sql.hostname, bash.sql.username,
        bash.sql.password, bash.sql.database,
        bash.sql.port
    );

    if obj then
        bash.sql.obj = obj;
        bash.sql.connected = true;
        MsgCon(color_sql, "Successfully connected to MySQL server!");
        tableCheck();
    else
        MsgErr("Unable to connect to MySQL server!");
        MsgErr(err);
        return;
    end
end

function bash.sql.tableCleanup()
    if !bash.sql.connected then return; end


end

function bash.sql.columnCleanup()
    if !bash.sql.connected then return; end


end
