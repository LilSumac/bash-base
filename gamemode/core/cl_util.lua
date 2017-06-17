-- Various utility functions for clients only.
bash.util = bash.util or {};
local draw = draw;
local surface = surface;

--
-- Misc. Global Functions
--
function checkpanel(panel)
	return IsValid(panel) and ispanel(panel);
end

--
-- 'draw' Library Functions
--
function draw.PositionIsInArea(posX, posY, firstPosX, firstPosY, secondPosX, secondPosY)
	return ((posX >= firstPosX and posX <= secondPosX) and (posY >= firstPosY and posY <= secondPosY));
end

function draw.Circle(posX, posY, radius, quality, color)
	local points = {};
	local temp;

	for index = 1, quality do
		temp = math.rad(index * 360) / quality;

		points[index] = {
			x = posX + (math.cos(temp) * radius),
			y = posY + (math.sin(temp) * radius)
		};
	end

	draw.NoTexture();
	surface.SetDrawColor(color);
	surface.DrawPoly(points);
end

function draw.Radial(x, y, r, ang, rot, color)
	local segments = 360;
	local segmentstodraw = 360 * (ang / 360);
	rot = rot * (segments / 360);
	local poly = {};

	local temp = {};
	temp['x'] = x;
	temp['y'] = y;
	table.insert(poly, temp);

	for i = 1 + rot, segmentstodraw + rot do
		local temp = {};
		temp['x'] = math.cos((i * (360 / segments)) * (math.pi / 180)) * r + x;
		temp['y'] = math.sin((i * (360 / segments)) * (math.pi / 180)) * r + y;

		table.insert(poly, temp);
	end

	draw.NoTexture();
	surface.SetDrawColor(color);
	surface.DrawPoly(poly);
end

function draw.FadeColor(from, to, rate, doAlpha)
	for chan, val in pairs(from) do
		if chan == "a" and !doAlpha then continue; end
		if val != to[chan] then
			if math.abs(val - to[chan]) < 1 then
				from[chan] = to[chan];
			else
				from[chan] = Lerp(rate, val, to[chan]);
			end
		end
	end
end

function draw.FadeColorAlpha(from, to, rate)
	if from.a != to then
		if math.abs(from.a - to) < 1 then
			from.a = to;
		else
			from.a = Lerp(rate, from.a, to);
		end
	end
end

--
-- 'string' Library Functions
--
function string.wrap(str, font, size)
	if string.len(str) == 1 then return str, 0; end
    str = string.Replace(str, '\n', '');
    str = string.Replace(str, "<br>", '\n');

    surface.SetFont(font);
	local start, c, n, lastspace, lastspacemade = 1, 1, 0, 0, 0;
	local endstr = "";
	while string.len(str or "") > c do
		local sub = string.sub(str, start, c);

		if str[c] == " " then
			lastspace = c;
		end

		if surface.GetTextSize(sub) >= size and lastspace != lastspacemade then
			local sub2;
			if lastspace == 0 then
				lastspace = c;
				lastspacemade = c;
			end

			if lastspace > 1 then
				sub2 = string.sub(str, start, lastspace - 1);
				c = lastspace;
			else
				sub2 = string.sub(str, start, c);
			end

			endstr = endstr .. sub2 .. "\n";
			lastspace = c + 1;
			lastspacemade = lastspace;
			start = c + 1;
			n = n + 1;
		end

		c = c + 1;
	end

	if start < string.len(str or "") then
		endstr = endstr .. string.sub(str or "", start);
	end

	return endstr, n;
end

--
-- bash util Functions
--

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