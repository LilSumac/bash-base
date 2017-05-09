-- Handler for networking variables.
bash.net = bash.net or {};
bash.net.globals = bash.net.globals or {};

-- Metatables.
local Entity = FindMetaTable("Entity");
local Player = FindMetaTable("Player");

function getNetVar(key, default)
    local val = bash.net.globals[key];
    return val != nil and value or default;
end

function Entity:GetNetVar(key, default)
    local index = self:EntIndex();
    if bash.net[index] and bash.net[index][key] != nil then
        return bash.net[index][key];
    end
    return default;
end
Player.GetLocalVar = Entity.GetNetVar;

if SERVER then
    -- Check to see if there's an attempt to send a function.
    local function checkBadType(key, value)
        local valType = type(val);
        if valType == "function" then
            MsgErr("Networked var '%s' contains a bad object type!", key);
            return true;
        elseif valType == "table" then
            for k, v in pairs(value) do
                if checkBadType(key, k) or checkBadType(key, v) then
                    return true;
                end
            end
        end
    end

    function setNetVar(key, val, rec)
        if checkBadType(key, val) then return; end
        if getNetVar(key) == val then return; end

        bash.net.globals[key] = val;

        rec = rec or player.GetAll();
    end

elseif CLIENT then

end
