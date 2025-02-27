-- percentages at which bar should change color
PETHEALTH_YELLOW_TRANSITION = .60
PETHEALTH_RED_TRANSITION = .30

-- table indices of bar colors
PETHEALTH_GREEN_INDEX = 1;
PETHEALTH_YELLOW_INDEX = 2;
PETHEALTH_RED_INDEX = 3;

PETHEALTH_POWER = { {r = 0.52, g = 1.0, b = 0.52}, {r = 1.0, g = 0.98, b = 0.72}, {r = 1.0, g = 0.42, b = 0.42} };

-- Base mixin for pet health bar attached to the player's nameplate (Personal Resources)
PetHealthBarMixin = CreateFromMixins(ClassNameplateAlternatePowerBarBaseMixin);

function PetHealthBarMixin:Initialize()
    self.frequentUpdates = true;
    self.Border:SetVertexColor(0, 0, 0, 1);
    self.Border:SetBorderSizes(nil, nil, 0, 0);

    self.baseMixin.Initialize(self);
end

function PetHealthBarMixin:EvaluateUnit()
    local meetsRequirements = false;

    local _, class = UnitClass(self:GetUnit());
    local spec = GetSpecialization();

    if class == "HUNTER" and (spec == 1 or spec == 3) then
        meetsRequirements = true;
    elseif class == "WARLOCK" then
        meetsRequirements = true;
    -- elseif class == "DEATHKNIGHT" and (spec == 3) then
    --     meetsRequirements = true;
    end

    self.baseMixin.SetBarEnabled(self, meetsRequirements);
end

function PetHealthBarMixin:UpdatePower()
    self:UpdateMinMaxPower();
    self.baseMixin.UpdatePower(self);
    self:UpdateArt();
end

function PetHealthBarMixin:UpdateArt()
    if not self.currentPower or not self.maxPower then
        self.overrideArtInfo = nil;
        self.baseMixin.UpdateArt(self);
        return;
    end

    local percent = self.maxPower > 0 and self.currentPower / self.maxPower or 0;

    if percent <= PETHEALTH_RED_TRANSITION then
        artInfo = PETHEALTH_POWER[PETHEALTH_RED_INDEX];
    elseif percent <= PETHEALTH_YELLOW_TRANSITION then
        artInfo = PETHEALTH_POWER[PETHEALTH_YELLOW_INDEX];
    else
        artInfo = PETHEALTH_POWER[PETHEALTH_GREEN_INDEX];
    end
    self.overrideArtInfo = artInfo;

    self.baseMixin.UpdateArt(self);
end

function PetHealthBarMixin:GetCurrentPower()
    return UnitHealth("pet") or 0;
end

function PetHealthBarMixin:GetCurrentMinMaxPower()
    local maxHealth = UnitHealthMax("pet");
    return 0, maxHealth;
end