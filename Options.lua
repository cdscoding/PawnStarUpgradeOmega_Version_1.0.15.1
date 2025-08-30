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
    f.title:SetText(addonName .. " Version 1.0")
    
    self.optionsFrame = f

    -- Pawn Status Section
    local pawnHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pawnHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -160)
    pawnHeader:SetText("Pawn Integration")
    pawnHeader:SetTextColor(1, 0.8, 0.2)
    
    local pawnStatus = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pawnStatus:SetPoint("TOPLEFT", pawnHeader, "BOTTOMLEFT", 5, -10)
    pawnStatus:SetWidth(220) -- Reduced width to make space for the button
    pawnStatus:SetJustifyH("LEFT")
    f.pawnStatus = pawnStatus
    
    -- Support and Community Button
    local communityButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    communityButton:SetSize(160, 25)
    communityButton:SetPoint("LEFT", pawnStatus, "RIGHT", 20, 0)
    communityButton:SetText("Support & Community")
    communityButton:SetScript("OnClick", function()
        GO:ShowSupportWindow()
    end)

    -- New Delete Saved Variables Button
    local deleteButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    deleteButton:SetSize(160, 25)
    deleteButton:SetPoint("TOP", communityButton, "BOTTOM", 0, -5)
    deleteButton:SetText("Reset Addon Data")
    deleteButton:SetScript("OnClick", function()
        GO:RequestWipeConfirmation()
    end)

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
    self:CreateWipeConfirmationDialog()
end

function GO:CreateWipeConfirmationDialog()
    StaticPopupDialogs[addonName .. "_WIPE_CONFIRM"] = {
        text = "Are you sure you want to delete all saved data for " .. addonName .. "? This cannot be undone and will reset all settings.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            GO:WipeSavedVariables()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function GO:RequestWipeConfirmation()
    StaticPopup_Show(addonName .. "_WIPE_CONFIRM")
end

-- Constants for the Support & Community popup window (based on GoldReaper's Welcome window)
local SUPPORT_WINDOW_WIDTH = 420
local SUPPORT_WINDOW_HEIGHT = 580
local DISCORD_LOGO_PATH = "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\DiscordLogo.tga"
local PATREON_LOGO_PATH = "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\PatreonLogo.tga"

-- Color constants for text formatting
local COLORS = {
    SECTION_TITLE = "|cFFD4AF37", -- Yellow
    HIGHLIGHT = "|cFFFFFFFF",     -- White
    SUB_HIGHLIGHT = "|cFFFF8000",   -- Orange
    RESET = "|r"
}

local function CT(color, text)
    return color .. text .. COLORS.RESET
end

-- Creates the main support window for the addon (GoldReaper Welcome screen replica)
function GO:CreateSupportWindow()
    if self.supportFrame then return end
    
    local sw = CreateFrame("Frame", addonName .. "SupportWindow", UIParent, "BasicFrameTemplateWithInset")
    self.supportFrame = sw
    sw:SetSize(SUPPORT_WINDOW_WIDTH, SUPPORT_WINDOW_HEIGHT)
    sw:SetFrameStrata("DIALOG")
    sw:SetFrameLevel(self.optionsFrame and (self.optionsFrame:GetFrameLevel() or 5) + 5 or 10)
    sw.TitleText:SetText("Support & Community")
    sw:SetMovable(true)
    sw:EnableMouse(true)
    sw:RegisterForDrag("LeftButton")
    sw:SetScript("OnDragStart", function(self) self:StartMoving() end)
    sw:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    sw:SetClampedToScreen(true)
    sw.CloseButton:SetScript("OnClick", function() GO:HideSupportWindow() end)

    -- Top text block
    local topText = sw:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    topText:SetPoint("TOPLEFT", 15, -40)
    topText:SetWidth(sw:GetWidth() - 30)
    topText:SetJustifyH("LEFT")
    topText:SetJustifyV("TOP")
    local topContent = {
        CT(COLORS.SECTION_TITLE, "Feedback & Support") .. "\n",
        "Your feedback is crucial for improving the addon! Please don't hesitate to reach out with bugs, suggestions, or questions.\n"
    }
    topText:SetText(table.concat(topContent, ""))
    
    -- Discord Logo and Link (positioned below top text)
    local discordLogo = sw:CreateTexture(nil, "ARTWORK")
    discordLogo:SetSize(328, 108) 
    discordLogo:SetTexture(DISCORD_LOGO_PATH)
    discordLogo:SetPoint("TOP", topText, "BOTTOM", 0, -10)

    local discordLinkBox = CreateFrame("EditBox", nil, sw, "InputBoxTemplate")
    discordLinkBox:SetPoint("TOP", discordLogo, "BOTTOM", 0, -10)
    discordLinkBox:SetSize(sw:GetWidth() - 60, 30)
    discordLinkBox:SetText("https://discord.gg/5TC7gyTe")
    discordLinkBox:SetAutoFocus(false)
    discordLinkBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    discordLinkBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discordLinkBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local discordInstructionLabel = sw:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    discordInstructionLabel:SetPoint("TOP", discordLinkBox, "BOTTOM", 0, -5)
    discordInstructionLabel:SetTextColor(1, 1, 1)
    discordInstructionLabel:SetText("Press Ctrl+C to copy the URL.")

    -- Patreon Logo and Link
    local patreonLogo = sw:CreateTexture(nil, "ARTWORK")
    patreonLogo:SetSize(256, 64) 
    patreonLogo:SetTexture(PATREON_LOGO_PATH)
    patreonLogo:SetPoint("TOP", discordInstructionLabel, "BOTTOM", 0, -20)

    local messageFS = sw:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    messageFS:SetPoint("TOP", patreonLogo, "BOTTOM", 0, -15)
    messageFS:SetWidth(sw:GetWidth() - 40)
    messageFS:SetJustifyH("CENTER")
    messageFS:SetJustifyV("TOP")
    messageFS:SetTextColor(1, 0.82, 0) -- Gold color
    messageFS:SetText("Join the community to chat, get help, and report bugs! If you wish to support development, donations are gratefully accepted as an option.")

    local patreonLinkBox = CreateFrame("EditBox", nil, sw, "InputBoxTemplate")
    patreonLinkBox:SetPoint("TOP", messageFS, "BOTTOM", 0, -15)
    patreonLinkBox:SetSize(sw:GetWidth() - 60, 30)
    patreonLinkBox:SetText("https://www.patreon.com/csasoftware")
    patreonLinkBox:SetAutoFocus(false)
    patreonLinkBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    patreonLinkBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    patreonLinkBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local patreonInstructionLabel = sw:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    patreonInstructionLabel:SetPoint("TOP", patreonLinkBox, "BOTTOM", 0, -5)
    patreonInstructionLabel:SetTextColor(1, 1, 1)
    patreonInstructionLabel:SetText("Press Ctrl+C to copy the URL.")
    
    sw:Hide()
end

function GO:ShowSupportWindow()
    if not self.supportFrame then self:CreateSupportWindow() end
    if not self.supportFrame then return end
    
    self.supportFrame:ClearAllPoints()
    self.supportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    self.supportFrame:Show()
    self.supportFrame:Raise()
end

function GO:HideSupportWindow()
    if self.supportFrame and self.supportFrame:IsShown() then 
        self.supportFrame:Hide() 
    end
end

function GO:ToggleSupportWindow()
    if not self.supportFrame or not self.supportFrame:IsShown() then 
        self:ShowSupportWindow() 
    else 
        self:HideSupportWindow() 
    end
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

