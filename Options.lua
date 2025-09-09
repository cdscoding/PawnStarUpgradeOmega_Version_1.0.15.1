-- Options.lua - Enhanced with smart Pawn integration and user onboarding

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]

function GO:UpdateOptionsPanel()
    if not self.optionsFrame then return end

    local f = self.optionsFrame
    local minimapCheck = _G[addonName .. "MinimapCheck"]
    local soundCheck = _G[addonName .. "SoundCheck"]
    local pauseInCombatCheck = _G[addonName .. "PauseInCombatCheck"]
    local safeZonesOnlyCheck = _G[addonName .. "SafeZonesOnlyCheck"]
    local ignoreBoECheck = _G[addonName .. "IgnoreBoECheck"]
    local showOneRingCheck = _G[addonName .. "ShowOneRingCheck"]

    -- Set checkbox states
    minimapCheck:SetChecked(not PawnStarOmegaDB.minimap.hide)
    soundCheck:SetChecked(PawnStarOmegaDB.soundEnabled)
    pauseInCombatCheck:SetChecked(PawnStarOmegaDB.pauseInCombat)
    safeZonesOnlyCheck:SetChecked(PawnStarOmegaDB.safeZonesOnly)
    ignoreBoECheck:SetChecked(PawnStarOmegaDB.ignoreBoE)
    showOneRingCheck:SetChecked(PawnStarOmegaDB.showOneRing)

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
    f:SetSize(450, 510) -- Made slightly larger
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
    f.title:SetText(addonName .. " Version 1.0.15.1")
    
    -- Override the default close button behavior and set strata
    f.CloseButton:SetFrameStrata(f:GetFrameStrata())
    f.CloseButton:SetFrameLevel(f:GetFrameLevel() + 1)
    f.CloseButton:SetScript("OnClick", function() GO:ToggleOptionsPanel() end)
    
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
    
    -- Blocked Items Button
    local blockedItemsButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    blockedItemsButton:SetSize(160, 25)
    blockedItemsButton:SetPoint("TOP", deleteButton, "BOTTOM", 0, -5)
    blockedItemsButton:SetText("Blocked Items")
    blockedItemsButton:SetScript("OnClick", function()
        GO.BlockedItems:TogglePanel()
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

    -- Pause scans in combat checkbox - ENHANCED
    local pauseInCombatCheck = CreateFrame("CheckButton", addonName .. "PauseInCombatCheck", f, "UICheckButtonTemplate")
    pauseInCombatCheck:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 0, -10)
    pauseInCombatCheck.text = pauseInCombatCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pauseInCombatCheck.text:SetPoint("LEFT", pauseInCombatCheck, "RIGHT", 5, 0)
    pauseInCombatCheck.text:SetText("Pause Scans in Combat")
    pauseInCombatCheck:SetScript("OnClick", function(self)
        PawnStarOmegaDB.pauseInCombat = self:GetChecked()
        
        -- Restart scanning with new options
        if GO.scanTimer then
            GO.scanTimer:Cancel()
        end
        GO.scanTimer = C_Timer.NewTicker(6, function() 
            GO:ScanGearWithOptions() 
        end)
        
        -- Provide feedback to user
        if self:GetChecked() then
            print("|cff00ff00PawnStarUpgradeOmega:|r Gear scanning will now pause during combat.")
        else
            print("|cff00ff00PawnStarUpgradeOmega:|r Gear scanning will continue during combat.")
        end
    end)
    
    -- Add tooltip for combat pause option
    pauseInCombatCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Pause Scans in Combat")
        GameTooltip:AddLine("When enabled, the addon will not scan for gear upgrades while you are in combat. This can help reduce performance impact during fights.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    pauseInCombatCheck:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Scan only in safe zones checkbox - ENHANCED
    local safeZonesOnlyCheck = CreateFrame("CheckButton", addonName .. "SafeZonesOnlyCheck", f, "UICheckButtonTemplate")
    safeZonesOnlyCheck:SetPoint("TOPLEFT", soundCheck, "BOTTOMLEFT", 0, -10)
    safeZonesOnlyCheck.text = safeZonesOnlyCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    safeZonesOnlyCheck.text:SetPoint("LEFT", safeZonesOnlyCheck, "RIGHT", 5, 0)
    safeZonesOnlyCheck.text:SetText("Scan Only in Rest Areas")
    safeZonesOnlyCheck:SetScript("OnClick", function(self)
        PawnStarOmegaDB.safeZonesOnly = self:GetChecked()
        
        -- Restart scanning with new options
        if GO.scanTimer then
            GO.scanTimer:Cancel()
        end
        GO.scanTimer = C_Timer.NewTicker(6, function() 
            GO:ScanGearWithOptions() 
        end)
        
        -- Provide feedback to user
        if self:GetChecked() then
            print("|cff00ff00PawnStarUpgradeOmega:|r Gear scanning will only occur in rest areas (cities, inns, etc.).")
        else
            print("|cff00ff00PawnStarUpgradeOmega:|r Gear scanning will occur anywhere.")
        end
    end)
    
    -- Add tooltip for safe zones option
    safeZonesOnlyCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Scan Only in Rest Areas")
        GameTooltip:AddLine("When enabled, the addon will only scan for gear upgrades when you are in a rest area (cities, inns, etc.). This prevents upgrade notifications while questing or in dangerous areas.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    safeZonesOnlyCheck:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Ignore Bind on Equip checkbox - ENHANCED
    local ignoreBoECheck = CreateFrame("CheckButton", addonName .. "IgnoreBoECheck", f, "UICheckButtonTemplate")
    ignoreBoECheck:SetPoint("TOPLEFT", pauseInCombatCheck, "BOTTOMLEFT", 0, -10)
    ignoreBoECheck.text = ignoreBoECheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ignoreBoECheck.text:SetPoint("LEFT", ignoreBoECheck, "RIGHT", 5, 0)
    ignoreBoECheck.text:SetText("Ignore Bind on Equip")
    ignoreBoECheck:SetScript("OnClick", function(self)
        PawnStarOmegaDB.ignoreBoE = self:GetChecked()
        
        -- Immediately rescan gear to apply changes
        C_Timer.After(0.5, function()
            GO:ScanGearWithOptions()
        end)
        
        -- Provide feedback to user
        if self:GetChecked() then
            print("|cff00ff00PawnStarUpgradeOmega:|r Bind on Equip items will be ignored in upgrade recommendations.")
        else
            print("|cff00ff00PawnStarUpgradeOmega:|r Bind on Equip items will be included in upgrade recommendations.")
        end
    end)
    
    -- Add tooltip for BoE option
    ignoreBoECheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Ignore Bind on Equip")
        GameTooltip:AddLine("When enabled, items that bind when equipped will not be suggested as upgrades. Useful if you want to preserve BoE items for selling or trading.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ignoreBoECheck:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Show 1 Ring Slot Only checkbox - ENHANCED
    local showOneRingCheck = CreateFrame("CheckButton", addonName .. "ShowOneRingCheck", f, "UICheckButtonTemplate")
    showOneRingCheck:SetPoint("TOPLEFT", safeZonesOnlyCheck, "BOTTOMLEFT", 0, -10)
    showOneRingCheck.text = showOneRingCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    showOneRingCheck.text:SetPoint("LEFT", showOneRingCheck, "RIGHT", 5, 0)
    showOneRingCheck.text:SetText("Show 1 Ring Slot Only")
    showOneRingCheck:SetScript("OnClick", function(self)
        PawnStarOmegaDB.showOneRing = self:GetChecked()
        
        -- Immediately rescan gear to apply changes
        C_Timer.After(0.5, function()
            GO:ScanGearWithOptions()
        end)
        
        -- Provide feedback to user
        if self:GetChecked() then
            print("|cff00ff00PawnStarUpgradeOmega:|r Only ring slot 1 will show upgrade recommendations.")
        else
            print("|cff00ff00PawnStarUpgradeOmega:|r Both ring slots will show upgrade recommendations.")
        end
    end)
    
    -- Add tooltip for ring slot option
    showOneRingCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show 1 Ring Slot Only")
        GameTooltip:AddLine("When enabled, only ring slot 1 will be considered for upgrade recommendations. This reduces duplicate ring suggestions since both ring slots can use the same items.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showOneRingCheck:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Information text - moved down
    local infoText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", ignoreBoECheck, "BOTTOMLEFT", 0, -10)
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
local SUPPORT_WINDOW_HEIGHT = 690
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
    
    -- Set strata for the close button to match the parent frame
    sw.CloseButton:SetFrameStrata(sw:GetFrameStrata())
    sw.CloseButton:SetFrameLevel(sw:GetFrameLevel() + 1)
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
    discordLinkBox:SetText("https://discord.com/invite/5TfC7ey3Te")
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
        if GO.BlockedItems.Frame and GO.BlockedItems.Frame:IsShown() then
            GO.BlockedItems.Frame:Hide()
        end
    else
        self:UpdateOptionsPanel()
        self.optionsFrame:Show()
        if self.statWeightsFrame then
            self.statWeightsFrame:Show()
        end
    end
end
