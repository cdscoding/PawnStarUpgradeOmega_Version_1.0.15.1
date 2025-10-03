-- Core.lua - Main addon initialization and core systems

local addonName = "PawnStarUpgradeOmega"
PawnStarUpgradeOmega = {}
local GO = PawnStarUpgradeOmega

-- Core variables
GO.scanTimer = nil
GO.scanningPaused = false -- Flag to track if the periodic scan is paused
GO.playerClass = nil
GO.playerSpec = nil
GO.animationTimer = nil
GO.currentArrowFrame = 1
GO.scanThrottleTimer = nil -- Timer for throttling gear scans

-- Audio system for upgrade notifications
GO.soundFiles = {
    "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\gearupgrade1.ogg",
    "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\gearupgrade2.ogg",
    "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\gearupgrade3.ogg"
}

-- Arrow animation frames and sequence
GO.arrowFrames = {
    "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\arrowup1.tga",
    "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\arrowup2.tga",
    "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\arrowup3.tga",
    "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\arrowup2.tga"
}

-- Slot name mapping
GO.slotNames = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest",
    [6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands",
    [11] = "Ring 1", [12] = "Ring 2", [13] = "Trinket 1", [14] = "Trinket 2",
    [15] = "Back", [16] = "Main Hand", [17] = "Off Hand", [18] = "Ranged"
}

function GO:DebugPrint(...)
    if PawnStarOmegaDB and PawnStarOmegaDB.debugMode then
        print("|cff33ff99PSUO Debug:|r", ...)
    end
end

function GO:PlayUpgradeSound()
    if not PawnStarOmegaDB.soundEnabled then return end
    -- The sound playback is asynchronous, but the triggering scan is heavy. 
    -- We ensure the scan is delayed to prevent client freeze.
    local randomIndex = math.random(1, #self.soundFiles)
    PlaySoundFile(self.soundFiles[randomIndex], "Master")
end

function GO:OnLoad()
    -- Default database structure
    local defaults = {
        settings = {
            showWelcomeWindow = true
        },
        selectedPawnScale = "AUTO",
        minimap = { hide = false },
        soundEnabled = true,
        debugMode = false,
        hasShownPawnRecommendation = false,
        pauseInCombat = false,
        safeZonesOnly = false,
        ignoreBoE = false,
        showOneRing = false,
        blockedItems = {},
        -- NEW: Store character/realm-specific saved builds
        savedBuilds = {}
    }

    -- Initialize or update the database
    PawnStarOmegaDB = PawnStarOmegaDB or {}
    if PawnStarOmegaDB.settings == nil then PawnStarOmegaDB.settings = {} end

    -- Initialize all settings with defaults if not present
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            PawnStarOmegaDB[key] = PawnStarOmegaDB[key] or {}
            for subKey, subValue in pairs(value) do
                if PawnStarOmegaDB[key][subKey] == nil then
                    PawnStarOmegaDB[key][subKey] = subValue
                end
            end
        else
            if PawnStarOmegaDB[key] == nil then
                PawnStarOmegaDB[key] = value
            end
        end
    end
    
    -- Add blockedItems table for users updating the addon
    if PawnStarOmegaDB.blockedItems == nil then
        PawnStarOmegaDB.blockedItems = {}
    end

    -- Add savedBuilds table for users updating the addon
    if PawnStarOmegaDB.savedBuilds == nil then
        PawnStarOmegaDB.savedBuilds = {}
    end

    -- Clean up old variables
    PawnStarOmegaDB.firstTimeUser = nil
    PawnStarOmegaDB.usePawn = nil

    self.playerClass = select(2, UnitClass("player"))
    self.playerSpec = GetSpecialization()

    self:DebugPrint("OnLoad called.")
    self:DebugPrint("Player Class:", self.playerClass)
    self:DebugPrint("Player Spec ID:", self.playerSpec)

    -- Initialize modules
    if self.Welcome and self.Welcome.OnInitialize then
        self.Welcome:OnInitialize()
    end
    if self.BlockedItems and self.BlockedItems.OnInitialize then
        self.BlockedItems:OnInitialize()
    end

    self:CreateMainFrame()
    self:CreateMinimapIcon()
    self:StartArrowAnimation()
    
    -- The periodic scan timer is started here, but the first scan execution is deferred.
    self:StartScanning()

    print("|cff00ff00" .. addonName .. " loaded!|r Type |cffffffff/pawnstar|r to open. " ..
          (self:IsPawnAvailable() and "Pawn integration active!" or "Consider installing Pawn for better accuracy."))
end

function GO:CreateMainFrame()
    -- Increased width from 400 to 500
    self.frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "BasicFrameTemplateWithInset")
    self.frame:SetSize(500, 250) 
    self.frame:SetPoint("CENTER")
    self.frame:SetFrameStrata("TOOLTIP")
    self.frame:SetFrameLevel(25) -- Set below Blocked Items (30) but above Options/StatWeights (DIALOG)
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)

    -- Set strata for the close button to match the parent frame but be one level higher
    self.frame.CloseButton:SetFrameStrata(self.frame:GetFrameStrata())
    self.frame.CloseButton:SetFrameLevel(self.frame:GetFrameLevel() + 1)

    -- Add Logo (Increased size by 20%: 64 -> 77)
    self.frame.logo = self.frame:CreateTexture(nil, "ARTWORK")
    self.frame.logo:SetSize(77, 77) 
    self.frame.logo:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\PawnStarUpgradeOmegaLogo.tga")
    self.frame.logo:SetPoint("TOP", self.frame, "TOP", 0, -5) 

    -- Create animated arrows (Increased size by 20%: 32 -> 38)
    self.frame.arrowLeft = self.frame:CreateTexture(nil, "ARTWORK")
    self.frame.arrowLeft:SetSize(38, 38) 
    self.frame.arrowLeft:SetPoint("RIGHT", self.frame.logo, "LEFT", -5, 0) 

    self.frame.arrowRight = self.frame:CreateTexture(nil, "ARTWORK")
    self.frame.arrowRight:SetSize(38, 38) 
    self.frame.arrowRight:SetPoint("LEFT", self.frame.logo, "RIGHT", 5, 0) 

    self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.frame.title:SetPoint("TOP", self.frame.TitleBg, "TOP", 0, -5)
    self.frame.title:SetText("Gear Upgrades")

    -- Create scroll frame for results (adjusted width)
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self.frame, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", 5, -75) 
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -15, 5) 

    self.content = CreateFrame("Frame")
    self.content:SetSize(475, 1) -- Increased internal content width from 375 to 475
    self.scrollFrame:SetScrollChild(self.content)

    self.frame:Hide()
end

function GO:CreateMinimapIcon()
    local LDB = LibStub("LibDataBroker-1.1")
    local LibDBIcon = LibStub("LibDBIcon-1.0")

    if not LibDBIcon then
        print("|cffff0000" .. addonName .. " Error:|r LibDBIcon-1.0 is not loaded.")
        return
    end

    local dataObject = LDB:NewDataObject(addonName, {
        type = "launcher",
        text = addonName,
        icon = "Interface\\AddOns\\PawnStarUpgradeOmega\\Media\\arrowup3.tga",
        tooltiptext = "Click to open " .. addonName .. " options.",

        OnClick = function(self, button)
            if button == "LeftButton" then
                GO:ToggleOptionsPanel()
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddLine(addonName)
            tooltip:AddLine("Left-click to open options.")
            if GO:IsPawnAvailable() then
                tooltip:AddLine("|cff00ff00Pawn integration active|r")
            else
                tooltip:AddLine("|cffff6600Basic mode - install Pawn for better accuracy|r")
            end
        end
    })

    LibDBIcon:Register(addonName, dataObject, PawnStarOmegaDB.minimap)
end

function GO:StartScanning()
    if self.scanTimer then self.scanTimer:Cancel() end
    -- The periodic ticker is still set to 6 seconds.
    self.scanTimer = C_Timer.NewTicker(6, function() self:ScanGearWithOptions() end)
    self.scanningPaused = false
    self:DebugPrint("Periodic scanning restarted.")
end

function GO:StopScanning()
    if self.scanTimer then
        self.scanTimer:Cancel()
        self.scanTimer = nil
        self.scanningPaused = true
        self:DebugPrint("No upgrades found. Pausing periodic scan to reduce lag.")
    end
end

function GO:StartArrowAnimation()
    if self.animationTimer then self.animationTimer:Cancel() end
    self.animationTimer = C_Timer.NewTicker(0.1, function() self:UpdateArrowAnimation() end)
end

function GO:UpdateArrowAnimation()
    self.currentArrowFrame = (self.currentArrowFrame % #self.arrowFrames) + 1
    local texture = self.arrowFrames[self.currentArrowFrame]

    if self.frame and self.frame.arrowLeft and self.frame.arrowRight then
        self.frame.arrowLeft:SetTexture(texture)
        self.frame.arrowRight:SetTexture(texture)
    end
end

function GO:BlockItem(itemID, itemLink)
    if not itemID or not itemLink then return end
    self:DebugPrint("Blocking item:", itemLink, "(ID:", itemID, ")")
    if not PawnStarOmegaDB.blockedItems then PawnStarOmegaDB.blockedItems = {} end
    PawnStarOmegaDB.blockedItems[itemID] = itemLink
    self:ScanGearWithOptions() -- Rescan to update the upgrade list
end

function GO:UnblockItem(itemID)
    if not itemID then return end
    if not PawnStarOmegaDB.blockedItems or not PawnStarOmegaDB.blockedItems[itemID] then return end

    self:DebugPrint("Unblocking item ID:", itemID)
    PawnStarOmegaDB.blockedItems[itemID] = nil
    
    -- Refresh the Blocked Items window if it's open
    if self.BlockedItems and self.BlockedItems.Frame and self.BlockedItems.Frame:IsShown() then
        self.BlockedItems:UpdatePanel()
    end
    
    self:ScanGearWithOptions() -- Rescan to allow the item to appear again
end

function GO:IsItemBlocked(itemID)
    if not itemID then return false end
    return PawnStarOmegaDB and PawnStarOmegaDB.blockedItems and PawnStarOmegaDB.blockedItems[itemID]
end

function GO:WipeSavedVariables()
    PawnStarOmegaDB = nil
    print("|cff00ff00" .. addonName .. ":|r All saved data has been deleted. Reloading UI.")
    ReloadUI()
end

-- Slash command handler
SLASH_PAWNSTAR1 = "/pawnstar"
SLASH_PAWNSTAR2 = "/psuo"
SlashCmdList["PAWNSTAR"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "debug on" then
        PawnStarOmegaDB.debugMode = true
        print("|cff00ff00PawnStarUpgradeOmega:|r Debug mode ENABLED.")
    elseif msg == "debug off" then
        PawnStarOmegaDB.debugMode = false
        print("|cff00ff00PawnStarUpgradeOmega:|r Debug mode DISABLED.")
    elseif msg == "debug" then
        GO:PrintDebugInfo()
    elseif msg == "pawn" then
        if GO:IsPawnAvailable() then
            print("|cff00ff00PawnStarUpgradeOmega:|r Pawn is installed and active!")
        else
            GO:ShowPawnRecommendation()
        end
    else
        GO:ToggleOptionsPanel()
    end
end

function GO:PrintDebugInfo()
    print("PawnStar: Debug info dump:")
    print("Player class: " .. (GO.playerClass or "nil"))
    print("Player spec: " .. (GO.playerSpec or "nil"))
    print("Player level: " .. UnitLevel("player"))
    print("Pawn available: " .. tostring(GO:IsPawnAvailable()))
    print("Combat pause: " .. tostring(PawnStarOmegaDB.pauseInCombat))
    print("Safe zones only: " .. tostring(PawnStarOmegaDB.safeZonesOnly))
    print("Ignore BoE: " .. tostring(PawnStarOmegaDB.ignoreBoE))
    print("Show one ring: " .. tostring(PawnStarOmegaDB.showOneRing))
    print("Currently in combat: " .. tostring(GO:IsInCombat()))
    print("Currently in safe zone: " .. tostring(GO:IsInSafeZone()))
    print("Can use 2H weapons: " .. tostring(GO:CanUse2HandedWeapons()))
    print("Prefers dual wield: " .. tostring(GO:PrefersDualWield()))

    local equippedCount = 0
    for _ in pairs(GO.equippedGear) do equippedCount = equippedCount + 1 end
    print("Equipped items (" .. equippedCount .. "):")
    for slot, item in pairs(GO.equippedGear) do
         local _, _, _, ilvl = GetItemInfo(item.link)
         print(string.format("  Slot %d: [%s] ilvl %d, Score: %.2f", slot, item.link, ilvl or 0, item.score))
    end
    print("Bag items found:")
    for slot, items in pairs(GO.bagItems) do
        print("  Slot " .. slot .. " can hold " .. #items .. " items:")
        for i, item in ipairs(items) do
            local _, _, _, ilvl, itemMinLevel = GetItemInfo(item.link)
            print(string.format("    Item %d: [%s] ilvl %d bag=%d slot=%d score=%.1f BoE=%s MinLvl=%s",
                i, item.link, ilvl or 0, item.bag, item.slot, item.score, tostring(item.isBoE or false), tostring(itemMinLevel)))
        end
    end
end

-- Function to handle throttled scanning
function GO:RequestThrottledScan()
    -- This throttle timer is still used for BAG_UPDATE and PLAYER_EQUIPMENT_CHANGED
    if self.scanThrottleTimer then
        self.scanThrottleTimer:Cancel()
    end
    self.scanThrottleTimer = C_Timer.After(2.5, function()
        self:DebugPrint("Throttled scan initiated.")
        self:ScanGearWithOptions()
        self.scanThrottleTimer = nil
    end)
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")
-- The previously added 'UI_FINISHED' event caused an error and has been removed.

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            GO:OnLoad()
        elseif loadedAddonName == "Pawn" and GO.OnPawnAddonLoaded then
            C_Timer.After(1, function()
                GO:OnPawnAddonLoaded()
            end)
        end
    elseif event == "PLAYER_LOGIN" then
        -- Handle welcome window display
        if PawnStarOmegaDB and PawnStarOmegaDB.settings and PawnStarOmegaDB.settings.showWelcomeWindow then
            -- Delay welcome window slightly to allow for full screen load
            C_Timer.After(3, function()
                if GO.Welcome and GO.Welcome.ShowWindow then
                    GO.Welcome:ShowWindow()
                end
            end)
        end
        
        -- FIX: Re-enabling the initial heavy gear scan with a 5-second delay on PLAYER_LOGIN.
        -- This ensures the client is past the critical loading phase before the CPU-intensive
        -- scan (and subsequent sound notification) is triggered, preventing the client freeze.
        GO:DebugPrint("PLAYER_LOGIN detected. Initiating first full gear scan (delayed 5s).")
        C_Timer.After(5, function() 
            GO:ScanGearWithOptions() 
        end)

    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" then
        GO:RequestThrottledScan()
    end
end)
