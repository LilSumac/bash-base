-- Library for handling character data and objects.
bash.char = bash.char or {};
bash.char.vars = bash.char.vars or {};
bash.char.active = bash.char.active or {};

function bash.char.addVar(varTab)
    if !varTab or !varTab.ID then return; end
    if bash.reg.vars[varTab.ID] then
        MsgErr("[bash.char.addVar] -> A variable with the ID '%s' already exists.", varTab.ID);
        return;
    end

    -- General variable information.
    varTab.ID = varTab.ID;
    varTab.Type = varTab.Type or "string";
    varTab.Default = varTab.Default or "";
    varTab.IsPublic = varTab.IsPublic or false;

    -- Variable source information.
    varTab.Source = varTab.Source or SRC_MAN;
    varTab.SourceColumn = (varTab.Source == SRC_SQL and varTab.SourceColumn) or nil;

    -- Variable hooks.
    varTab.OnGenerateCL = varTab.OnGenerateCL; -- function(_self, def)
    varTab.OnGenerateSV = varTab.OnGenerateSV; -- function(_self, def, ply)
    varTab.OnLoad = varTab.OnLoad or function(_self, ply, index, def)
        if _self.Source == SRC_SQL then
            return ply:GetSQLData(_self.SourceTable, index, _self.SourceColumn);
        else return def; end
    end
    varTab.OnGet = varTab.OnGet; -- function(_self, val, def, ent)
    varTab.OnSet = varTab.OnSet; -- function(_self, val, def, ent)

    bash.char.vars[varTab.ID] = varTab;
end

-- Local function for dropping the variable structures (on refresh).
local function dropVars()
    if table.IsEmpty(bash.char.vars) then return; end
    MsgDebug("Dropping variable structures from character library...");
    bash.char.vars = {};
end

function bash.char.instance(ply, id)
    -- get SQL data linked to id
    -- create char object
    -- add to active, link to ply
end

function bash.char.new(steamID, data)
    -- loop through all
end


--[[
bash.char = bash.char or {};
bash.char.active = bash.char.active or {};

function bash.char.create(ply, data)
    if !checkply(ply) or !data then return; end

    local fullData = {};
    local vars, vals, val = {}, {};
    for key, var in pairs(bash.reg.vars) do
        if var.IsGlobal then continue; end

        vars[#vars + 1] = key;
        val = (data[key] or var:GetDefault(ply));
        fullData[key] = val;
        if var.Type == "string" and type(val) == "string" then
            vals[#vals + 1] = Fmt("\'%s\'", val);
        elseif var.Type == "table" and type(val) == "table" then
            vals[#vals + 1] = pon.encode(val);
        else
            vals[#vals + 1] = val;
        end
    end

    hook.Call("PreCreateChar", nil, data);

    local query = "INSERT INTO bash_chars(";
    query = query .. table.concat(vars, ", ") .. ") VALUES(";
    query = query .. table.concat(vals, ", ") .. ");";
    bash.sql.query(query, function(results)
        ply:SetNetVars(fullData);
    end);
end

function bash.char.load(ply, id)

end

function bash.char.unload(ply)
    if !checkply(ply) or ply:GetNetVar("Status") != STATUS_ACTIVE then return; end

    local id = ply:GetNetVar("CharID");

end

function bash.char.delete(id, ply)

end
]]



do -- For server refreshes.
    dropVars();
end
