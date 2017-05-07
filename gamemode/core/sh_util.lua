-- Various utility functions for both the server and client.
bash.util = bash.util or {};

-- bash.util.includeFile
--   Usage: Include/send a file for download depending on its prefix.
--   Arguments: <string filePath>
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
end

-- bash.util.includeDir
--   Usage: Include/send all files in a particular directory.
--   Arguments: <string dirPath>, <bool recurSubDirs>
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
        bash.util.includeFile(dirPath .. "/" .. file);
    end
    
    if recur then
        for index, dir in ipairs(dirs) do
            bash.util.includeDir(dirPath .. "/" .. dir);
        end
    end
end