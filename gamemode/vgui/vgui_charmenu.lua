-- vgui element that acts as a landing place.
local CHARMENU = {};
CHARMENU.State = CHARMENU.State or "Landing";
CHARMENU.BGColor = CHARMENU.BGColor or Color(20, 20, 20, 0);
CHARMENU.Alpha = CHARMENU.Alpha or 0;
CHARMENU.SubMenu = CHARMENU.SubMenu or nil;

-- Micro-optimizations.
local cam_End3D, cam_Start3D, _Color, _CurTime, draw_SimpleText, _HSVToColor, _LerpLim, math_Clamp, _RealTime, surface_DrawLine, surface_DrawOutlinedRect, surface_DrawRect, surface_DrawTexturedRect, surface_DrawTexturedRectUV, surface_SetDrawColor, surface_SetMaterial = cam.End3D, cam.Start3D, Color, CurTime, draw.SimpleText, HSVToColor, LerpLim, math.Clamp, RealTime, surface.DrawLine, surface.DrawOutlinedRect, surface.DrawRect, surface.DrawTexturedRect, surface.DrawTexturedRectUV, surface.SetDrawColor, surface.SetMaterial;

-- Materials.
local gradH = getMaterial("gui/gradient");
local gradV = getMaterial("gui/gradient_down");

function CHARMENU:Init()
    self:SetPos(0, 0);
    self:SetSize(SCRW, SCRH);
    self.State = self.State or "Landing";
    self.BGColor.a = self.BGColor.a or 0;
    self.Alpha = self.Alpha or 0;

    gui.EnableScreenClicker(true);
    self:CreateMenu();
    self:CreateViewport();
end

function CHARMENU:Paint(w, h)
    if self.State == "Entering" then

    else
        self.BGColor.a = _LerpLim(0.02, self.BGColor.a, 240, 1);
        self.Alpha = _LerpLim(0.02, self.Alpha, 255, 1);
    end

    surface_SetDrawColor(self.BGColor);
    surface_DrawRect(0, 0, w, h);
end

function CHARMENU:CreateMenu()
    if checkpanel(self.SubMenu) then
        self.SubMenu:Remove();
        self.SubMenu = nil;
    end

    self.SubMenu = vgui.Create("EditablePanel", self);
    self.SubMenu:SetPos((SCRW * 0.015), (SCRW * 0.015));
    self.SubMenu:SetSize(SCRW * 0.25, 1);
    self.SubMenu.PerformLayout = function(_self, w, h)
        -- Don't mess with the submenu when we've moved the buttons!
        if self.State == "Creating" then return; end

        local height = 0;
        if checkpanel(_self.Header) then
            _self.Header:SetPos(0, 0);
            height = height + _self.Header:GetTall();
        end
        if checkpanel(_self.CharHeader) then
            _self.CharHeader:SetPos(0, height);
            height = height + _self.CharHeader:GetTall();
        end
        if _self.CharButtons then
            for _, button in ipairs(_self.CharButtons) do
                if checkpanel(button) then
                    button:SetPos(0, height);
                    height = height + button:GetTall();
                end
            end
        end
        if checkpanel(_self.CreateChar) then
            _self.CreateChar:SetPos(0, height);
            height = height + _self.CreateChar:GetTall();
        end
        if checkpanel(_self.CloseButton) then
            _self.CloseButton:SetPos(0, height);
            height = height + _self.CloseButton:GetTall();
        end
        if checkpanel(_self.Disconnect) then
            _self.Disconnect:SetPos(0, height);
            height = height + _self.Disconnect:GetTall();
        end
        if checkpanel(_self.BackButton) then
            _self.BackButton:SetPos(0, 0);
        end

        _self:SetTall(height);
    end
    self.SubMenu.Paint = function() end

    local sub = self.SubMenu;
    local width = sub:GetWide();
    sub.Header = vgui.Create("EditablePanel", sub);
    sub.Header:SetSize(width, SCRH * 0.1);
    sub.Header.Paint = function(_self, w, h)
        surface_SetDrawColor(_Color(0, 0, 0, self.Alpha));
        surface_DrawRect(0, 0, w, h);

        local time = _CurTime() * 10;
        local colorL = _HSVToColor(time % 360, 0.5, 0.5);
        local colorT = _HSVToColor((time + 30) % 360, 0.5, 0.5);
        local colorR = _HSVToColor((time + 60) % 360, 0.5, 0.5);
        local colorB = _HSVToColor((time + 90) % 360, 0.5, 0.5);
        colorL.a = self.Alpha;
        colorT.a = self.Alpha;
        colorR.a = self.Alpha;
        colorB.a = self.Alpha;

        surface_SetMaterial(gradH);
        surface_SetDrawColor(colorL);
        surface_DrawTexturedRect(1, 1, w - 2, h - 2);

        surface_SetMaterial(gradH);
        surface_SetDrawColor(colorR);
        surface_DrawTexturedRectUV(1, 1, w - 2, h - 2, 1, 0, 0, 1);

        surface_SetMaterial(gradV);
        surface_SetDrawColor(colorT);
        surface_DrawTexturedRect(1, 1, w - 2, h - 2);

        surface_SetMaterial(gradV);
        surface_SetDrawColor(colorB);
        surface_DrawTexturedRectUV(1, 1, w - 2, h - 2, 0, 1, 1, 0);

        draw_SimpleText(
            (SCHEMA and SCHEMA.Name) or "/bash/",
            "bash-light-24", w / 2, h / 2,
            _Color(255, 255, 255, self.Alpha),
            TEXT_CENT, TEXT_CENT
        );
    end

    sub.CharHeader = vgui.Create("EditablePanel", sub);
    local charHeader = sub.CharHeader;
    charHeader:SetSize(width, 28)
    charHeader.Paint = function(_self, w, h)
        surface_SetDrawColor(_Color(0, 0, 0, self.Alpha));
        surface_DrawRect(0, 0, w, h);

        local time = _CurTime() * 10;
        local col = _HSVToColor((time + 90) % 360, 0.5, 0.5);
        col.a = self.Alpha;
        draw_SimpleText(
            "Characters",
            "bash-regular-24", 6, h / 2,
            col,
            TEXT_LEFT, TEXT_CENT
        );
    end

    sub.CreateChar = vgui.Create("DButton", sub);
    local createChar = sub.CreateChar;
    createChar:SetSize(width, 28);
    createChar:SetText("");
    createChar.Paint = function(_self, w, h)
        local time = _CurTime() * 10;
        local col = _HSVToColor((time + 90) % 360, 0.5, 0.5);
        col.a = self.BGColor.a;
        if _self:IsHovered() then
            col.r = col.r + 30;
            col.g = col.g + 30;
            col.b = col.b + 30;
        end
        surface_SetDrawColor(col);
        surface_DrawRect(0, 0, w, h);

        draw_SimpleText(
            "Create Character",
            "bash-regular-24", 6, h / 2,
            (_self:IsHovered() and _Color(200, 200, 200, self.Alpha)) or _Color(255, 255, 255, self.Alpha),
            TEXT_LEFT, TEXT_CENT
        );

        surface_SetDrawColor(_Color(0, 0, 0, self.BGColor.a));
        surface_DrawOutlinedRect(0, 0, w, h);
    end
    createChar.DoClick = function(_self)
        if checkpanel(self.Viewport) then
            if checkpanel(self.Viewport.DeleteButton) then
                self.Viewport.DeleteButton:SetVisible(false);
            end
            if checkpanel(self.Viewport.LoadButton) then
                self.Viewport.LoadButton:SetVisible(false);
            end
            self.Viewport:SetVisible(false);
        end

        self.State = "Creating";
        self:HideSubButtons();
        self:CreateOutfitter();
    end

    local status = LocalPlayer():GetNetVar("Status");
    if status == STATUS_ACTIVE then
        sub.CloseButton = vgui.Create("DButton", sub);
        local close = sub.CloseButton;
        close:SetSize(width, 28);
        close:SetText("");
        close.Paint = function(_self, w, h)
            local time = _CurTime() * 10;
            local col = _HSVToColor((time + 90) % 360, 0.5, 0.5);
            col.a = self.BGColor.a;
            if _self:IsHovered() then
                col.r = col.r + 30;
                col.g = col.g + 30;
                col.b = col.b + 30;
            end
            surface_SetDrawColor(col);
            surface_DrawRect(0, 0, w, h);

            draw.SimpleText(
                "Close",
                "bash-regular-24", 6, h / 2,
                (_self:IsHovered() and _Color(200, 200, 200, self.Alpha)) or _Color(255, 255, 255, self.Alpha),
                TEXT_LEFT, TEXT_CENT
            );

            surface_SetDrawColor(_Color(0, 0, 0, self.BGColor.a));
            surface_DrawOutlinedRect(0, -1, w, h + 1);
        end
        close.DoClick = function(_self)
            self:Remove();
        end
    end

    sub.Disconnect = vgui.Create("DButton", sub);
    local disconnect = sub.Disconnect;
    disconnect:SetSize(width, 28);
    disconnect:SetText("");
    disconnect.Paint = function(_self, w, h)
        local time = _CurTime() * 10;
        local col = _HSVToColor((time + 90) % 360, 0.5, 0.5);
        col.a = self.BGColor.a;
        if _self:IsHovered() then
            col.r = col.r + 30;
            col.g = col.g + 30;
            col.b = col.b + 30;
        end
        surface_SetDrawColor(col);
        surface_DrawRect(0, 0, w, h);

        draw_SimpleText(
            "Disconnect",
            "bash-regular-24", 6, h / 2,
            (_self:IsHovered() and _Color(200, 200, 200, self.Alpha)) or _Color(255, 255, 255, self.Alpha),
            TEXT_LEFT, TEXT_CENT
        );

        surface_SetDrawColor(_Color(0, 0, 0, self.BGColor.a));
        surface_DrawOutlinedRect(0, -1, w, h + 1);
    end
    disconnect.DoClick = function(_self)
        RunConsoleCommand("disconnect");
    end

    sub.BackButton = vgui.Create("DButton", sub);
    local back = sub.BackButton;
    back:SetVisible(false);
    back:SetSize(width, 28);
    back:SetText("");
    back.Paint = function(_self, w, h)
        local time = _CurTime() * 10;
        local col = _HSVToColor((time + 90) % 360, 0.5, 0.5);
        col.a = self.BGColor.a;
        if _self:IsHovered() then
            col.r = col.r + 30;
            col.g = col.g + 30;
            col.b = col.b + 30;
        end
        surface_SetDrawColor(col);
        surface_DrawRect(0, 0, w, h);

        draw_SimpleText(
            "Back",
            "bash-regular-24", 6, h / 2,
            (_self:IsHovered() and _Color(200, 200, 200, self.Alpha)) or _Color(255, 255, 255, self.Alpha),
            TEXT_LEFT, TEXT_CENT
        );

        surface_SetDrawColor(_Color(0, 0, 0, self.BGColor.a));
        surface_DrawOutlinedRect(0, 0, w, h);
    end
    back.DoClick = function(_self)
        if checkpanel(self.Viewport) then
            self.Viewport:SetChar(0, {});
            self.Viewport:SetVisible(true);
        end
        if checkpanel(self.Outfitter) then
            self.Outfitter:SetVisible(false);
        end

        self:ShowSubButtons(function()
            self.State = "Landing";
        end);
    end

    sub:InvalidateLayout();
    self:UpdateCharacters();
end

function CHARMENU:CreateViewport()
    if checkpanel(self.Viewport) then
        self.Viewport:Remove();
        self.Viewport = nil;
    end

    self.Viewport = vgui.Create("EditablePanel", self);
    local port = self.Viewport;
    port:SetSize(SCRW * 0.7, SCRH * 0.7);
    port:SetPos(SCRW - port:GetWide() - (SCRW * 0.015), (SCRW * 0.015));
    port.CurScene = nil;

    port.SetChar = function(_self, index, data)
        _self.CharData = data;
        local override = hook.Call("ChooseCharScene", nil, data);
        if override then
            _self.CurScene = bash.charmenu.loadScene(override, index, data.BaseModel);
        else
            _self.CurScene = bash.charmenu.loadRandScene(index, data.BaseModel);
        end
    end

    local last;
    local speed = 0.5;
    port.Paint = function(_self, w, h)
        if !_self.CurScene then return; end

        draw_SimpleText(
            _self.CharData.CharName, "bash-regular-36",
            w / 2, 6, _Color(200, 200, 200), TEXT_CENT, TEXT_TOP
        );

        last = last or _RealTime();
        local x, y = _self:LocalToScreen(0, 0);
        cam_Start3D(
            _self.CurScene.CamData.Pos,
            _self.CurScene.CamData.Ang,
            _self.CurScene.CamData.FOV,
            x, y, w, h);

            for _, ent in pairs(_self.CurScene.Props) do
                ent:SetupBones();
                ent:DrawModel();
                ent:FrameAdvance((RealTime() - last) * speed);
                if ent.Think then
                    ent:Think();
                end
            end
        cam_End3D();
        last = _RealTime();

        surface_SetDrawColor(_Color(200, 200, 200));
        surface_DrawOutlinedRect(0, 0, w, h);
    end

    local portX, portY = port:GetPos();
    self.Viewport.DeleteButton = vgui.Create("TextButton", self);
    local del = self.Viewport.DeleteButton;
    del:SetVisible(false);
    del:SetDrawFont("bash-regular-36");
    del:SetDrawText("Delete");
    del:SetPos(portX + 6, portY + port:GetTall() + 6);
    del.Think = function(_self)
        _self:SetTextColor(_Color(255, 255, 255, self.Alpha));
        _self:SetHoverColor(_Color(200, 200, 200, self.Alpha));
        _self:SetDisabledColor(_Color(100, 100, 100, self.Alpha));
    end
    del.SetChar = function(_self, id)
        if !id then _self:SetEnabled(false); return; end
        _self.CharID = id;
    end
    del.DoClick = function(_self)
        MsgN("Deleting char: " .. (_self.CharID or "nil"));
    end

    self.Viewport.LoadButton = vgui.Create("TextButton", self);
    local load = self.Viewport.LoadButton;
    load:SetVisible(false);
    load:SetDrawFont("bash-regular-36");
    load:SetDrawText("Load");
    load:SetPos(portX + port:GetWide() - load:GetWide() - 6, portY + port:GetTall() + 6);
    load:SetRightAligned(true);
    load.Think = function(_self)
        _self:SetTextColor(_Color(255, 255, 255, self.Alpha));
        _self:SetHoverColor(_Color(200, 200, 200, self.Alpha));
        _self:SetDisabledColor(_Color(100, 100, 100, self.Alpha));
    end
    load.SetChar = function(_self, id)
        if !id then _self:SetEnabled(false); return; end
        _self.CharID = id;
    end
    load.DoClick = function(_self)
        MsgN("Loading char: " .. (_self.CharID or "nil"));
    end
end

function CHARMENU:CreateOutfitter()
    if checkpanel(self.Outfitter) then
        self.Outfitter.SampleModel:Remove();
        self.Outfitter:Remove();
        self.Outfitter = nil;
    end

    self.Outfitter = vgui.Create("EditablePanel", self);
    local outfit = self.Outfitter;
    outfit:SetSize(SCRW * 0.7, SCRH * 0.7);
    outfit:SetPos(SCRW - outfit:GetWide() - (SCRW * 0.015), (SCRW * 0.015));
    outfit.CharData = {};

    outfit.Stages = {"Gender", "Appearance", "Identity", "Alignment", "Traits"};
    outfit.CurStage = 0;
    outfit.SetStage = function(_self, stage)
        _self.CurStage = stage;

        if stage == 1 then

        elseif stage == #_self.Stages then

        end
    end
    outfit.Paint = function(_self, w, h)
        --[[
        draw.SimpleText(
            _self.CharData.CharName or "New Character", "bash-regular-36",
            w / 2, 6, Color(200, 200, 200), TEXT_CENT, TEXT_TOP
        );

        draw.SimpleText(
            "Drag to rotate model.", "bash-regular-24",
            w / 2, h - 6, Color(200, 200, 200), TEXT_CENT, TEXT_BOT
        );

        if !_self.CharData.Model then
            --_self.SampleModel:SetMaterial(getMaterial("models/shadertest/shader4"));
        end

        last = last or RealTime();
        local x, y = _self:LocalToScreen(0, 0);
        cam.Start3D(Vector(0, 0, 40), Angle(0, 0, 0), 90, x, y, w, h);
            _self.SampleModel:SetupBones();
            _self.SampleModel:DrawModel();
            _self.SampleModel:FrameAdvance((RealTime() - last) * speed);
        cam.End3D();
        last = RealTime();
        ]]

        surface.SetDrawColor(Color(200, 200, 200));
        surface.DrawOutlinedRect(0, 0, w, h);
    end

    outfit.SampleModel = ClientsideModel("models/humans/group01/male_01.mdl");
    outfit.SampleModel:SetNoDraw(true);
    outfit.SampleModel:SetColor(Color(0, 0, 0));
    outfit.SampleModel:SetPos(Vector(120, 0, 0));
    outfit.SampleModel:SetAngles(Angle(0, 180, 0));
    local seq = outfit.SampleModel:LookupSequence("walk_all");
    outfit.SampleModel:SetSequence(seq);

    self.Outfitter.StageDisplay = vgui.Create("EditablePanel", outfit);
    local stager = self.Outfitter.StageDisplay;
    stager:SetPos(1, 1);
    stager:SetSize(outfit:GetWide() - 2, (outfit:GetTall() * 0.25) - 2);
    stager.Paint = function(_self, w, h)
        -- Draw area for boxes.
        local stages = _self:GetParent().Stages;
        local areaH = h * 0.7;
        local boxSize = areaH;
        local margin = (w - (boxSize * #stages)) / (#stages + 1);
        local areaX = margin;
        local areaY = h * 0.15;
        for index, stage in ipairs(_self:GetParent().Stages) do
            draw_RoundedBox(8, areaX, areaY, boxSize, boxSize, _Color(40 * index, 255, 255));
            areaX = areaX + boxSize + margin;
        end

        surface_SetDrawColor(_Color(200, 200, 200));
        surface_DrawLine(0, h - 1, w - 1, h - 1);
    end

    --[[
    outfit.OnMousePressed = function(_self, code)
        _self.Rotating = (code == MOUSE_LEFT);
        local x, y = _self:CursorPos();
        _self.LastX = x;
        _self.LastY = y;
    end
    outfit.OnMouseReleased = function(_self)
        _self.Rotating = false;
    end
    outfit.Think = function(_self)
        if !_self.Rotating then return; end
        if _self.Rotating and !input.IsMouseDown(MOUSE_LEFT) then
            _self.Rotating = false;
            return;
        end

        local x, y = _self:CursorPos();
        _self.LastX = _self.LastX or x;
        _self.LastY = _self.LastY or y;
        if _self.LastX == x and _self.LastY == y then return; end

        local ang = _self.SampleModel:GetAngles();
        local diffX = _self.LastX - x;
        --local diffY = _self.LastY - y;
        local scaleX = (diffX / (_self:GetWide() / 2));
        --local scaleY = (diffY / (_self:GetTall() / 2));
        --ang.z = ang.z + (5 * scaleY);
        ang.y = ang.y - (6 * scaleX);
        _self.SampleModel:SetAngles(ang);
    end

    local outX, outY = outfit:GetPos();
    self.Outfitter.CreateButton = vgui.Create("TextButton", self);
    local create = self.Outfitter.CreateButton;
    create:SetEnabled(false);
    create:SetDrawFont("bash-regular-36");
    create:SetDrawText("Create");
    create:SetPos(outX + (outfit:GetWide() / 2) - (create:GetWide() / 2), outY + outfit:GetTall() + 6);
    create.Think = function(_self)
        _self:SetTextColor(Color(255, 255, 255, self.Alpha));
        _self:SetHoverColor(Color(200, 200, 200, self.Alpha));
        _self:SetDisabledColor(Color(100, 100, 100, self.Alpha));
    end
    create.DoClick = function(_self)
        MsgN("Creating new char!!!");
    end

    --self.Outfitter.BasicInfo = vgui.Create();
    ]]
end

function CHARMENU:UpdateCharacters()
    local sub = self.SubMenu;
    local width = sub:GetWide();
    sub.CharButtons = sub.CharButtons or {};
    for index, button in pairs(sub.CharButtons) do
        button:Remove();
    end
    sub.CharButtons = {};

    local chars = LocalPlayer():GetNetVar("CharData");
    chars = chars or {};
    local button;
    if #chars == 0 then
        sub.CharButtons[1] = vgui.Create("EditablePanel", sub);
        button = sub.CharButtons[#sub.CharButtons];
        button:SetSize(width, 28);
        button.Paint = function(_self, w, h)
            surface_SetDrawColor(_Color(0, 0, 0, math_Clamp(self.BGColor.a - 50, 0, 255)));
            surface_DrawRect(0, 0, w, h);
            draw_SimpleText(
                "None.",
                "bash-regular-24", 6, h / 2,
                _Color(255, 255, 255, self.Alpha),
                TEXT_LEFT, TEXT_CENT
            );
        end
    else
        for index, char in ipairs(chars) do
            sub.CharButtons[#sub.CharButtons + 1] = vgui.Create("DButton", sub);
            button = sub.CharButtons[#sub.CharButtons];
            button:SetSize(width, 28);
            button:SetText("");
            button.Index = index;
            button.CharData = char;
            button.Paint = function(_self, w, h)
                if _self:IsHovered() then
                    surface_SetDrawColor(_Color(30, 30, 30, math_Clamp(self.BGColor.a - 50, 0, 255)));
                else
                    surface_SetDrawColor(_Color(0, 0, 0, math_Clamp(self.BGColor.a - 50, 0, 255)));
                end

                surface_DrawRect(0, 0, w, h);
                draw_SimpleText(
                    (_self.CharData and _self.CharData.CharName) or "...",
                    "bash-regular-24", 6, h / 2,
                    (_self:IsHovered() and _Color(200, 200, 200, self.Alpha)) or _Color(255, 255, 255, self.Alpha),
                    TEXT_LEFT, TEXT_CENT
                );
            end
            button.DoClick = function(_self)
                if checkpanel(self.Viewport) and _self.CharData then
                    local char = LocalPlayer():GetCharacter();

                    if checkpanel(self.Viewport.DeleteButton) then
                        self.Viewport.DeleteButton:SetVisible(true);
                        self.Viewport.DeleteButton:SetChar(_self.CharData.CharID);
                        self.Viewport.DeleteButton:SetEnabled(!char or char:GetID() != _self.CharData.CharID);
                    end
                    if checkpanel(self.Viewport.LoadButton) then
                        self.Viewport.LoadButton:SetVisible(true);
                        self.Viewport.LoadButton:SetChar(_self.CharData.CharID);
                        self.Viewport.LoadButton:SetEnabled(!char or char:GetID() != _self.CharData.CharID);
                    end
                    self.Viewport:SetChar(_self.Index, _self.CharData);
                end
            end
        end
    end

    sub:InvalidateLayout();
end

function CHARMENU:HideSubButtons(callback)
    self.State = "Creating";
    local sub = self.SubMenu;

    sub.CharHeader:SetEnabled(false);
    sub.CharHeader:MoveTo(0, 0, 1);

    for index, button in ipairs(sub.CharButtons) do
        button:SetEnabled(false);
        button:MoveTo(0, 0, 1);
    end

    sub.CreateChar:SetEnabled(false);
    sub.CreateChar:MoveTo(0, 0, 1);

    if checkpanel(sub.CloseButton) then
        sub.CloseButton:SetEnabled(false);
        sub.CloseButton:MoveTo(0, 0, 1);
    end

    sub.Disconnect:SetEnabled(false);
    sub.Disconnect:MoveTo(0, 0, 1);

    sub.Header:MoveToFront();

    sub.BackButton:SetVisible(true);
    sub.BackButton:MoveTo(0, sub.Header:GetTall(), 1.25, 0, -1, function(data, pnl)
        pnl:SetEnabled(true);

        if callback then
            callback();
        end
    end);
end

function CHARMENU:ShowSubButtons(callback)
    local sub = self.SubMenu;
    local height = sub.Header:GetTall();

    sub.CharHeader:MoveTo(0, height, 1, 0, -1, function(data, pnl)
        pnl:SetEnabled(true);
    end);
    height = height + sub.CharHeader:GetTall();

    for index, button in pairs(sub.CharButtons) do
        button:MoveTo(0, height, 1, 0, -1, function(data, pnl)
            pnl:SetEnabled(true);
        end);
        height = height + button:GetTall();
    end

    sub.CreateChar:MoveTo(0, height, 1, 0, -1, function(data, pnl)
        pnl:SetEnabled(true);
    end);
    height = height + sub.CreateChar:GetTall();

    if checkpanel(sub.CloseButton) then
        sub.CloseButton:MoveTo(0, height, 1, 0, -1, function(data, pnl)
            pnl:SetEnabled(true);
        end);
        height = height + sub.CloseButton:GetTall();
    end

    sub.Disconnect:MoveTo(0, height, 1, 0, -1, function(data, pnl)
        pnl:SetEnabled(true);
    end);

    sub.BackButton:SetEnabled(false);
    sub.BackButton:MoveTo(0, 0, 1, 0, -1, function(data, pnl)
        pnl:SetVisible(false);

        if callback then
            callback();
        end
    end);
end

vgui.Register("bash_charmenu", CHARMENU, "EditablePanel");
