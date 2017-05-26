-- Various utility functions for both the server and client.
bash.util = bash.util or {};

function MsgCon(color, text, ...)
    if type(color) != "table" then return; end
    if !text then text = ""; end

    text = Format(text, unpack({...})) .. '\n';
    MsgC(color, text);

    -- if verbose logging enabled, log text
end

function MsgErr(text, ...)
    if !text then text = ""; end

    text = Format(text, unpack({...})) .. '\n';
    MsgC(color_red, text);

    -- log error
end

function MsgDebug(text, ...)
    if !bash.config.debugMode then return; end
    if !text then text = ""; end

    text = Format("[DEBUG] " .. text, unpack({...})) .. '\n';
    MsgC(color_con, text);
end

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

    MsgDebug()
end

function bash.util.includeDir(dirPath, recur)
    if !dirPath then return; end

    local baseDir = "bash";
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

    if recur then
        for index, dir in ipairs(dirs) do
            bash.util.includeDir(dirPath .. "/" .. dir);
        end
    end
end
