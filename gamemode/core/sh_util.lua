-- Various utility functions for both the server and client.
bash.util = bash.util or {};
local table = table;

--
-- Misc. Global Functions
--
function checkply(ent)
    return IsValid(ent) and ent:IsPlayer();
end

function detype(val, typ)

end

function getMaterial(mat)
    bash.util.matCache = bash.util.matCache or {};
    bash.util.matCache[mat] = bash.util.matCache[mat] or Material(mat);
    return bash.util.matCache[mat];
end

function getModel(mod)
    bash.util.modCache = bash.util.modCache or {};
    bash.util.modCache[mod] = bash.util.modCache[mod] or Model(mod);
    return bash.util.modCache[mod];
end

function LerpColor(frac, from, to, noAlpha)
    for chan, val in pairs(from) do
        if chan == "a" and noAlpha then continue; end
        val = LerpLim(from, val, to[chan], 1);
    end
end

function LerpLim(frac, from, to, lim)
    lim = lim or 1;
    if math.abs(from - to) < lim then
        return to;
    end

    return Lerp(frac, from, to);
end

function MsgCon(color, text, ...)
    if type(color) != "table" then return; end
    if !text then text = ""; end

    text = Format(text, unpack({...})) .. '\n';
    MsgC(color, text);

    -- if verbose logging enabled, log text
end

function MsgDebug(text, ...)
    if !bash.config.debugMode then return; end
    if !text then text = ""; end

    text = Format("[DEBUG] " .. text, unpack({...})) .. '\n';
    MsgC(color_con, text);
end

function MsgErr(text, ...)
    if !text then text = ""; end

    text = Format(text, unpack({...})) .. '\n';
    MsgC(color_red, text);

    -- log error
end

--
-- 'table' Library Functions
--
function table.IsEmpty(tab)
    if !tab or type(tab) != "table" then return true; end
    for _, __ in pairs(tab) do return false; end
    return true;
end

--
-- bash util Functions
--
function bash.util.includeFile(filePath)
    if !filePath then return; end

    local fileName = filePath:GetFileFromFilename();
    local prefix = string.Explode('_', fileName)[1];
    if PREFIXES_CLIENT[prefix] then
        if SERVER then AddCSLuaFile(filePath);
        else include(filePath); end
    elseif PREFIXES_SERVER[prefix] and SERVER then
        include(filePath);
    elseif PREFIXES_SHARED[prefix] then
        if SERVER then AddCSLuaFile(filePath); end
        include(filePath);
    end

    MsgDebug("Processed file '%s'", fileName);
end

function bash.util.includeDir(dirPath, recur)
    if !dirPath then return; end

    local baseDir = "bash-base";
    if SCHEMA and SCHEMA.Folder and SCHEMA.IsLoading then
        baseDir = SCHEMA.Folder .. "/schema/";
    else
        baseDir = baseDir .. "/gamemode/";
    end

    local files, dirs = file.Find(baseDir .. dirPath .. "/*.lua", "LUA");
    for index, file in ipairs(files) do
        if dirPath == "core" and CORE_EXCLUDED[file] then continue; end
        bash.util.includeFile(dirPath .. "/" .. file);
    end

    MsgDebug("Processed directory '%s'", dirPath);

    if recur then
        for index, dir in ipairs(dirs) do
            bash.util.includeDir(dirPath .. "/" .. dir);
        end
    end
end

function bash.util.getID()
	return tostring(math.Round(os.time() + system.AppTime() + (math.cos(SysTime()) * 26293888)));
end
