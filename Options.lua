-- Options.lua - Enhanced with smart Pawn integration and user onboarding

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]

function GO:UpdateOptionsPanel()
    if not self.optionsFrame then return end

    local f = self.optionsFrame
    local minimapCheck = _G[addonName .. "MinimapCheck"]
    local soundCheck = _G[addonName .. "SoundCheck"]

    -- Set checkbox states
    minimapCheck:SetChecked(not PawnStarOmegaDB.minimap.hide)
    soundCheck:SetChecked(PawnStarOmegaDB.soundEnabled)

    -- Update Pawn status display
    self:UpdatePawnStatusDisplay()
    self:UpdateStatWeightsPanel()
end

function GO:UpdatePawnStatusDisplay()
    if not self.optionsFrame or not self.optionsFrame.pawnStatus then return end
    
    local statusText = self.optionsFrame.pawnStatus
    local installButton = self.optionsFrame.pawnInstallButton
    
    if self:IsPawnAvailable() then
        statusText:SetText("Pawn Status: |cff00ff00Installed & Active|r")
        installButton:Hide()
        
        -- Show scale count
        local availableScales = self:GetAllAvailablePawnScales()
        local scaleCount = 0
        for _ in pairs(availableScales) do
            scaleCount = scaleCount + 1
        end
        
        if scaleCount > 0 then
            statusText:SetText(statusText:GetText() .. string.format("\n%d stat weight scales available", scaleCount))
        else
            statusText:SetText(statusText:GetText() .. "\nNo scales found - import some scales in Pawn!")
        end
    else
        statusText:SetText("Pawn Status: |cffff6600Not Installed|r\nUsing basic fallback weights")
        installButton:Show()
    end
end

function GO:CreateOptionsPanel()
    if self.optionsFrame then
        return
    end

    local f = CreateFrame("Frame", addonName .. "OptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(450, 400) -- Made slightly larger
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    -- Add Logo only (no arrows for options window)
    f.logo = f:CreateTexture(nil, "ARTWORK")
    f.logo:SetSize(128, 128)
    f.logo:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\PawnStarUpgradeOmegaLogo.tga")
    f.logo:SetPoint("TOP", f, "TOP", 0, -10)
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", f.TitleBg, "TOP", 0, -5)
    f.title:SetText(addonName .. " Options")
    
    self.optionsFrame = f

    -- Pawn Status Section
    local pawnHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pawnHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -160)
    pawnHeader:SetText("Pawn Integration")
    pawnHeader:SetTextColor(1, 0.8, 0.2)
    
    local pawnStatus = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pawnStatus:SetPoint("TOPLEFT", pawnHeader, "BOTTOMLEFT", 5, -10)
    pawnStatus:SetWidth(400)
    pawnStatus:SetJustifyH("LEFT")
    f.pawnStatus = pawnStatus
    
    -- Install Pawn button (initially hidden)
    local pawnInstallButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    pawnInstallButton:SetSize(150, 25)
    pawnInstallButton:SetPoint("TOPLEFT", pawnStatus, "BOTTOMLEFT", 0, -10)
    pawnInstallButton:SetText("Get Pawn Addon")
    pawnInstallButton:SetScript("OnClick", function()
        GO:ShowPawnRecommendation()
    end)
    f.pawnInstallButton = pawnInstallButton

    -- Options Section
    local optionsHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    optionsHeader:SetPoint("TOPLEFT", pawnInstallButton, "BOTTOMLEFT", 0, -30)
    optionsHeader:SetText("Addon Settings")
    optionsHeader:SetTextColor(1, 0.8, 0.2)

    -- Minimap icon checkbox
    local minimapCheck = CreateFrame("CheckButton", addonName .. "MinimapCheck", f, "UICheckButtonTemplate")
    minimapCheck:SetPoint("TOPLEFT", optionsHeader, "BOTTOMLEFT", 5, -15)
    minimapCheck.text = minimapCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    minimapCheck.text:SetPoint("LEFT", minimapCheck, "RIGHT", 5, 0)
    minimapCheck.text:SetText("Show Minimap Icon")
    minimapCheck:SetScript("OnClick", function(self)
        PawnStarOmegaDB.minimap.hide = not self:GetChecked()
        if PawnStarOmegaDB.minimap.hide then
            LibStub("LibDBIcon-1.0"):Hide(addonName)
        else
            LibStub("LibDBIcon-1.0"):Show(addonName)
        end
    end)

    -- Sound effects checkbox - positioned to the right of minimap checkbox
    local soundCheck = CreateFrame("CheckButton", addonName .. "SoundCheck", f, "UICheckButtonTemplate")
    soundCheck:SetPoint("TOPLEFT", minimapCheck, "TOPRIGHT", 180, 0)
    soundCheck.text = soundCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    soundCheck.text:SetPoint("LEFT", soundCheck, "RIGHT", 5, 0)
    soundCheck.text:SetText("Enable Sound Effects")
    soundCheck:SetScript("OnClick", function(self)
        PawnStarOmegaDB.soundEnabled = self:GetChecked()
    end)
    
    -- Information text - moved up to fill the space we just created
    local infoText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 5, -15)
    infoText:SetWidth(390)
    infoText:SetJustifyH("LEFT")
    infoText:SetText("This addon enhances your WoW experience by automatically detecting gear upgrades. " ..
                     "For best results, install Pawn addon and import stat weights from Raidbots.com simulations.")
    infoText:SetTextColor(0.8, 0.8, 0.8)
    
    f:Hide()
    self:CreateStatWeightsPanel()
end

function GO:ToggleOptionsPanel()
    if not self.optionsFrame then
        self:CreateOptionsPanel()
    end

    if self.optionsFrame:IsShown() then
        self.optionsFrame:Hide()
        if self.statWeightsFrame then
            self.statWeightsFrame:Hide()
        end
    else
        self:UpdateOptionsPanel()
        self.optionsFrame:Show()
        if self.statWeightsFrame then
            self.statWeightsFrame:Show()
        end
    end
end