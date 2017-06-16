-- Library for handling character data and objects.
bash.char = bash.char or {};
bash.char.active = bash.char.active or {};

function bash.char.instance(ply, id)
    -- get SQL data linked to id
    -- create char object
    -- add to active, link to ply
end

function bash.char.new(steamID, data)
    -- loop through all
end



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
