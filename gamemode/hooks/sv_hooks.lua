-- Server-side hooks.

function GM:PlayerSpawn(ply)
    ply:Initialize();
end

-- Networked strings.
util.AddNetworkString("bash_ply_init");

-- Network hooks.
vnet.Watch("bash_ply_init", function(pck)
    local ply = pck.Source;
    bash.sql.playerInit(ply);
end);
