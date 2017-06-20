-- SQL database interface.
bash.sql = bash.sql or {};
bash.sql.obj = bash.sql.obj or nil;
bash.sql.connected = bash.sql.connected or false;
bash.sql.tables = bash.sql.tables or {};
bash.sql.charstats = bash.sql.charstats or {};
local color_sql = Color(0, 151, 151, 255);

-- tmysql4 is the required SQL module.
if !tmysql then
    local status, mod = pcall(require, "tmysql4");
    if !status then
        MsgErr("No tmysql4 module found! Resolve this before continuing.");
    else
        MsgCon(color_sql, "tmysql4 module loaded.");
    end
end

function bash.sql.addTable(tab)
    if !tab or !tab.Name then return; end
    if bash.sql.tables[tab.Name] then
        MsgErr("[bash.sql.addTable] -> A table with the name '%s' already exists!", tab.Name);
        return;
    end

    tab.Name = tab.Name;
    tab.Reference = tab.Reference or REF_NONE;
    tab.Columns = tab.Columns or {};
    tab.Columns["EntryNum"] = "INT(10) UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE";
    if tab.Reference == REF_PLY then
        tab.Columns["SteamID"] = "TEXT NOT NULL";
    elseif tab.Reference == REF_CHAR then
        tab.Columns["SteamID"] = "TEXT NOT NULL";
        tab.Columns["CharID"] = "TEXT NOT NULL";
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

    if bash.sql.tables[tabName].Columns[colName] then
        if override then
            MsgDebug("Overriding column '%s' in table '%s'.", colName, tabName);
        else
            MsgErr("[bash.sql.addColumn] -> The column '%s' already exists in the table '%s'! To override this, provide the override argument to this function.", colName, tabName);
            return;
        end
    else
        MsgDebug("Adding column '%s' to table '%s'.", colName, tabName);
    end

    bash.sql.tables[tabName].Columns[colName] = col;
end

-- Local function for dropping the table structures (on refresh).
local function dropTables()
    if table.IsEmpty(bash.sql.tables) then return; end
    MsgDebug("Dropping SQL table structures...");
    bash.sql.tables = {};
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
        for colName, col in pairs(tab.Columns) do
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
                    "ALTER TABLE %s ADD %s %s%s; ", name, colName, col, (bash.sql.tables[name].Key == colName and " PRIMARY KEY" or "")
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
        for colName, col in pairs(tab.Columns) do
            query = query .. Fmt("`%s` %s, ", colName, col);
        end
        query = query .. Fmt("PRIMARY KEY(%s)); ", tab.Key);
    end

    bash.sql.query(query, function(results)
        MsgDebug("Missing tables were checked in DB.");
        columnCheck();
    end);
end

function bash.sql.connect()
	-- First, we check to see if we can connect to the database.
    local obj, err = tmysql.initialize(
        bash.sql.hostname, bash.sql.username,
        bash.sql.password, bash.sql.database,
        bash.sql.port, nil, CLIENT_MULTI_STATEMENTS
    );

    if obj then
        bash.sql.obj = obj;
        bash.sql.connected = true;
        MsgCon(color_sql, "Successfully connected to MySQL server!");
    else
        MsgErr("Unable to connect to MySQL server!");
        MsgErr(err);
        return;
    end

    -- Create default table structure!
    bash.sql.addTable{
        Name = "bash_plys",
        Reference = REF_PLY,
        Columns = {
            ["Name"] = SQL_TYPE["string"]
        }
    };

    bash.sql.addTable{
        Name = "bash_chars",
        Reference = REF_CHAR,
        Columns = {}
    };

    bash.sql.addTable{
        Name = "bash_invs",
        Reference = REF_NONE,
        Columns = {}
    };

    bash.sql.addTable{
        Name = "bash_items",
        Reference = REF_NONE,
        Columns = {}
    };

    bash.sql.addTable{
        Name = "bash_bans",
        Reference = REF_NONE,
        Columns = {
            ["VictimName"] = SQL_TYPE["string"],
            ["VictimID"] = SQL_TYPE["string"],
            ["BannerName"] = SQL_TYPE["string"],
            ["BannerSteamID"] = SQL_TYPE["string"],
            ["BanTime"] = SQL_TYPE["number"],
            ["BanLength"] = SQL_TYPE["number"],
            ["BanReason"] = SQL_TYPE["string"]
        }
    };

	-- Gather all external structures!
    hook.Call("AddSQLTables");
    hook.Call("EditSQLTables");

	-- Finally, check the database structure.
	tableCheck();
end

function bash.sql.disconnect()
    if !bash.sql.connected or !bash.sql.obj then return; end

    MsgCon(color_sql, "Disconnecting from database!");
    bash.sql.obj:Disconnect();
end

function bash.sql.tableCleanup()
    if !bash.sql.connected then return; end

    -- finish later
end

function bash.sql.columnCleanup()
    if !bash.sql.connected then return; end

    -- finish later
end

function bash.sql.playerInit(ply)
    if !bash.sql.connected then return; end
    if !checkply(ply) then return; end

    bash.util.sendLoadProgress(ply, "Starting up...");
	hook.Call("PreSQLData", nil, ply);

    local id = ply:EntIndex();
    bash.reg.queue = bash.reg.queue or Queue:Create();
    local peek = bash.reg.queue:First();
    if !peek then
        bash.reg.queue:Enqueue(id);

        local update = vnet.CreatePacket("reg_queued");
        update:Table({[id] = 1});
        update:AddTargets(ply);
        update:Send();
    elseif peek and peek != id then
        bash.reg.queue:Enqueue(id);
        return;
    end

    local _ply = ply;
    local name, steamID = ply:Name(), ply:SteamID();
    local query = Fmt("SELECT * FROM bash_plys WHERE SteamID = \'%s\';", steamID);
    bash.sql.query(query, function(results)
        results = results[1];
        if table.IsEmpty(results.data) then
            MsgDebug("No row found for player '%s', creating a new one...", name);
            bash.sql.createPlyData(_ply);
        else
            MsgDebug("Row found for player '%s'.", name);
            _ply.SQLData = _ply.SQLData or {};
            _ply.SQLData["bash_plys"] = results.data[1];

            hook.Call("PostPlyData", nil, _ply);
            bash.sql.getCharData(_ply);
        end
    end);
end

function bash.sql.createPlyData(ply)
    if !bash.sql.connected then return; end
    if !checkply(ply) then return; end

    bash.util.sendLoadProgress(ply, "Creating your own row...");

    local name, steamID = ply:Name(), ply:SteamID();
    local vars = {};
    local vals = {};
    local val;
    for key, var in pairs(bash.reg.vars) do
        if var.SourceTable == "bash_plys" then
            vars[#vars + 1] = key;
            val = var:OnGenerateSV(ply, var.Default);
            if var.Type == "table" then
                vals[#vals + 1] = pon.encode(val)
            else
                vals[#vals + 1] = val;
            end
        end
    end

    local query = "INSERT INTO bash_plys(Name, SteamID";
    for index, var in ipairs(vars) do
        query = query .. ", " .. var;
    end
    query = query .. Fmt(") VALUES(\'%s\', \'%s\'", bash.sql.escape(name), steamID);
    for index, val in ipairs(vals) do
        if type(val) == "string" then
            query = query .. Fmt(", \'%s\'", bash.sql.escape(val));
        else
            query = query .. ", " .. tostring(val);
        end
    end
    query = query .. ");";

    hook.Call("CreatePlyData", nil, ply);

    local _ply = ply;
    bash.sql.query(query, function(results)
        _ply.SQLData = _ply.SQLData or {};
        _ply.SQLData["bash_plys"] = _ply.SQLData["bash_plys"] or {};
        for index = 1, #vars do
            _ply.SQLData["bash_plys"][vars[index]] = vals[index];
        end

        hook.Call("PostPlyData", nil, _ply);
        bash.sql.getCharData(_ply);
    end);
end

function bash.sql.getCharData(ply)
    if !bash.sql.connected then return; end
    if !checkply(ply) then return; end

    bash.util.sendLoadProgress(ply, "Gathering existing data...");

    local name, steamID = ply:Name(), ply:SteamID();
    MsgDebug("Gathering existing data for %s (%s)...", name, steamID);
    local query = Fmt("SELECT * FROM bash_chars WHERE SteamID = \'%s\';", steamID);
    local _ply = ply;
    bash.sql.query(query, function(results)
        results = results[1];
        local chars = {};
        for index, char in ipairs(results.data) do
            chars[#chars + 1] = char;
        end

        _ply.SQLData["bash_chars"] = chars;
        hook.Call("GetCharData", nil, _ply);
        _ply:Register();
    end);
end

-- Player metatable.
local Player = FindMetaTable("Player");
function Player:GetSQLData(table, index, field)
    if !table or !bash.sql.tables[table] then return; end
    self.SQLData = self.SQLData or {};

    if !field then
        if !index then -- Asking for an entire table.
            return self.SQLData[table];
        else -- 'index' is really a field.
            return (self.SQLData[table] != nil and self.SQLData[table][index]) or nil;
        end
    else
        return (self.SQLData[table] != nil and self.SQLData[table][index] and self.SQLData[table][index][field]) or nil;
    end
end

do -- For server refreshes.
	dropTables();
	bash.sql.disconnect();
end
