-- Library for handling all things related to the character menu.
bash.charmenu = bash.charmenu or {};
bash.charmenu.obj = bash.charmenu.obj or nil;
bash.charmenu.vars = bash.charmenu.vars or {};
bash.charmenu.scenes = bash.charmenu.scenes or {};
bash.charmenu.loadedScenes = bash.charmenu.loadedScenes or {};

-- Micro-optimizations.
local _FrameTime = FrameTime;

function bash.charmenu.open()
    if checkpanel(bash.charmenu.obj) and bash.charmenu:IsVisible() then return; end

    MsgDebug("Opening character menu...");
    bash.charmenu.obj = vgui.Create("bash_charmenu");
end

function bash.charmenu.close()
    if !checkpanel(bash.charmenu.obj) then return; end

    MsgDebug("Closing character menu...");
    bash.charmenu.unload();
    bash.charmenu.obj:Remove();
    bash.charmenu.obj = nil;
end

--[[
function bash.charmenu.addVar(varData)
    if !varData or !varData.ID then return; end
    if bash.charmenu.vars[varData.ID] then
        MsgErr("[bash.charmenu.addVar] -> A character variable with the ID '%s' already exists!", varData.ID);
        return;
    end

    varData.ID = varData.ID;
    varData.Title = varData.Title or "Variable Name";
    varData.Subtitle = varData.Subtitle or "Variable description.";
    varData.CreateElement = varData.CreateElement or function(_self, panel) end
    varData.GetValue = varData.GetValue or function(_self,)
end
]]

function bash.charmenu.addScene(sceneData)
    if !sceneData or !sceneData.ID then return; end
    if bash.charmenu.scenes[sceneData.ID] then
        MsgErr("[bash.charmenu.addScene] -> A character scene with the ID '%s' already exists!", sceneData.ID);
        return;
    end

    sceneData.ID = sceneData.ID;
    sceneData.Setup = sceneData.Setup or function(_self) end
    sceneData.Think = sceneData.Think or function(_self) end

    sceneData.CamData = sceneData.CamData or {};
    sceneData.CamData.Pos = sceneData.CamData.Pos or Vector();
    sceneData.CamData.Ang = sceneData.CamData.Ang or Angle();
    sceneData.CamData.FOV = sceneData.CamData.FOV or 90;

    sceneData.TextData = sceneData.TextData or {};
    sceneData.TextData.Pos = sceneData.TextData.Pos or Vector();
    sceneData.TextData.Ang = sceneData.TextData.Ang or Angle();

    sceneData.AddProp = function(_self, model, pos, ang, seq)
        if !model or !pos or !ang then return; end
        local ent = ClientsideModel(model);
        ent:SetPos(pos);
        ent:SetAngles(ang);
        if seq then
            seq = ent:LookupSequence(seq);
            ent:SetSequence(seq);
        end
        ent:SetNoDraw(true);

        _self.Props[#_self.Props + 1] = ent;
        return ent;
    end

    bash.charmenu.scenes[sceneData.ID] = sceneData;
    MsgDebug("Character scene registered with ID '%s'.", sceneData.ID);
end

function bash.charmenu.removeScene(id)
    if !id then return; end

    MsgDebug("Removing character scene with ID '%s'...", id);
    bash.charmenu.scenes[id] = nil;
end

function bash.charmenu.loadScene(id, index, model)
    if !id or !index or !model then return; end
    if !bash.charmenu.scenes[id] then return; end
    if bash.charmenu.loadedScenes[index] then return bash.charmenu.loadedScenes[index]; end

    -- Sloppy shallow copy!
    local sceneStruct = bash.charmenu.scenes[id];
    local newScene = {};
    newScene.Props = {};
    newScene.CamData = sceneStruct.CamData;
    newScene.TextData = sceneStruct.TextData;
    newScene.CharModel = model;
    newScene.Think = sceneStruct.Think;
    newScene.AddProp = sceneStruct.AddProp;
    newScene.Setup = sceneStruct.Setup;
    newScene:Setup();
    bash.charmenu.loadedScenes[index] = newScene;
    return newScene;
end

function bash.charmenu.loadRandScene(index, model)
    if !index or !model then return; end
    if bash.charmenu.loadedScenes[index] then return bash.charmenu.loadedScenes[index]; end

    local keys = {};
    for key, _ in pairs(bash.charmenu.scenes) do
        keys[#keys + 1] = key;
    end

    local id = keys[math.random(#keys)];
    -- Sloppy shallow copy!
    local sceneStruct = bash.charmenu.scenes[id];
    local newScene = {};
    newScene.Props = {};
    newScene.CamData = sceneStruct.CamData;
    newScene.TextData = sceneStruct.TextData;
    newScene.CharModel = model;
    newScene.Think = sceneStruct.Think;
    newScene.AddProp = sceneStruct.AddProp;
    newScene.Setup = sceneStruct.Setup;
    newScene:Setup();
    bash.charmenu.loadedScenes[index] = newScene;
    return newScene;
end

function bash.charmenu.unload()
    local num = 0;
    MsgDebug("Removing all character scene entities...");
    for _, scene in pairs(bash.charmenu.loadedScenes) do
        for __, ent in pairs(scene.Props) do
            ent:Remove();
            num = num + 1;
        end
    end
    MsgDebug("Removed %d character scene entities.", num);

    if bash.charmenu.loadedScenes != {} then
        MsgDebug("Dropping loaded character scenes...");
        bash.charmenu.loadedScenes = {};
    end
end

-- Local function for dropping all scenes (on refresh).
local function dropScenes()
    if bash.charmenu.scenes != {} then
        MsgDebug("Dropping scenes...");
        bash.charmenu.scenes = {};
    end
    if bash.charmenu.loadedScenes != {} then
        MsgDebug("Dropping loaded scenes...");
        bash.charmenu.loadedScenes = {};
    end
end

-- Local function for generating random citizen models (for default scenes).
local function randomModel()
    local groups = {"01", "02", "03", "03m"};
    local gender = math.random();
    if gender > 0.5 then
        local num = 0;
        while num == 0 or num == 5 do
            num = math.random(7);
        end
        return "models/Humans/Group" .. table.Random(groups) .. "/Female_0" .. num .. ".mdl";
    else
        local num = math.random(9);
        return "models/Humans/Group" .. table.Random(groups) .. "/Male_0" .. num .. ".mdl";
    end
end

-- For server refreshes.
dropScenes();

-- Add default scenes.
bash.charmenu.addScene{
    ID = "default01",
    CamData = {
        Pos = Vector(0, -20, 40),
        Ang = Angle(10, 10, 0),
        FOV = 90
    },
    TextData = {
        Pos = Vector(70, 0, 40),
        Ang = Angle()
    },

    Setup = function(_self)
        -- Character
        _self:AddProp(
            _self.CharModel,
            Vector(70, 0, 0),
            Angle(0, 180, 0),
            "plazaidle4"
        );

        -- Walker 1
        local walk01 = _self:AddProp(
            randomModel(),
            Vector(20, 200, 0),
            Angle(0, 270, 0),
            "walk_all"
        );
        walk01.Think = function(_self)
            local curPos = _self:GetPos();
            if curPos.y < -200 then
                curPos.y = 200;
            else
                curPos.y = curPos.y - (_FrameTime() * 100);
            end
            _self:SetPos(curPos);
        end

        -- Walker 2
        local walk02 = _self:AddProp(
            randomModel(),
            Vector(50, -100, 0),
            Angle(0, 90, 0),
            "walk_all"
        );
        walk02.Think = function(_self)
            local curPos = _self:GetPos();
            if curPos.y > 175 then
                curPos.y = -100;
            else
                curPos.y = curPos.y + (_FrameTime() * 100);
            end
            _self:SetPos(curPos);
        end

        -- Walker 3
        local walk03 = _self:AddProp(
            randomModel(),
            Vector(40, -1000, 0),
            Angle(0, 90, 0),
            "run_all"
        );
        walk03.Think = function(_self)
            local curPos = _self:GetPos();
            if curPos.y > 1500 then
                curPos.y = -100;
            else
                curPos.y = curPos.y + (_FrameTime() * 300);
            end
            _self:SetPos(curPos);
        end

        -- Sitter 1
        _self:AddProp(
            randomModel(),
            Vector(90, 60, 0),
            Angle(0, 150, 0),
            "Sit_Chair"
        );

        -- Chair
        _self:AddProp(
            "models/props_c17/FurnitureChair001a.mdl",
            Vector(102, 47, 22),
            Angle(0, 150, 0)
        );

        -- Talker 1
        _self:AddProp(
            randomModel(),
            Vector(90, -30, 0),
            Angle(0, 270, 0),
            "LineIdle02"
        );

        -- Talker 2
        _self:AddProp(
            randomModel(),
            Vector(90, -60, 0),
            Angle(0, 90, 0),
            "LineIdle03"
        );
    end
};


bash.charmenu.addScene{
    ID = "default02",
    CamData = {
        Pos = Vector(40, -40, 60),
        Ang = Angle(20, 55, 0),
        FOV = 90
    },
    TextData = {
        Pos = Vector(70, 40, 7),
        Ang = Angle(0, 180, 0)
    },

    Setup = function(_self)
        -- Character
        _self:AddProp(
            _self.CharModel,
            Vector(80, 0, 0),
            Angle(0, 180, 0),
            "canals_arlene_tinker"
        );

        -- Table
        _self:AddProp(
            "models/props_wasteland/controlroom_desk001a.mdl",
            Vector(55, 0, 20),
            Angle()
        );

        -- Hula
        _self:AddProp(
            "models/props_lab/huladoll.mdl",
            Vector(55, 20, 37),
            Angle(0, 300, 0)
        );

        -- Printer
        _self:AddProp(
            "models/props_lab/plotter.mdl",
            Vector(70, 40, 7),
            Angle(0, 180, 0)
        );

        -- Crossbow
        _self:AddProp(
            "models/weapons/w_crossbow.mdl",
            Vector(40, -10, 39),
            Angle(5, -45, -10)
        );

        -- Wrench
        _self:AddProp(
            "models/props_c17/tools_wrench01a.mdl",
            Vector(60, 10, 37),
            Angle(0, 135, 0)
        );

        -- Grenade
        _self:AddProp(
            "models/Items/combine_rifle_ammo01.mdl",
            Vector(64, 0, 43),
            Angle(0, 0, 180)
        );
    end
};
