bash.reg = bash.reg or {};
bash.reg.stored = bash.reg.stored or {};

-- Registry data is saved in text files.
file.CreateDir("bash");

--------------------
-- Library Functions
--------------------

-- bash.reg.set
--   Usage: Sets a persistence variable mapped to a key and saves it to an
--          individual text file.
--   Arguments: <string key>, <string value>, <bool isGlobalVar>, <bool isNotMapSpecific>
function bash.reg.set(key, val, global, ignoreMap)
    local path = "bash/" .. (global and "" or SCHEMA.Folder .. "/") .. (ignoreMap and "" or game.GetMap() .. "/");

    if !global then
        file.CreateDir("bash/" .. SCHEMA.Folder .. "/");
    end

    file.CreateDir(path);
    file.Write(path .. key .. ".txt", pon.encode({val}));
    bash.reg.stored[key] = value;
end

-- bash.reg.set
--   Usage: Returns a persistence variable mapped to the given key, if it
--          exists. Otherwise, it will return the default value given.
--   Arguments: <string key>, <string default>, <bool isGlobalVar>, <bool isNotMapSpecific>, <bool shouldRefresh>
--   Returns: <vararg value>
function bash.reg.get(key, default, global, ignoreMap, refresh)
    if !refresh then
        if bash.reg.stored[key] != nil then
            return bash.reg.stored[key];
        end
    end

    local path = "bash/" .. (global and "" or SCHEMA.Folder .. "/") .. (ignoreMap and "" or game.GetMap() .. "/");
    local contents = file.Read(path .. key .. ".txt", "DATA");
    if content and contents != "" then
        local status, decoded = pcall(pon.decode, contents);
        if status and decoded then
            if decoded[1] != nil then
                return decoded[1];
            else
                return default;
            end
        else
            return default;
        end
    else
        return default;
    end
end

-- bash.reg.delete
--   Usage: Deletes an existing persistence variable from the registry.
--   Arguments: <string key>, <bool isGlobalVar>, <bool isNotMapSpecific>
function bash.reg.delete(key, global, ignoreMap)
    local path = "bash/" .. (global and "" or SCHEMA.Folder .. "/") .. (ignoreMap and "" or game.GetMap() .. "/");
    local contents = file.Read(path .. key .. ".txt", "DATA");
    if contents and contents != "" then
        file.Delete(path .. key .. ".txt");
        bash.reg.stored[key] = nil;
    end
end

-----------------
-- Hooks & Timers
-----------------

-- bashSaveRegistry
-- Calls the SaveRegistry hook every 10 minutes.
timer.Create("bashSaveRegistry", 600, 0, function()
    hook.Run("SaveRegistry");
end);
