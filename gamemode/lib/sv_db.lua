-- Main interface library for SQL database.
bash.db = bash.db or {};

-- Include necessary DB credentials.
bash.util.includeFile("bash/gameomde/config/sv_db.lua");

-- Local function for query errors.
local function QueryErr(query, err)
    MsgErr("SQL query failed!\n" .. query .. '\n' .. err);
end

local color_sql = Color(0, 151, 151, 255);
local modules = {};

-- SQLite (local storage) module.
modules.sqlite = {

    query = function(_query, _callback)
        local data = sql.Query(_query);
        local err = sql.LastError();

        if data == false then
            QueryErr(_query, err);
            return;
        end

        if _callback then
            local lastID = tonumber(sql.QueryValue("SELECT last_insert_rowid();"));
            _callback(data, lastID);
        end
    end,

    escape = function(str)
        return sql.SQLStr(str, true);
    end,

    connect = function()
        MsgCon(color_sql, "Successfully connected to SQLite database!");
    end

};

-- tmysql4 (external storage) module.
modules.tmysql4 = {

    query = function(_query, _callback)
        if bash.db.object then
            bash.db.object:Query(_query, function(dataTab, status, lastID)
                if QUERY_SUCCESS and status == QUERY_SUCCESS then
                    if _callback then
                        _callback(dataTab, lastID);
                    end
                else
                    -- Try and handle multiple queries in one.
                    if dataTab then
                        for index, data in ipairs(dataTab) do
                            if data.status then
                                if _callback then
                                    _callback(data.data, data.lastid);
                                end

                                continue;
                            end

                            MsgErr("Query #%d in the following chain failed!", index);
                            MsgErr(_query);
                            MsgErr(data.error);
                        end
                    end
                end
            end);
        end
    end,

    escape = function(str)
        if bash.db.object then
            return bash.db.object:Escape(str);
        end

        return tmysql and tmysql.escape and tmysql.escale(str) or sql.SQLStr(str, true);
    end,

    connect = function(callback)
        if !pcall(require, "tmysql4") then
            --setNetVar dberror
        end

        local obj, err = tmysql.initialize(
            bash.db.hostname, bash.db.username,
            bash.db.password, bash.db.database,
            bash.db.port
        );

        if object then
            bash.db.object = obj;
            bash.db.escape = modules.tmysql4.escape;
            bash.db.query = modules.tmysql4.query;

            MsgCon(color_sql, "Successfully connected to tmysql4 server!");
        else
            MsgErr("Unable to connect to tmysql4 server!");
            MsgErr(err);
        end
    end

};

MYSQLOO_QUEUE = MYSQLOO_QUEUE or {};
-- MySQLOO (external storage) module.
modules.mysqloo = {

    query = function(_query, _callback)
        if bash.db.object then
            local obj = bash.db.object:query(_query);

            if _callback then
                function obj:onSuccess(data)
                    _callback(data, self:lastInsert());
                end
            end

            function obj:onError(err)
                if bash.db.object:status() == mysqloo.DATABASE_NOT_CONNECTED then
                    MYSQLOO_QUEUE[#MYSQLOO_QUEUE + 1] = {_query, _callback};
                    bash.db.connect();
                    return;
                end

                QueryErr(_query, err);
            end

            obj:start();
        end
    end,

    escape = function(str)
        if bash.db.object then
            return bash.db.object:escape(str);
        else
            sql.SQLStr(str, true);
        end
    end,

    connect = function()
        if !pcall(require, "mysqloo") then
            --setNetVar dberror
        end

        local obj = mysqloo.connect(
            bash.db.hostname, bash.db.username,
            bash.db.password, bash.db.database,
            bash.db.port
        );

        function obj:onConnected()
            bash.db.object = self;
            bash.db.escape = modules.mysqloo.escape;
            bash.db.query = modules.mysqloo.query;

            for index, waiting in ipairs(MYSQLOO_QUEUE) do
                bash.db.query(waiting[1], waiting[2]);
            end
            MYSQLOO_QUEUE = {};

            MsgCon(color_sql, "Successfully connected to MySQLOO server!");
        end

        function obj:onConnectedFailed(err)
            MsgErr("Failed to connect to MySQLOO server!");
            MsgErr(err);
        end

        obj:connect();

        timer.Create("bashMySQLWakeUp", 300, 0, function()
            bash.db.query("SELECT 1 + 1;");
        end);
    end

};

-- Set default values.
bash.db.escape = modules.sqlite.escape;
bash.db.query = modules.sqlite.query;

function bash.db.connect()
    local mod = modules[bash.db.module];
    if mod then
        if !bash.db.object then
            mod.connect();
        end

        bash.db.escape = mod.escape;
        bash.db.query = mod.query;
    else
        MsgErr("No SQL module of the name '%s' was found!", bash.db.module);
    end
end
