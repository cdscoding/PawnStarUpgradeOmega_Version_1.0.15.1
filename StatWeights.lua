-- StatWeights.lua - Smart Pawn integration with user-friendly fallback system
-- Designed to maximize downloads while providing excellent UX for all users

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]

-- Stat display names for a more user-friendly presentation
local statDisplayNames = {
    strength = "Strength",
    agility = "Agility",
    intellect = "Intellect",
    stamina = "Stamina",
    criticalStrike = "Critical Strike",
    haste = "Haste",
    mastery = "Mastery",
    versatility = "Versatility",
    armor = "Armor",
    -- Additional Pawn stats
    spirit = "Spirit",
    spellpower = "Spell Power",
    attackpower = "Attack Power",
    expertise = "Expertise",
    hit = "Hit",
    dodge = "Dodge",
    parry = "Parry",
    block = "Block",
    resilience = "Resilience"
}

-- Map Pawn's internal stat names to our display names
local pawnStatMapping = {
    ["Strength"] = "strength",
    ["Agility"] = "agility", 
    ["Intellect"] = "intellect",
    ["Stamina"] = "stamina",
    ["CritRating"] = "criticalStrike",
    ["HasteRating"] = "haste",
    ["MasteryRating"] = "mastery",
    ["Versatility"] = "versatility",
    ["Armor"] = "armor",
    ["Spirit"] = "spirit",
    ["Ap"] = "attackpower",
    ["Rap"] = "attackpower",
    ["SpellPower"] = "spellpower",
    ["ExpertiseRating"] = "expertise",
    ["HitRating"] = "hit",
    ["DodgeRating"] = "dodge",
    ["ParryRating"] = "parry",
    ["BlockRating"] = "block",
    ["ResilienceRating"] = "resilience"
}

-- Simple, intentionally generic fallback weights when Pawn isn't available
-- These provide basic functionality while encouraging Pawn installation
-- All secondary stats set to 0.6 to avoid favoring any particular stat priority
local basicFallbackWeights = {
    -- Tank specs: Prioritize survivability stats
    TANK = {
        stamina = 1.00,
        armor = 0.70,
        strength = 0.60, agility = 0.60, -- Primary stat (one will be 0 based on class)
        versatility = 0.60,
        haste = 0.60,
        mastery = 0.60,
        criticalStrike = 0.60
    },
    -- Healer specs: Prioritize intellect and healing throughput
    HEALER = {
        intellect = 1.00,
        versatility = 0.60,
        criticalStrike = 0.60,
        haste = 0.60,
        mastery = 0.60,
        stamina = 0.15
    },
    -- DPS specs: Prioritize damage stats
    DAMAGER = {
        strength = 1.00, agility = 1.00, intellect = 1.00, -- Primary stat varies by class
        criticalStrike = 0.60,
        haste = 0.60,
        mastery = 0.60,
        versatility = 0.60,
        stamina = 0.10
    },
    -- Fallback for characters without a specialization (pre-level 10)
    NO_SPEC = {
        WARRIOR =       { strength = 1.0, stamina = 0.5 },
        PALADIN =       { strength = 1.0, stamina = 0.5 },
        HUNTER =        { agility = 1.0, stamina = 0.5 },
        ROGUE =         { agility = 1.0, stamina = 0.5 },
        PRIEST =        { intellect = 1.0, stamina = 0.5 },
        DEATHKNIGHT =   { strength = 1.0, stamina = 0.5 },
        SHAMAN =        { agility = 1.0, intellect = 1.0, stamina = 0.5 },
        MAGE =          { intellect = 1.0, stamina = 0.5 },
        WARLOCK =       { intellect = 1.0, stamina = 0.5 },
        MONK =          { agility = 1.0, stamina = 0.5 },
        DRUID =         { agility = 1.0, intellect = 1.0, stamina = 0.5 },
        DEMONHUNTER =   { agility = 1.0, stamina = 0.5 },
        EVOKER =        { intellect = 1.0, stamina = 0.5 },
    }
}

function GO:IsPawnAvailable()
    return PawnCommon and PawnCommon.Scales and next(PawnCommon.Scales)
end

function GO:ShowPawnRecommendation()
    -- Create a friendly popup encouraging Pawn installation
    if not self.pawnRecommendFrame then
        local f = CreateFrame("Frame", addonName .. "PawnRecommendFrame", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(450, 300)
        f:SetPoint("CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG") -- Higher strata than options window
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        
        -- Title
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        f.title:SetPoint("TOP", f.TitleBg, "TOP", 0, -5)
        f.title:SetText("Unlock Full Potential!")
        
        -- Main message
        local message = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        message:SetPoint("TOP", f.title, "BOTTOM", 0, -20)
        message:SetWidth(400)
        message:SetJustifyH("CENTER")
        message:SetText("For the most accurate gear recommendations, install the |cff00ff00Pawn|r addon!\n\n" ..
                       "|cffffffffPawn provides:|r\n" ..
                       "• Precise stat weights from simulations\n" ..
                       "• Regular updates for patches\n" ..
                       "• Customizable scales for different builds")
        
        -- Current status
        local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        status:SetPoint("TOP", message, "BOTTOM", 0, -30)
        status:SetTextColor(1, 0.8, 0)
        status:SetText("Currently using basic fallback weights")
        
        -- Buttons
        local installButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        installButton:SetSize(120, 30)
        installButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 20)
        installButton:SetText("Get Pawn")
        installButton:SetScript("OnClick", function()
            print("|cff00ff00PawnStarUpgradeOmega:|r Search for 'Pawn' in CurseForge to install it.")
            f:Hide()
        end)
        
        local laterButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        laterButton:SetSize(120, 30)
        laterButton:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
        laterButton:SetText("Maybe Later")
        laterButton:SetScript("OnClick", function()
            f:Hide()
        end)
        
        local okButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        okButton:SetSize(120, 30)
        okButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 20)
        okButton:SetText("Continue")
        okButton:SetScript("OnClick", function()
            f:Hide()
        end)
        
        self.pawnRecommendFrame = f
    end
    
    self.pawnRecommendFrame:Show()
end

function GO:GetAllAvailablePawnScales()
    if not self:IsPawnAvailable() then
        return {}
    end
    
    local availableScales = {}
    
    for scaleName, scaleData in pairs(PawnCommon.Scales) do
        if scaleData and scaleData.Values and next(scaleData.Values) then
            local displayName = scaleName
            if scaleData.LocalizedName and scaleData.LocalizedName ~= "" then
                displayName = scaleData.LocalizedName
            end
            
            availableScales[scaleName] = {
                internalName = scaleName,
                displayName = displayName,
                values = scaleData.Values,
                isHidden = scaleData.Hidden or false
            }
        end
    end
    
    return availableScales
end

function GO:GetPawnScaleByName(scaleName)
    if not self:IsPawnAvailable() then
        return nil, nil
    end
    
    local scaleData = PawnCommon.Scales[scaleName]
    if scaleData and scaleData.Values then
        return scaleData.Values, scaleName
    end
    
    return nil, nil
end

function GO:GetDefaultPawnScaleForSpec()
    if not self:IsPawnAvailable() then
        return nil, nil
    end
    
    local specID = GetSpecialization()
    if not specID or specID == 0 then return nil, nil end
    
    local _, specName = GetSpecializationInfo(specID)
    if not specName then return nil, nil end -- Ensure spec is valid
    
    local _, classFile = UnitClass("player")
    
    local availableScales = self:GetAllAvailablePawnScales()
    if not next(availableScales) then
        return nil, nil
    end
    
    local bestMatch = nil
    local bestMatchName = nil
    
    -- Look for class + spec name pattern (more reliable than ID)
    for scaleName, scaleInfo in pairs(availableScales) do
        local lowerName = string.lower(scaleInfo.displayName)
        local lowerClassName = string.lower(classFile)
        local lowerSpecName = string.lower(specName)
        if string.find(lowerName, lowerClassName) and string.find(lowerName, lowerSpecName) then
            bestMatch = scaleInfo.values
            bestMatchName = scaleName
            break
        end
    end
    
    -- Look for spec name match only
    if not bestMatch then
        for scaleName, scaleInfo in pairs(availableScales) do
            local lowerName = string.lower(scaleInfo.displayName)
            local lowerSpec = string.lower(specName)
            if string.find(lowerName, lowerSpec) then
                bestMatch = scaleInfo.values
                bestMatchName = scaleName
                break
            end
        end
    end
    
    -- Look for class name match only
    if not bestMatch then
        local lowerClassName = string.lower(classFile)
        for scaleName, scaleInfo in pairs(availableScales) do
            local lowerName = string.lower(scaleInfo.displayName)
            if string.find(lowerName, lowerClassName) then
                bestMatch = scaleInfo.values
                bestMatchName = scaleName
                break
            end
        end
    end
    
    return bestMatch, bestMatchName
end


function GO:GetBasicFallbackWeights()
    local specID = GetSpecialization()
    local className, classFile = UnitClass("player")
    local specName = specID and GetSpecializationInfo(specID)
    
    if not specName then
        -- Handle characters without a specialization (pre-level 10)
        if basicFallbackWeights.NO_SPEC[classFile] then
            return basicFallbackWeights.NO_SPEC[classFile], "Basic Fallback (" .. className .. ")"
        else
            -- Ultra-basic fallback if class not found
            return { strength = 1, agility = 1, intellect = 1, stamina = 0.5 }, "Ultra-Basic Fallback"
        end
    end
    
    local _, _, _, _, role = GetSpecializationInfo(specID)
    
    if basicFallbackWeights[role] then
        return basicFallbackWeights[role], "Basic Fallback (" .. specName .. ")"
    end
    
    -- Ultra-basic fallback if role is somehow unknown
    return { strength = 1, agility = 1, intellect = 1, stamina = 0.5 }, "Ultra-Basic Fallback"
end

function GO:GetCurrentStatWeights()
    local specID = GetSpecialization()
    local specName = specID and GetSpecializationInfo(specID)

    -- Priority 1: If no spec is learned, always use the class-based fallback.
    if not specName then
        self:DebugPrint("No specialization learned. Using class-based fallback weights.")
        return self:GetBasicFallbackWeights()
    end

    -- Priority 2: Try to use Pawn if available and a spec is learned
    if self:IsPawnAvailable() then
        local selectedScale = PawnStarOmegaDB.selectedPawnScale
        local pawnWeights = nil
        local scaleName = nil
        
        if selectedScale and selectedScale ~= "AUTO" then
            pawnWeights, scaleName = self:GetPawnScaleByName(selectedScale)
        end
        
        if not pawnWeights then
            pawnWeights, scaleName = self:GetDefaultPawnScaleForSpec()
        end
        
        if pawnWeights and scaleName then
            local convertedWeights = {}
            for pawnStat, value in pairs(pawnWeights) do
                local ourStatName = pawnStatMapping[pawnStat]
                if ourStatName and value > 0 then
                    convertedWeights[ourStatName] = value
                end
            end
            
            if next(convertedWeights) then
                local displayName = scaleName
                local availableScales = self:GetAllAvailablePawnScales()
                if availableScales[scaleName] then
                    displayName = availableScales[scaleName].displayName
                end
                self:DebugPrint("Using Pawn stat weights from scale: " .. displayName)
                return convertedWeights, "Pawn: " .. displayName
            end
        end
    end
    
    -- Priority 3: Use role-based fallback if spec is learned but Pawn fails or isn't installed
    self:DebugPrint("Using role-based fallback weights.")
    local fallbackWeights, fallbackName = self:GetBasicFallbackWeights()
    
    if not PawnStarOmegaDB.hasShownPawnRecommendation then
        PawnStarOmegaDB.hasShownPawnRecommendation = true
        C_Timer.After(2, function()
            self:ShowPawnRecommendation()
        end)
    end
    
    return fallbackWeights, fallbackName
end

function GO:CreateScaleDropdown()
    if not self.statWeightsFrame then return end
    
    local dropdown = CreateFrame("Frame", addonName .. "ScaleDropdown", self.statWeightsFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOP", self.statWeightsFrame.scaleInfo, "BOTTOM", 0, -10)
    UIDropDownMenu_SetWidth(dropdown, 300)
    
    if self:IsPawnAvailable() then
        UIDropDownMenu_SetText(dropdown, "Select Pawn Scale...")
    else
        UIDropDownMenu_SetText(dropdown, "Install Pawn for More Options")
    end
    
    local function DropdownOnClick(self)
        if self.value == "INSTALL_PAWN" then
            GO:ShowPawnRecommendation()
            return
        end
        
        PawnStarOmegaDB.selectedPawnScale = self.value
        UIDropDownMenu_SetText(dropdown, self:GetText())
        GO:UpdateStatWeightsPanel()
        GO:ScanGear()
    end
    
    local function DropdownInitialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
        
        if GO:IsPawnAvailable() then
            -- Add AUTO option
            info.text = "Auto-detect Best Scale"
            info.value = "AUTO"
            info.func = DropdownOnClick
            info.checked = (PawnStarOmegaDB.selectedPawnScale == "AUTO" or not PawnStarOmegaDB.selectedPawnScale)
            UIDropDownMenu_AddButton(info, level)
            
            -- Add separator
            info = UIDropDownMenu_CreateInfo()
            info.text = ""
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            
            -- Add available Pawn scales
            local availableScales = GO:GetAllAvailablePawnScales()
            local sortedScales = {}
            
            for scaleName, scaleInfo in pairs(availableScales) do
                table.insert(sortedScales, {
                    internalName = scaleName,
                    displayName = scaleInfo.displayName,
                    isHidden = scaleInfo.isHidden
                })
            end
            table.sort(sortedScales, function(a, b) return a.displayName < b.displayName end)
            
            for _, scaleData in ipairs(sortedScales) do
                info = UIDropDownMenu_CreateInfo()
                info.text = scaleData.displayName
                if scaleData.isHidden then
                    info.text = info.text .. " (Hidden)"
                end
                info.value = scaleData.internalName
                info.func = DropdownOnClick
                info.checked = (PawnStarOmegaDB.selectedPawnScale == scaleData.internalName)
                UIDropDownMenu_AddButton(info, level)
            end
        else
            -- Show Pawn installation option
            info.text = "Install Pawn for Better Weights"
            info.value = "INSTALL_PAWN"
            info.func = DropdownOnClick
            info.notCheckable = true
            info.colorCode = "|cff00ff00"
            UIDropDownMenu_AddButton(info, level)
            
            info = UIDropDownMenu_CreateInfo()
            info.text = "Using Basic Fallback Weights"
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
    end
    
    UIDropDownMenu_Initialize(dropdown, DropdownInitialize)
    self.scaleDropdown = dropdown
    
    return dropdown
end

function GO:UpdateStatWeightsPanel()
    if not self.statWeightsFrame then return end

    local f = self.statWeightsFrame
    
    -- Clear previous content
    for i = 1, (f.numStatStrings or 0) do
        local statString = _G[addonName .. "StatString" .. i]
        if statString then
            statString:Hide()
        end
    end
    
    local specID = GetSpecialization()
    local className, classFile = UnitClass("player")
    local classColor = RAID_CLASS_COLORS[classFile]
    
    local specName
    if specID and GetSpecializationInfo(specID) then
        _, specName = GetSpecializationInfo(specID)
    else
        specName = "No Specialization"
    end
    
    local weights, scaleName = self:GetCurrentStatWeights()
    
    if not weights or not next(weights) then
        f.specInfo:SetText("No weights available")
        f.scaleInfo:SetText("Please select a specialization")
        return
    end

    -- Update header
    f.specInfo:SetText(specName .. " " .. className)
    if classColor then
        f.specInfo:SetTextColor(classColor.r, classColor.g, classColor.b)
    end
    
    -- Color-code the scale name based on source
    if string.find(scaleName, "Pawn:") then
        f.scaleInfo:SetTextColor(0.2, 1, 0.2) -- Green for Pawn
    else
        f.scaleInfo:SetTextColor(1, 0.8, 0.2) -- Orange for fallback
    end

    f.scaleInfo:SetText(scaleName)

    -- Update dropdown text
    if self.scaleDropdown then
        if self:IsPawnAvailable() then
            local selectedScale = PawnStarOmegaDB.selectedPawnScale
            if selectedScale and selectedScale ~= "AUTO" then
                local availableScales = self:GetAllAvailablePawnScales()
                if availableScales[selectedScale] then
                    UIDropDownMenu_SetText(self.scaleDropdown, availableScales[selectedScale].displayName)
                else
                    UIDropDownMenu_SetText(self.scaleDropdown, "Scale not found")
                end
            else
                UIDropDownMenu_SetText(self.scaleDropdown, "Auto-detect Best Scale")
            end
        else
            UIDropDownMenu_SetText(self.scaleDropdown, "Install Pawn for More Options")
        end
    end

    -- Add helpful hint for fallback weights
    if not self:IsPawnAvailable() then
        local hintText = f.hintText
        if not hintText then
            hintText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            hintText:SetPoint("TOP", f.scaleInfo, "BOTTOM", 0, -15)
            hintText:SetWidth(350)
            hintText:SetJustifyH("CENTER")
            hintText:SetTextColor(1, 0.6, 0.2)
            f.hintText = hintText
        end
        hintText:SetText("Install Pawn addon for accurate, personalized stat weights!")
        hintText:Show()
    else
        if f.hintText then
            f.hintText:Hide()
        end
    end

    -- Display weights in two columns
    local yOffset = self:IsPawnAvailable() and -140 or -160 -- Extra space for hint
    local xOffset = 30
    local i = 1
    local column = 1
    local statsInColumn = 0
    local maxStatsPerColumn = 6
    
    local sortedStats = {}
    for statKey, value in pairs(weights) do
        if value > 0 then
            table.insert(sortedStats, {key = statKey, value = value})
        end
    end
    table.sort(sortedStats, function(a, b) return a.value > b.value end)

    for _, statData in ipairs(sortedStats) do
        local stat = statData.key
        local value = statData.value
        local displayName = statDisplayNames[stat] or stat
        local statString = _G[addonName .. "StatString" .. i]
        if not statString then
            statString = f:CreateFontString(addonName .. "StatString" .. i, "OVERLAY", "GameFontNormal")
            statString:SetJustifyH("LEFT")
        end
        statString:SetPoint("TOPLEFT", xOffset, yOffset)
        statString:SetText(string.format("%s: %.2f", displayName, value))
        statString:Show()
        
        yOffset = yOffset - 25
        statsInColumn = statsInColumn + 1
        
        if statsInColumn >= maxStatsPerColumn and column == 1 then
            column = 2
            statsInColumn = 0
            yOffset = self:IsPawnAvailable() and -140 or -160
            xOffset = 220
        end
        i = i + 1
    end
    f.numStatStrings = i - 1
end

function GO:OnSpecChanged()
    self:UpdateStatWeightsPanel()
    print("PawnStarUpgradeOmega: Spec changed, updating weights and rescanning gear...")
    self:ScanGear()
end

function GO:OnPawnAddonLoaded()
    -- Called when Pawn addon is detected
    print("|cff00ff00PawnStarUpgradeOmega:|r Pawn detected! Switching to Pawn stat weights for maximum accuracy.")
    
    if self.pawnRecommendFrame and self.pawnRecommendFrame:IsShown() then
        self.pawnRecommendFrame:Hide()
    end
    
    self:UpdateStatWeightsPanel()
    self:ScanGear()
end

function GO:CreateStatWeightsPanel()
    if self.statWeightsFrame then return end

    local f = CreateFrame("Frame", addonName .. "StatWeightsFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(450, 510) -- Slightly larger to accommodate hints
    f:SetPoint("LEFT", self.optionsFrame, "RIGHT", 10, 0)
    f:SetFrameStrata("DIALOG")
    
    -- Register for spec change events
    f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:RegisterEvent("CHARACTER_POINTS_CHANGED")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_SPECIALIZATION_CHANGED" or 
           event == "ACTIVE_TALENT_GROUP_CHANGED" or
           event == "PLAYER_TALENT_UPDATE" or
           event == "CHARACTER_POINTS_CHANGED" then
            C_Timer.After(0.5, function()
                GO:OnSpecChanged()
            end)
        elseif event == "ADDON_LOADED" and ... == "Pawn" then
            C_Timer.After(1, function()
                GO:OnPawnAddonLoaded()
            end)
        end
    end)
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", f.TitleBg, "TOP", 0, -5)
    f.title:SetText("Current Stat Weights")

    -- Override the default close button behavior and set strata
    f.CloseButton:SetFrameStrata(f:GetFrameStrata())
    f.CloseButton:SetFrameLevel(f:GetFrameLevel() + 1)
    f.CloseButton:SetScript("OnClick", function() GO:ToggleOptionsPanel() end)

    f.specInfo = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.specInfo:SetPoint("TOP", f.title, "BOTTOM", 0, -15)
    
    f.scaleInfo = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.scaleInfo:SetPoint("TOP", f.specInfo, "BOTTOM", 0, -5)

    self.statWeightsFrame = f
    self:CreateScaleDropdown()
    f:Hide()
end

