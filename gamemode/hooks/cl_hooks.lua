-- Client-side hooks.

function GM:InitPostEntity()
    --[[
    local init = vnet.CreatePacket("bash_ply_init");
    init:AddServer();
    init:Send();
    ]]

    LocalPlayer().Initialized = false;
    bash.intro = vgui.Create("bash_intro");
end

-- Handling mid-game resolution changes.
local resChanged = false;
hook.Add("HUDPaint", "BASH_HandleResChange", function()
    if SCRW != ScrW() then
        SCRW = ScrW();
        resChanged = true;
    end
    if SCRH != ScrH() then
        SCRH = ScrH();
        resChanged = true;
    end
    if resChanged then
        CENTER_X = SCRW / 2;
        CENTER_Y = SCRH / 2;
        resChanged = false;
    end
end);

--
-- Network Hooks
--
vnet.Watch("util_progress", function(pck)
	local msg = pck:String();
	local done = pck:Bool();
	bash.progress = msg;
	MsgCon(color_green, msg);

	if done then
		LocalPlayer().Initialized = true;
		MsgCon(color_green, "All done!");
	end
end);
