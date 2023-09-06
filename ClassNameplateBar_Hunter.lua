ClassNameplateBarHunter = {};

function ClassNameplateBarHunter:Initialize()
	self.Border:SetVertexColor(0, 0, 0, 1);
	self.Border:SetBorderSizes(nil, nil, 0, 0);
	HunterPetHealthBarMixin.Initialize(self);
end