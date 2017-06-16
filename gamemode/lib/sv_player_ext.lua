-- Extensions for the Player class.
local Player = FindMetaTable("Player");

function Player:Initialize()
    if !checkply(self) then return; end

    self:SetTeam(TEAM_SPECTATOR);
    self:StripWeapons();
    self:StripAmmo();
    self:Spectate(OBS_MODE_ROAMING);
    self:SetMoveType(MOVETYPE_NOCLIP);
    self:Freeze(true);
end
