-- Terminal-approved colors!
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

-- Files to be excluded from directory processing.
CORE_EXCLUDED = {
    ["sh_ell"] =    true,
    ["sh_glob"] =   true,
    ["sh_util"] =   true
};

-- File prefixes for sorting.
PREFIXES_CLIENT = {
    ["cl_"] =   true,
    ["vgui_"] = true
};
PREFIXES_SERVER = {["sv_"] = true};
PREFIXES_SHARED = {
    ["sh_"] =   true,
    ["item_"] = true,
    ["obj_"] =  true,
    [string.Explode('_', game.GetMap())[1] .. "_"] = true
};
