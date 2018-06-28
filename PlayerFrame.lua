local myFrame = CreateFrame("MyFrame")
myFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

myFrame:SetScript("OnEvent", function(self, event, ...)
    if event == 'PLAYER_ENTERING_WORLD' then
        PlayerFrameTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare")
    end
end)