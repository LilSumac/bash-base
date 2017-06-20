-- Base relies on sandbox elements.
DeriveGamemode("sandbox");
-- Global table for bash elements.
bash = bash or {};
bash.startTime = SysTime();

-- Send required base files to client.
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("core/sh_const.lua");
AddCSLuaFile("core/cl_util.lua");
AddCSLuaFile("core/sh_util.lua");
AddCSLuaFile("shared.lua");

-- Include required base files.
include("core/sh_const.lua");
include("core/sh_util.lua");
include("core/sv_util.lua");
include("shared.lua");

-- Report startup time.
local len = math.Round(SysTime() - bash.startTime, 8);
MsgCon(color_green, "Successfully initialized server-side. Startup: %fs", len);

-- Entry point for the SQL DB.
bash.sql.connect();
