-- Global constants. See Documentation for more info.
color_trans =       Color(0, 0, 0, 0);
color_black =       Color(0, 0, 0, 255);
color_white =       Color(255, 255, 255, 255);
color_grey =        Color(151, 151, 151, 255);
color_con =         Color(200, 200, 200, 255);
color_darkred =     Color(151, 0, 0, 255);
color_red =         Color(255, 0, 0, 255);
color_darkgreen =   Color(0, 151, 0, 255);
color_green =       Color(0, 255, 0, 255);
color_darkblue =    Color(0, 0, 151, 255);
color_blue =        Color(0, 0, 255, 255);
color_beige =       Color(151, 151, 0, 255);
color_yellow =      Color(255, 255, 0, 255);
color_turquoise =   Color(0, 151, 151, 255);
color_cyan =        Color(0, 255, 255, 255);
color_purple =      Color(151, 0, 151, 255);
color_pink =        Color(255, 0, 255, 255);

CORE_EXCLUDED = {
    ["sh_const.lua"] =  true,
    ["sh_util.lua"] =   true
};

Fmt = Format;

PREFIXES_CLIENT = {
    ["cl"] =   true,
    ["vgui"] = true
};
PREFIXES_SERVER = {["sv"] = true};
PREFIXES_SHARED = {
    ["sh"] =   true,
    ["item"] = true,
    ["obj"] =  true,
    [string.Explode('_', game.GetMap())[1]] = true
};

REF_NONE = 0;
REF_PLY = 1;
REF_CHAR = 2;

SQL_TYPE = {};
SQL_TYPE["boolean"] = "TINYINT(1) UNSIGNED NOT NULL DEFAULT 0";
SQL_TYPE["number"] = "INT(10) UNSIGNED NOT NULL DEFAULT 0";
SQL_TYPE["string"] = "TEXT NOT NULL DEFAULT \'\'";
SQL_TYPE["table"] = SQL_TYPE["string"];

SRC_SQL = 1;
SRC_CACHE = 2;
SRC_MAN = 3;
