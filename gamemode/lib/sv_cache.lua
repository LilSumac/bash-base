bash.cache = bash.cache or {};
bash.cache.stored = bash.cache.stored or {};

-- Cached data is saved in text files.
file.CreateDir("bash");

function bash.cache.set(key, val, global, ignoreMap)
    local path = "bash/" .. (global and "" or SCHEMA.Folder .. "/") .. (ignoreMap and "" or game.GetMap() .. "/");

    if !global then
        file.CreateDir("bash/" .. SCHEMA.Folder .. "/");
    end

    file.CreateDir(path);
    file.Write(path .. key .. ".txt", pon.encode({val}));
    bash.cache.stored[key] = value;
end

function bash.cache.get(key, default, global, ignoreMap, refresh)
    if !refresh then
        if bash.cache.stored[key] != nil then
            return bash.cache.stored[key];
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

function bash.cache.delete(key, global, ignoreMap)
    local path = "bash/" .. (global and "" or SCHEMA.Folder .. "/") .. (ignoreMap and "" or game.GetMap() .. "/");
    local contents = file.Read(path .. key .. ".txt", "DATA");
    if contents and contents != "" then
        file.Delete(path .. key .. ".txt");
        bash.cache.stored[key] = nil;
    end
end
