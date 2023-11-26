-- percentages at which bar should change color
PETHEALTH_YELLOW_TRANSITION = .60
PETHEALTH_RED_TRANSITION = .30

-- table indices of bar colors
PETHEALTH_GREEN_INDEX = 1;
PETHEALTH_YELLOW_INDEX = 2;
PETHEALTH_RED_INDEX = 3;

PETHEALTH_POWER = { {r = 0.52, g = 1.0, b = 0.52}, {r = 1.0, g = 0.98, b = 0.72}, {r = 1.0, g = 0.42, b = 0.42} };

HunterPetHealthBarMixin = {};

function HunterPetHealthBarMixin:Initialize()
	self.frequentUpdates = true;
	self.requiredClass = "HUNTER";

	self.baseMixin.Initialize(self);
end

function HunterPetHealthBarMixin:UpdatePower()
	self:UpdateMinMaxPower();
	self.baseMixin.UpdatePower(self);
	self:UpdateArt();
end

function HunterPetHealthBarMixin:UpdateArt()
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

function HunterPetHealthBarMixin:EvaluateUnit()
	local meetsRequirements = false;

	local _, class = UnitClass(self:GetUnit());
	meetsRequirements = class == self.requiredClass;

	self:SetBarEnabled(meetsRequirements);
end

function HunterPetHealthBarMixin:OnBarEnabled()
	self:UpdatePower();
end

function HunterPetHealthBarMixin:GetCurrentPower()
	return UnitHealth("pet") or 0;
end

function HunterPetHealthBarMixin:GetCurrentMinMaxPower()
	local maxHealth = UnitHealthMax("pet");
	return 0, maxHealth;
end