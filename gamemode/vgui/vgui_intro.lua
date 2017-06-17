-- vgui element that handles the intro animation sequence.
-- This is by far the ugliest code in the project thus far. I suck at making
-- stuff look good.
bash.progress = bash.progress or "Loading...";

local INTRO = {};
INTRO.Stage = INTRO.Stage or "Loading";
INTRO.CurStep = INTRO.CurStep or 1;
INTRO.SetupElements = INTRO.SetupElements or {};
INTRO.SetupValues = INTRO.SetupValues or {};
INTRO.RequestedData = INTRO.RequestedData or false;

-- Positions
local w, h = SCRW, SCRH;
local x1, x2, y1, y2 = 0, 0, 0, 0;
local left, right, up, down = (w * 0.125), (w * 0.875), (h * 0.2), (h * 0.8);

-- Colors
local colBG, colAnim = colBG or Color(255, 255, 255), colAnim or Color(255, 255, 255);
local colorL, colorT, colorR, colorB;
local bgSeq = {
    Color(51, 153, 255),
    Color(255, 51, 153),
    Color(153, 255, 51),
    Color(0, 153, 153),
    Color(153, 0, 153),
    Color(153, 153, 0),
    Color(0, 153, 76),
    Color(76, 0, 153),
    Color(153, 76, 0)
};

-- Alphas
local alphaBG, alphaAnim = alphaBG or 255, alphaAnim or 0;

-- Materials
local gradH = getMaterial("gui/gradient");
local gradV = getMaterial("gui/gradient_down");

-- Text Resources
local headers = {
    "Welcome!",
    "What is /bash/?",
    "How do you play?",
    "Where do I start?",
    "Let's get started!"
};
local subheaders = {
    "Hello and welcome to the /bash/ public beta. You're in for an exclusive look at a roleplay gamemode many years in the making. Please keep these things in mind:<br><br>• All features and content are subject to change.<br>• Any bugs or instabilities are being worked on, and we appreciate your patience.<br>• Staff are waiting and ready to assist you should you need it.<br><br>By proceeding, you agree to abide by the server rules.",
    "BASH is a gamemode developed by LilSumac over the course of several years. In early 2016, an alpha version was released as a public server, to mild success. However, the gamemode itself was not ready for the demands of a populated server, and thus the project was scrapped. Source code for the alpha can be found at github.com/LilSumac/bash-srp-alpha.<br><br>Now, after completely gutting the initial version and starting anew, the BASH beta aims to deliver a smooth, streamlined experience to you, the player. We hope that you find the gamemode to be responsive, immersive, and visually appealing.",
    "Like many other popular gamemodes such as Clockwork, NutScript, and TacoScript, BASH is a serious roleplay framework. This is not a DarkRP, PERP, or any other 'lite' RP gamemode, and should not be played as one. BASH relies heavily on character creation, development, and interaction with your fellow players rather than just shooting and looting.<br><br>In addition, the gamemode itself is usually based within some kind of universe, ranging from popular video games such as S.T.A.L.K.E.R. and Half-life 2 to more realistic scenarios like real-world military conflicts and apocalyptic settings.<br><br>If you are unfamiliar with the concept described here, feel free to reach out to a staff member and they will assist you in getting oriented.",
    "On the next screen, you'll be faced with your character menu. This is where you manage all of your different characters. Simply create a new character and you'll be dropped into the world. From there, if you need help, reach out to another player in the local OOC chat (.// in chat) and you'll get the guidance you need.",
    "You're all set to start playing! Thank you again for choosing this server, and we hope you enjoy yourself playing /bash/!<br><br>-LilSumac and the Admin Team"
};

function INTRO:Init()
    self:SetSize(0, 0);
    self:SetSize(SCRW, SCRH);
end

function INTRO:PaintBG(w, h)
    surface.SetDrawColor(color_white);
    surface.DrawRect(0, 0, w, h);

    local time = CurTime() * 10;
    colorL = HSVToColor(time % 360, 0.5, 0.5);
    colorT = HSVToColor((time + 30) % 360, 0.5, 0.5);
    colorR = HSVToColor((time + 60) % 360, 0.5, 0.5);
    colorB = HSVToColor((time + 90) % 360, 0.5, 0.5);
    colorL.a = alphaAnim;
    colorT.a = alphaAnim;
    colorR.a = alphaAnim;
    colorB.a = alphaAnim;

    surface.SetMaterial(gradH);
    surface.SetDrawColor(colorL);
    surface.DrawTexturedRect(0, 0, w, h);

    surface.SetMaterial(gradH);
    surface.SetDrawColor(colorR);
    surface.DrawTexturedRectUV(0, 0, w, h, 1, 0, 0, 1);

    surface.SetMaterial(gradV);
    surface.SetDrawColor(colorT);
    surface.DrawTexturedRect(0, 0, w, h);

    surface.SetMaterial(gradV);
    surface.SetDrawColor(colorB);
    surface.DrawTexturedRectUV(0, 0, w, h, 0, 1, 1, 0);
end

function INTRO:Paint(w, h)
    if self.Stage == "Done" then return; end

    if !LocalPlayer().Initialized then
        alphaBG = LerpLim(0.05, alphaBG, 0);
        alphaAnim = LerpLim(0.01, alphaAnim, 255);
        LerpColor(0.01, colBG, color_white, true);

        if alphaBG == 0 and alphaAnim > 200 and !self.RequestedData then
            self.RequestedData = true;
            local init = vnet.CreatePacket("bash_ply_init");
            init:AddServer();
            init:Send();
        end
    elseif self.Stage == "Intro" then
        alphaAnim = LerpLim(0.01, alphaAnim, 255);
        LerpColor(0.01, colBG, color_white, true);
    end

    colBG.a = alphaBG;
    colAnim.a = alphaAnim;

    if self.Stage != "Finalize" then
        self:PaintBG(w, h);
    end

    surface.SetDrawColor(colBG);
    surface.DrawRect(0, 0, w, h);

    if self.Stage == "Loading" then
        draw.SimpleText(bash.progress, "bash-regular-24", CENTER_X, CENTER_Y - 85, colAnim, TEXT_CENT, TEXT_BOT);
        if bash.reg.queuePlace > 1 then
            draw.SimpleText(Fmt("Place in queue: %d", bash.reg.queuePlace), "bash-regular-24", CENTER_X, CENTER_Y + 85, colAnim, TEXT_CENT, TEXT_TOP);
        elseif bash.reg.queuePlace == 1 then
            draw.SimpleText("You're on your way!", "bash-regular-24", CENTER_X, CENTER_Y + 85, colAnim, TEXT_CENT, TEXT_TOP);
        end

        x1 = CENTER_X - (math.cos(SysTime()) * 100);
        y1 = CENTER_Y + (math.sin(SysTime() * 2) * 60);
        x2 = CENTER_X - (math.cos(SysTime() - 0.25) * 100);
        y2 = CENTER_Y + (math.sin((SysTime() * 2) - 0.25) * 60);

        draw.Circle(x1 + (10 * -math.cos(SysTime() * 2)), y1 + (10 * math.sin(SysTime())), 4, 10, colAnim);
        draw.Circle(x1 - (10 * -math.cos(SysTime() * 2)), y1 - (10 * math.sin(SysTime())), 4, 10, colAnim);
        draw.Circle(x2, y2, 4, 10, colAnim);
    elseif self.Stage == "Intro" then
        alphaBG = LerpLim(0.05, alphaBG, 0);

        draw.SimpleText(headers[self.CurStep], "bash-regular-36", w / 2, (h * 0.2), colAnim, TEXT_CENT, TEXT_TOP);

        -- Cache the subheader lines for efficiency.
        for index, line in pairs(self.SubCache) do
            local boxH = 24 * #self.SubCache;
            -- Center the new player intro text.
            draw.SimpleText(line, "bash-light-24", w / 2, (h / 2) - (boxH / 2) + ((index - 1) * 24), colAnim, TEXT_CENT, TEXT_TOP);
        end

        local wid = (32 * #headers) - 24;
        for index = 1, #headers do
            draw.Circle(
                (CENTER_X - (wid / 2)) + (24 * (index - 1)) + 4,
                (h * 0.8) - 16,
                4, 10, (self.CurStep == index and Color(128, 128, 128, alphaAnim)) or colAnim
            );
        end
    elseif self.Stage == "IntroDone" then
        alphaBG = LerpLim(0.05, alphaBG, 255);
        LerpColor(0.01, colBG, color_black, true);

        if alphaBG > 200 and colBG.r < 20 and colBG.g < 20 and colBG.b < 20 then
            self.ShowedEnjoy = self.ShowedEnjoy or CurTime();
            alphaAnim = LerpLim(0.01, alphaAnim, 255);
            draw.SimpleText("Enjoy.", "bash-regular-36", w / 2, h / 2, colAnim, TEXT_CENT, TEXT_CENT);
            if CurTime() - self.ShowedEnjoy > 3 then
                self.Stage = "Finalize";
            end
        else
            alphaAnim = LerpLim(0.05, alphaAnim, 0);
        end
    elseif self.Stage == "Finalize" then
        draw.SimpleText("Enjoy.", "bash-regular-36", w / 2, h / 2, colAnim, TEXT_CENT, TEXT_CENT);
        alphaAnim = LerpLim(0.02, alphaAnim, 0);
        alphaBG = LerpLim(0.02, alphaBG, 0);
        if alphaAnim == 0 and alphaBG == 0 then
            self.Stage = "Done";
            self:Remove();
            bash.charmenu.open();
        end
    end

    if LocalPlayer().Initialized and self.Stage == "Loading" then
        alphaAnim = LerpLim(0.05, alphaAnim, 0);
        alphaBG = LerpLim(0.05, alphaBG, 255);

        if LocalPlayer():GetNetVar("NewPlayer") == 1 then
            if alphaAnim < 1 then
                self:CreateNewPlayer();
                self.Stage = "Intro";
            end
        else
            if alphaAnim < 1 then
                self.Stage = "Finalize";
            end
        end
    end
end

function INTRO:SetStep(step)
    self.CurStep = step;

    local sub = string.wrap(subheaders[step], "bash-light-24", w * 0.4);
    self.SubCache = string.Explode('\n', sub);

    if step == 1 then
        self.BackButton:SetDrawText("Disconnect");
        self.NextButton:SetDrawText("Begin");
    elseif step == #headers then
        self.BackButton:SetDrawText("Back");
        self.NextButton:SetDrawText("Jump in!");
    else
        self.BackButton:SetDrawText("Back");
        self.NextButton:SetDrawText("Next");
    end
end

function INTRO:CreateNewPlayer()
    gui.EnableScreenClicker(true);
    self.SubCache = string.Explode('\n', string.wrap(subheaders[1], "bash-light-24", w * 0.4));

    local _self = self;
    self.BackButton = vgui.Create("TextButton", self);
    self.BackButton:SetDrawFont("bash-regular-36");
    self.BackButton:SetDrawText("Disconnect");
    self.BackButton:SetTextColor(colAnim);
    self.BackButton:SetPos(left, down - 36);
    function self.BackButton:DoClick()
        if self.DrawText == "Disconnect" then
            RunConsoleCommand("disconnect");
            return;
        end

        if _self.CurStep == 1 then
            _self.Stage = "Loading";
            alphaAnim = 0;
            return;
        end

        _self:SetStep(_self.CurStep - 1);
    end
    function self.BackButton:Think()
        self:SetHoverColor(Color(200, 200, 200, alphaAnim));
    end

    self.NextButton = vgui.Create("TextButton", self);
    self.NextButton:SetDrawFont("bash-regular-36");
    self.NextButton:SetDrawText("Begin");
    self.NextButton:SetTextColor(colAnim);
    self.NextButton:SetRightAligned(true);
    self.NextButton:SetPos(right - self.NextButton:GetWide(), down - 36);
    function self.NextButton:DoClick()
        if _self.CurStep == #headers then
            colBG = Color(100, 100, 100);
            _self.Stage = "IntroDone"
            _self.BackButton:Remove();
            _self.NextButton:Remove();
            return;
        end

        _self:SetStep(_self.CurStep + 1);
    end
    function self.NextButton:Think()
        self:SetHoverColor(Color(200, 200, 200, alphaAnim));
    end
end

vgui.Register("bash_intro", INTRO, "EditablePanel");
