-- Common vgui elements that are shared across many menus.

-- Text button.
local TEXT_BUTTON = {};

function TEXT_BUTTON:Init()
    self:SetText("");
    self.Entered = false;
    self.DrawText = "";
    self.DrawFont = "ChatFont";
    self.TextColor = color_white;
    self.HoverColor = color_con;
    self.DisabledColor = Color(100, 100, 100);
    self.RightAligned = false;
end

function TEXT_BUTTON:PerformLayout(w, h)
    surface.SetFont(self.DrawFont);
    local x, y = surface.GetTextSize(self.DrawText);
    self:SetSize(x, y);
    if self.RightAligned and self.OldW then
        local posX, posY = self:GetPos();
        self:SetPos((posX + self.OldW) - x, posY);
    end
    self.OldW = x;
    self.OldH = y;
end

function TEXT_BUTTON:Paint(w, h)
    draw.SimpleText(
        self.DrawText, self.DrawFont,
        w / 2, h / 2,
        (!self:IsEnabled() and self.DisabledColor) or (self:IsHovered() and self.HoverColor) or self.TextColor,
        TEXT_CENT, TEXT_CENT
    );
end

function TEXT_BUTTON:SetDrawFont(font)
    self.DrawFont = font;
    self:InvalidateLayout();
end

function TEXT_BUTTON:SetDrawText(text)
    self.DrawText = text;
    self:InvalidateLayout();
end

function TEXT_BUTTON:SetTextColor(col)
    self.TextColor = col;
end

function TEXT_BUTTON:SetHoverColor(col)
    self.HoverColor = col;
end

function TEXT_BUTTON:SetDisabledColor(col)
    self.DisabledColor = col;
end

function TEXT_BUTTON:SetRightAligned(align)
    self.RightAligned = align;
end

vgui.Register("TextButton", TEXT_BUTTON, "DButton");

-- Scroll panel.
local SCROLL = {};

function SCROLL:Init()
    self.ScrollingSet = false;

    self.VBar:SetWide(12);
    self.VBar.Paint = function() end
    self.VBar.btnUp.Paint = function() end
    self.VBar.btnDown.Paint = function() end

    self.VBar.btnGrip.HoverAlpha = 255;
    self.VBar.btnGrip.Paint = function(_self, w, h)
        DisableClipping(true);
            draw.RoundedBox(
                6, 0, -(self.VBar.btnUp:GetTall()), w, h + (2 * self.VBar.btnUp:GetTall()),
                Color(0, 0, 0, _self.HoverAlpha)
            );
        DisableClipping(false);
    end
    self.VBar.btnGrip.Think = function(_self)
        local par = _self:GetParent();
        local up = par.btnUp;
        local down = par.btnDown;
        if par.Dragging or _self:IsHovered() or up:IsHovered() or down:IsHovered() then
            _self.HoverAlpha = 255;
        else
            if _self.HoverAlpha < 51 then
                _self.HoverAlpha = 50;
                return;
            end
            _self.HoverAlpha = Lerp(0.03, _self.HoverAlpha, 50);
        end
    end
end

function SCROLL:Paint() end

vgui.Register("ScrollPanel", SCROLL, "DScrollPanel");
