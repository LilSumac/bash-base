-- Main data structure for handling networked variables.
bash.reg = bash.reg or {};
bash.reg.vars = bash.reg.vars or {};
bash.reg.entries = bash.reg.entries or {};
bash.reg.entries.globals = bash.reg.entries.globals or {};
bash.reg.queue = bash.reg.queue or Queue:Create();
bash.reg.queuePlace = bash.reg.queuePlace or 0;
bash.reg.lastFinish = bash.reg.lastFinish or nil;

function bash.reg.addVar(varTab)
    if !varTab.ID then return; end
    if bash.reg.vars[varTab.ID] then
        MsgErr("[bash.reg.addVar] -> A variable with the ID '%s' already exists.", varTab.ID);
        return;
    end

    varTab.ID = varTab.ID;
    varTab.Type = varTab.Type or "string";
    varTab.Default = varTab.Default or "";
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

-- Metatables.
local Entity = FindMetaTable("Entity");
local Player = FindMetaTable("Player");

function getGlobal(key)
    local var = bash.reg.vars[key];
    if !var or !var.IsGlobal then return; end
    return bash.reg.entries.globals[key] or var.Default;
end

function Entity:GetNetVar(key)
    local var = bash.reg.vars[key];
    if var and var.IsGlobal then return; end
    if !bash.reg.entries[self:EntIndex()] then
        MsgErr("[Entity.GetNetVar] -> This entity is not in the registry! (%s)", tostring(self));
        return;
    end
    return bash.reg.entries[self:EntIndex()][key] or (var and var.Default);
end

if SERVER then
    -- Networked strings.
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
            local val = bash.cache.get(var.SourceKey or key, var.Default, var.IgnoreSchema, var.IsMapSpecific, true);
            bash.entries.globals[key] = val;
            send.globals[key] = val;
        end

        update:Table(send);
        update:Broadcast();
    end

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

    function Entity:SetNetVar(key, val)
        if val == nil then return; end
        if self:GetNetVar(key) == val then return; end
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
        update:Int(id);
        update:Table(send);
        if !var or var.IsPublic then
            update:Broadcast();
        else
            update:AddTargets(self);
            update:Send();
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

        update:Table(update);
        update:AddTargets(self);
        update:Send();
    end

    function Player:Register(data)
        data = data or {};
        MsgCon(color_green, "Registering player %s...", self:Name());

        local id = self:EntIndex();
        bash.reg.queue = bash.reg.queue or Queue:Create();
        local peek = bash.reg.queue:First();
        if !peek then
            bash.reg.queue:Enqueue(id);

            local update = vnet.CreatePacket("reg_queued");
            update:Table({[id] = 1});
            update:AddTargets(self);
            update:Send();
        elseif peek and peek != id then
            bash.reg.queue:Enqueue(id);
            return;
        end

        self:SyncRegistry();

        local updateSelf = vnet.CreatePacket("reg_update");
        local update = vnet.CreatePacket("reg_update");

        local sendSelf = {};
        sendSelf[id] = {};
        local send = {};
        send[id] = {};
        local val;
        for key, var in pairs(bash.reg.vars) do
            if var.IsGlobal then continue end;

            val = data[key] or var.Default;
            bash.reg.entries[id][key] = val;
            sendSelf[id][key] = val;
            if var.IsPublic then send[id][key] = val; end
        end

        updateSelf:Table(sendSelf);
        updateSelf:AddTargets(self);
        updateSelf:Send();

        local except = {};
        for _, ply in pairs(player.GetAll()) do
            if ply != self then
                except[#except + 1] = ply;
            end
        end

        update:Table(send);
        update:AddTargets(except);
        update:Send();

        bash.reg.lastFinish = id;
        PrintTable(bash.reg.entries);
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
        local data = pck.Data;
        local id = LocalPlayer():EntIndex();
        bash.reg.queuePlace = data[id] or 0;
    end);

    vnet.Watch("reg_update", function(pck)
        local data = pck.Data;
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
        ID = "FirstLogin",
        Type = "number",
        Default = 0,
        IsPublic = true,
        Source = SRC_SQL
    };

    bash.reg.addVar{
        ID = "NewPlayer",
        Type = "boolean",
        Default = 0,
        IsPublic = true,
        Source = SRC_SQL
    };

    bash.reg.addVar{
        ID = "CharData",
        Type = "string",
        Default = {}
    };

    bash.reg.addVar{
        ID = "CharName",
        Type = "string",
        Default = "",
        IsPublic = true
    };

    bash.reg.addVar{
        ID = "Desc",
        Type = "string",
        Default = "",
        IsPublic = true
    };

    bash.reg.addVar{
        ID = "BaseModel",
        Type = "string",
        Default = ""
    };

    bash.reg.addVar{
        ID = "Invs",
        Type = "string",
        Default = ""
    };
end);
