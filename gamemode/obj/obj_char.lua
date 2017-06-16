Character = {};
Character.meta = {};
Character.meta.__index = Character.meta;

function Character:Create(id, data, ent)
    if !id or !data then return; end

    local char = {};
    char.ID = id;
    char.Data = data;
    char.Entity = ent;
    setmetatable(char, self.meta);
    return char;
end
