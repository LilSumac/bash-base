-- Main data structure for handling networked variables.
bash.reg = bash.reg or {};
bash.reg.vars = bash.reg.vars or {};
bash.reg.entries = bash.reg.entries or {};
bash.reg.entries.globals = bash.reg.entries.globals or {};
bash.reg.queue = bash.reg.queue or Queue:Create();
bash.reg.queuePlace = bash.reg.queuePlace or 0;
bash.reg.progress = bash.reg.progress or "Loading...";
bash.reg.lastFinish = bash.reg.lastFinish or nil;

function bash.reg.addVar(varTab)
    if !varTab or !varTab.ID then return; end
    if bash.reg.vars[varTab.ID] then
        MsgErr("[bash.reg.addVar] -> A variable with the ID '%s' already exists.", varTab.ID);
        return;
    end

    varTab.ID = varTab.ID;
    varTab.Type = varTab.Type or "string";
    varTab.Default = varTab.Default or "";
    varTab.GetDefault = varTab.GetDefault or function(self) return self.Default; end
    varTab.IsPublic = varTab.IsPublic or false;
    varTab.IsGlobal = varTab.IsGlobal or false;
    varTab.Source = varTab.Source or SRC_MAN;
    varTab.SourceTable = (varTab.Source == SRC_SQL and (varTab.SourceTable or "bash_plys")) or nil;
    varTab.Query = (varTab.Source == SRC_SQL and (varTab.Query or SQL_TYPE[varTab.Type])) or nil;
    varTab.SourceKey = (varTab.Source == SRC_CACHE and varTab.SourceKey) or nil;
    varTab.IsMapSpecific = (varTab.Source == SRC_CACHE and (varTab.IsMapSpecific or false)) or nil;
    varTab.IgnoreSchema = (varTab.Source == SRC_CACHE and (varTab.IgnoreSchema or false)) or nil;

    bash.reg.vars[varTab.ID] = varTab;
end

-- Local function for dropping the variable structures (on refresh).
local function dropVars()
    if bash.reg.vars == {} then return; end
    MsgDebug("Dropping variable structures from registry...");
    bash.reg.vars = {};
end

-- Metatables.
local Entity = FindMetaTable("Entity");
local Player = FindMetaTable("Player");

function getGlobal(key)
    local var = bash.reg.vars[key];
    if !var or !var.IsGlobal then return; end
    return bash.reg.entries.globals[key] or var:GetDefault();
end

function Entity:GetNetVar(key)
    local var = bash.reg.vars[key];
    if var and var.IsGlobal then return; end
    if !bash.reg.entries[self:EntIndex()] then
        MsgErr("[Entity.GetNetVar] -> This entity is not in the registry! (%s)", tostring(self));
        return;
    end
    return bash.reg.entries[self:EntIndex()][key] or (var and var:GetDefault(self));
end

function Player:Registered()
    return checkply(self) and (bash.reg.entries[self:EntIndex()] != nil);
end

if SERVER then
    -- Networked strings.
    util.AddNetworkString("reg_progress");
    util.AddNetworkString("reg_queued");
    util.AddNetworkString("reg_update");
    util.AddNetworkString("reg_delete");

    -- Check to see if there's an attempt to send a function.
    local function checkBadType(key, value)
        local valType = type(val);
        if valType == "function" then
            MsgErr("Networked var '%s' contains a bad (function) object type!", key);
            return true;
        elseif valType == "table" then
            for k, v in pairs(value) do
                if checkBadType(key, k) or checkBadType(key, v) then
                    return true;
                end
            end
        end
    end

    function bash.reg.loadGlobals()
        local update = vnet.CreatePacket("reg_update");

        local send = {};
        send.globals = {};
        for key, var in pairs(bash.reg.vars) do
            if !var.IsGlobal then continue; end
            local val = bash.cache.get(var.SourceKey or key, var:GetDefault(), var.IgnoreSchema, var.IsMapSpecific, true);
            bash.entries.globals[key] = val;
            send.globals[key] = val;
        end

        update:Table(send);
        update:Broadcast();
    end

    function bash.reg.sendProgress(ply, msg)
        local progress = vnet.CreatePacket("reg_progress");
        progress:String(msg);
        progress:AddTargets(ply);
        progress:Send();
    end

    --[[ To avoid server overload, values will just be updated on the fly.
    function bash.reg.save()
        local count = table.Count(bash.reg.entries);
        MsgDebug("Saving registry entries (%d)...", count);

        local delay = 0.05;
        local ply, steamID, queries, var, query, condition;
        for id, entries in pairs(bash.reg.entries) do
            if id == "globals" then continue; end

            ply = ents.GetByIndex(id);
            if !checkply(ply) then continue; end
            steamID = ply:SteamID();

            queries = {};
            for key, val in pairs(entries) do
                var = bash.reg.vars[key];
                if !var or var.IsGlobal or var.Source == SRC_SQL then continue; end

                queries[var.SourceTable] = queries[var.SourceTable] or {};
                queries[var.SourceTable][key] = val;
            end

            query = "";
            for tab, data in pairs(queries) do
                query = Fmt("UPDATE %s SET ", tab);

                for key, val in pairs(data) do
                    var = bash.reg.vars[key];
                    if var.Type == "table" and type(val) == "table" then
                        val = pon.encode(val);
                    end

                    if type(val) == "string" then
                        query = query .. Fmt("%s = \'%s\', ", key, val);
                    else
                        query = query .. key .. " = " .. val .. ", ";
                    end
                end
                query = query:sub(1, -2);

                if tab == "bash_plys" then
                    condition = Fmt(" WHERE SteamID = \'%s\';", steamID);
                elseif tab == "bash_chars" then
                    condition = Fmt(" WHERE SteamID = \'%s\' AND CharID = \'%s\';", steamID, ply:GetNetVar("CharID"));
                end

                query = query .. condition;

                -- Query save here.
            end
        end
    end
    ]]

    function setGlobal(key, val)
        if val == nil then return; end
        local var = bash.reg.vars[key];
        if !var or !var.IsGlobal then return; end
        if type(val) != var.Type then return; end
        if checkBadType(key, val) then return; end
        if getGlobal(key) == val then return; end

        bash.reg.entries.globals[key] = val;

        local update = vnet.CreatePacket("reg_update");
        local send = {};
        send.globals = {};
        send.globals[key] = val;
        update:Table(send);
        update:Broadcast();
    end

    function Entity:SetNetVar(key, val, updateDB)
        if val == nil then return; end
        if self:GetNetVar(key) == val and !istable(val) then return; end
        local var = bash.reg.vars[key];
        if var then
            if var.IsGlobal then return; end
            if type(val) != var.Type then return; end
        end
        if checkBadType(key, val) then return; end

        local id = self:EntIndex();
        bash.reg.entries[id] = bash.reg.entries[id] or {};
        bash.reg.entries[id][key] = val;

        local update = vnet.CreatePacket("reg_update");
        local send = {};
        send[id] = {};
        send[id][key] = val;
        update:Table(send);
        if !var or var.IsPublic then
            update:Broadcast();
        else
            update:AddTargets(self);
            update:Send();
        end

        if !updateDB then return; end
        -- Update SQL values on the fly!...
        if !var then return; end
        -- ...but not if the var isn't permanent!...
        if !checkply(self) then return; end
        if var.Source != SRC_SQL then return; end
        -- ...and also not if the var isn't saved via SQL!...
        local sqlTab = bash.sql.tables[var.SourceTable];
        if sqlTab.Reference == REF_NONE then return; end
        -- ...and also not if the table has no player reference point!

        local query = Fmt("UPDATE %s SET ", var.SourceTable);
        if var.Type == "table" and type(val) == "table" then
            val = bash.sql.escape(pon.encode(val));
            query = query .. Fmt("%s = \'%s\'", key, val);
        elseif var.Type == "boolean" and type(val) == "boolean" then
            query = query .. Fmt("%s = %d", key, (val and 1) or 0);
        elseif var.Type == "string" and type(val) == "string" then
            query = query .. Fmt("%s = \'%s\'", key, bash.sql.escape(val));
        else
            query = query .. key .. " = " .. val;
        end
        if sqlTab.Reference == REF_PLY then
            query = query .. Fmt(" WHERE SteamID = \'%s\';", self:SteamID());
        elseif sqlTab.Reference == REF_CHAR then
            query = query .. Fmt(" WHERE SteamID = \'%s\' AND CharID = \'%s\';", self:SteamID(), self:GetNetVar("CharID"));
        end
        MsgDebug(query);
        local name = self:Name();
        bash.sql.query(query, function(results)
            MsgDebug("Updated '%s' for player %s.", key, name);
        end);
    end

    function Entity:SetNetVars(data)
        local id = self:EntIndex();
        local update = vnet.CreatePacket("reg_update");
        local updateSelf = vnet.CreatePacket("reg_update");
        local send, sendSelf = {}, {};
        send[id] = {};
        sendSend[id] = {};
        for key, val in pairs(data) do
            if val == nil then continue; end
            if self:GetNetVar(key) == val and !istable(val) then continue; end
            local var = bash.reg.vars[key];
            if var then
                if var.IsGlobal then continue; end
                if type(val) != var.Type then continue; end
            end
            if checkBadType(key, val) then return; end

            bash.reg.entries[id] = bash.reg.entries[id] or {};
            bash.reg.entries[id][key] = val;

            sendSelf[id][key] = val;
            if !var or var.IsPublic then
                send[id][key] = val;
            end
        end

        if !table.IsEmpty(send[id]) then
            update:Table(send);
            update:Broadcast();
        else
            update:Discard();
        end

        if !table.IsEmpty(sendSelf[id]) then
            updateSelf:Table(sendSelf);
            updateSelf:AddTargets(self);
            updateSelf:Send();
        else
            updateSelf:Discard();
        end
    end

    function Player:SyncRegistry()
        local update = vnet.CreatePacket("reg_update");

        local send, selfID, var = {}, self:EntIndex(), var;
        for id, entries in pairs(bash.reg.entries) do
            if id == "globals" then
                send.globals = entries;
                continue;
            elseif id == selfID then
                send[id] = entries;
                continue;
            end

            for key, val in pairs(entries) do
                var = bash.reg.vars[key];
                if var.IsPublic --[[or self is staff]] then
                    send[id] = send[id] or {};
                    send[id][key] = val;
                end
            end
        end

        update:Table(send);
        update:AddTargets(self);
        update:Send();
    end

    function Player:Register()
        data = data or {};
        MsgCon(color_green, "Registering player %s...", self:Name());

        bash.reg.sendProgress(self, "Syncing registry...");
        self:SyncRegistry();

        bash.reg.sendProgress(self, "Registering...");
        local id = self:EntIndex();
        bash.reg.entries[id] = bash.reg.entries[id] or {};
        local updateSelf = vnet.CreatePacket("reg_update");
        local update = vnet.CreatePacket("reg_update");

        local sendSelf = {};
        sendSelf[id] = {};
        local send = {};
        send[id] = {};
        local val;
        for key, var in pairs(bash.reg.vars) do
            -- Global variables are not bound to players.
            if var.IsGlobal then continue; end
            -- The 'bash_plys' table is the only data we handle immediately. Registering all other
            -- variables is done either through hooks or manually.
            if var.Source == SRC_SQL and var.SourceTable == "bash_plys" then
                val = (self.SQLData and self.SQLData["bash_plys"] and self.SQLData["bash_plys"][key]) or self:GetDefault(self);
            else
                val = var:GetDefault(self);
            end

            -- Decode tables!
            if var.Type == "table" and type(val) == "string" then
                val = pon.decode(val);
            end

            bash.reg.entries[id][key] = val;
            sendSelf[id][key] = val;
            if var.IsPublic then send[id][key] = val; end
        end

        local except = {};
        for _, ply in pairs(player.GetAll()) do
            if ply != self then
                except[#except + 1] = ply;
            end
        end

        updateSelf:Table(sendSelf);
        updateSelf:AddTargets(self);
        updateSelf:Send();

        if #except >= 1 then
            update:Table(send);
            update:AddTargets(except);
            update:Send();
        else
            update:Discard();
        end

        bash.reg.sendProgress(self, "Finishing up...");
        self.Registered = true;
        bash.reg.lastFinish = id;

        MsgCon(color_green, "Registered player %s!", self:Name());
        hook.Call("PostRegister", nil, self);
    end

    function Entity:Deregister()
        local id = self:EntIndex();
        if id == -1 or !bash.reg.entries[id] then return; end
        bash.reg.entries[id] = nil;

        local update = vnet.CreatePacket("reg_delete");
        update:Int(id);
        update:Broadcast();
    end

    -- Handle the registry queue.
    hook.Add("Think", "reg_queue", function()
        if !bash.reg.queue then return; end
        if !bash.reg.queue:First() then return; end
        if bash.reg.lastFinish == bash.reg.queue:First() then
            -- Get rid of the finished player.
            bash.reg.queue:Dequeue();
            if bash.reg.queue:Len() == 0 then return; end

            local nextID = bash.reg.queue:Dequeue();
            local nextPly = ents.GetByIndex(nextID);
            bash.sql.playerInit(nextPly);

            if bash.reg.queue:Len() >= 1 then
                local update = vnet.CreatePacket("reg_queued");

                local recip, places, ply = {}, {}, nil;
                for index, id in pairs(bash.reg.queue:Elem()) do
                    ply = ents.GetByIndex(id);
                    if checkply(ply) then
                        recip[#recip + 1] = ply;
                        places[id] = index;
                    end
                end

                update:Table(places);
                update:AddTargets(recip);
                update:Send();
            end
        end
    end);

    -- Deregister an entity when removed.
    hook.Add("EntityRemoved", "reg_cleanup", function(ent)
        ent:Deregister();
    end);

    -- Push all SQL-sourced variables to the SQL table structure.
    hook.Add("EditSQLTables", "reg_sqlpush", function()
        for key, var in pairs(bash.reg.vars) do
            if var.Source == SRC_SQL then
                bash.sql.addColumn(var.SourceTable, key, var.Query, true);
            end
        end
    end);

elseif CLIENT then

    vnet.Watch("reg_queued", function(pck)
        local data = pck:Table();
        local id = LocalPlayer():EntIndex();
        bash.reg.queuePlace = data[id] or 0;
        MsgCon(color_green, "You are in queue position %d.", bash.reg.queuePlace);
    end);

    vnet.Watch("reg_progress", function(pck)
        local data = pck:String();
        bash.reg.progress = data;
        MsgCon(color_green, data);

        if data == "Finishing up..." then
            LocalPlayer().Initialized = true;
            MsgCon(color_green, "All done!");
        end
    end);

    vnet.Watch("reg_update", function(pck)
        local data = pck:Table();
        for id, entries in pairs(data) do
            bash.reg.entries[id] = bash.reg.entries[id] or {};
            for key, val in pairs(entries) do
                bash.reg.entries[id][key] = val;
            end
        end
    end);

    vnet.Watch("reg_delete", function(pck)
        local id = pck:Int();
        bash.reg.entries[id] = nil;
    end);

end

-- Add all default registry variables!
hook.Add("AddRegistryVariables", "reg_defaultvars", function()
    bash.reg.addVar{
        ID = "Addresses",
        Type = "table",
        Default = {},
        GetDefault = function(self, ply) return (checkply(ply) and {[ply:IPAddress()] = true}) or self.Default; end,
        Source = SRC_SQL,
        SourceTable = "bash_plys"
    };

    bash.reg.addVar{
        ID = "FirstLogin",
        Type = "number",
        GetDefault = function() return os.time(); end,
        IsPublic = true,
        Source = SRC_SQL,
        SourceTable = "bash_plys"
    };

    bash.reg.addVar{
        ID = "NewPlayer",
        Type = "boolean",
        Default = 1,
        IsPublic = true,
        Source = SRC_SQL,
        SourceTable = "bash_plys"
    };

    bash.reg.addVar{
        ID = "CharName",
        Type = "string",
        Default = "",
        IsPublic = true,
        Source = SRC_SQL,
        SourceTable = "bash_chars"
    };

    bash.reg.addVar{
        ID = "CharDesc",
        Type = "string",
        Default = "",
        IsPublic = true,
        Source = SRC_SQL,
        SourceTable = "bash_chars"
    };

    bash.reg.addVar{
        ID = "BaseModel",
        Type = "string",
        Default = "",
        Source = SRC_SQL,
        SourceTable = "bash_chars"
    };

    bash.reg.addVar{
        ID = "Invs",
        Type = "string",
        Default = "",
        Source = SRC_SQL,
        SourceTable = "bash_chars"
    };

    bash.reg.addVar{
        ID = "Status",
        Type = "number",
        Default = STATUS_CONN,
        IsPublic = true
    };

    bash.reg.addVar{
        ID = "CharID",
        Type = "string",
        Default = ""
    };

    bash.reg.addVar{
        ID = "CharData",
        Type = "string",
        Default = {},
        GetDefault = function(self, ply)
            return (checkply(ply) and ply.SQLData and ply.SQLData["bash_chars"]) or self.Default;
        end
    };
end);

-- For server refreshes.
dropVars();
