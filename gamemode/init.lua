-- Base relies on sandbox elements.
DeriveGamemode("sandbox");
-- Global table for bash elements.
bash = bash or {};

-- Send required base files to client.
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("core/sh_const.lua");
AddCSLuaFile("core/sh_util.lua");
AddCSLuaFile("shared.lua");

-- Include required base files.
include("core/sh_const.lua");
include("core/sh_util.lua");
include("shared.lua");
