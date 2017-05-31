Queue = {};
Queue.meta = {};
Queue.meta.__index = Queue.meta;

function Queue:Create(...)
    local tab = {};
    tab.Entries = {};
    setmetatable(tab, self.meta);

    local args = {...};
    if args and #args > 0 then
        tab:enqueue(...);
    end

    return tab;
end

function Queue.meta:Enqueue(...)
    local args = {...};
    if #args == 0 then return end;

    for _, val in pairs(args) do
        table.insert(self.Entries, val);
    end

    return #self.Entries;
end

function Queue.meta:Dequeue(num)
    num = num or 1;
    local entries = {};
    for index = 1, num do
        if #self.Entries > 0 then
            entries[#entries + 1] = self.Entries[1];
            table.remove(self.Entries, 1);
        else break end;
    end

    return unpack(entries);
end

function Queue.meta:Elem()
    return self.Entries;
end

function Queue.meta:First()
    return self.Entries[1];
end

function Queue.meta:Len()
    return #self.Entries;
end

function Queue.meta:Print()
    MsgDebug("Queue: %s", tostring(self));
    for index, val in pairs(self.Entries) do
        MsgDebug("\t%d : %s", index, tostring(val));
    end
end
