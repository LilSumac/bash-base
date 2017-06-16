-- Base relies on sandbox elements.
DeriveGamemode("sandbox");
-- Global table for bash elements.
bash = bash or {};
bash.startTime = SysTime();

-- Include required base files.
include("core/sh_const.lua");
include("core/cl_util.lua");
include("core/sh_util.lua");
include("shared.lua");

-- Report startup time.
local len = math.Round(SysTime() - bash.startTime, 8);
MsgCon(color_green, "Successfully initialized client-side. Startup: %fs", len);

-- Get rid of useless sandbox notifications.
timer.Remove("HintSystem_OpeningMenu");
timer.Remove("HintSystem_Annoy1");
timer.Remove("HintSystem_Annoy2");

-- Load fonts for use.
local function loadFonts()
	surface.CreateFont("bash-icons-1", {
		font = "bash-icons-1",
		size = 16
	});
	surface.CreateFont("bash-icons-2", {
		font = "bash-icons-2",
		size = 16
	});
	surface.CreateFont("bash-light-24", {
		font = "Ubuntu Light",
		size = 24
	});
	surface.CreateFont("bash-regular-24", {
		font = "Ubuntu",
		size = 24
	});
	surface.CreateFont("bash-regular-36", {
		font = "Ubuntu",
		size = 36
	});
	surface.CreateFont("bash-mono-24", {
		font = "Ubuntu Mono",
		size = 24
	});
end
hook.Add("InitPostEntity", "BASH_FontBug", loadFonts);

loadFonts();
