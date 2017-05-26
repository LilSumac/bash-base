-- Handler for networking variables.
bash.net = bash.net or {};
bash.net.globals = bash.net.globals or {};

-- Metatables.
local Entity = FindMetaTable("Entity");
local Player = FindMetaTable("Player");

function getNetVar(key, default)
    local val = bash.net.globals[key];
    return (val != nil and value) or default;
end

function Entity:GetNetVar(key, default)
    if bash.net[self] and bash.net[self][key] != nil then
        return bash.net[self][key];
    end
    return default;
end
Player.GetLocalVar = Entity.GetNetVar;

if SERVER then
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

    function setNetVar(key, val, rec)
        if checkBadType(key, val) then return; end
        if getNetVar(key) == val then return; end

        bash.net.globals[key] = val;

        rec = rec or player.GetAll();
        local netPack = vnet.CreatePacket("netGVar");
        netPack:Table({[key] = val});
        netPack:AddTargets(rec);
        netPack:Send();
    end

    function Entity:SetNetVar(key, val, rec)
        if checkBadType(key, val) then return; end

        bash.net[self] = bash.net[self] or {};
        if bash.net[self][key] != val then
            bash.net[self][key] = val;
        end

        rec = rec or player.GetAll();
        local netPack = vnet.CreatePacket("netNVar");
        netPack:Entity(self);
        netPack:Table({[key] = val});
        netPack:AddTargets(rec);
        netPack:Send();
    end

    function Player:SyncVars()
        local curPack;
        for ent, data in pairs(bash.net) do
            if ent == "globals" then
                curPack = vnet.CreatePacket("netGVar");
            elseif IsValid(ent) then
                curPack = vnet.CreatePacket("netNVar");
                curPack:Entity(ent);
            else continue; end

            curPack:Table(data);
            curPack:AddTargets(self);
            curPack:Send();
        end
    end

    -- Networked Strings
    util.AddNetworkString("netGVar");
    util.AddNetworkString("netNVar");

elseif CLIENT then



end
