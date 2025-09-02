-- PawnStarUpgradeOmega.lua - Main addon file with pure stat weight system and comprehensive weapon handling

local addonName = "PawnStarUpgradeOmega"
PawnStarUpgradeOmega = {}
local GO = PawnStarUpgradeOmega

-- Core variables
GO.scanTimer = nil
GO.playerClass = nil
GO.playerSpec = nil
GO.equippedGear = {}
GO.bagItems = {}
GO.animationTimer = nil
GO.currentArrowFrame = 1

-- Updated class equipment rules with proper off-hand item support
GO.classEquipmentRules = {
    DEATHKNIGHT = {
        [4] = { [4]=true }, -- Armor: Plate
        [2] = { [0]=true, [4]=true, [7]=true, [6]=true, [1]=true, [5]=true, [8]=true }
    },
    DEMONHUNTER = {
        [4] = { [2]=true }, -- Armor: Leather
        [2] = { [15]=true, [13]=true, [0]=true, [7]=true, [20]=true }
    },
    DRUID = {
        [4] = { [2]=true, [0]=true }, -- Armor: Leather + Off-hand focus items
        [2] = { [15]=true, [13]=true, [4]=true, [6]=true, [10]=true, [5]=true, [14]=true }
    },
    EVOKER = {
        [4] = { [3]=true, [0]=true }, -- Armor: Mail + Off-hand focus items
        [2] = { [15]=true, [13]=true, [0]=true, [4]=true, [7]=true, [10]=true, [14]=true }
    },
    HUNTER = {
        [4] = { [3]=true }, -- Armor: Mail
        [2] = { [2]=true, [18]=true, [3]=true, [15]=true, [13]=true, [0]=true, [7]=true, [6]=true, [10]=true, [1]=true, [8]=true }
    },
    MAGE = {
        [4] = { [1]=true, [0]=true }, -- Armor: Cloth + Off-hand focus items
        [2] = { [15]=true, [7]=true, [10]=true, [19]=true, [14]=true }
    },
    MONK = {
        [4] = { [2]=true, [0]=true }, -- Armor: Leather + Off-hand focus items
        [2] = { [13]=true, [0]=true, [4]=true, [7]=true, [6]=true, [10]=true }
    },
    PALADIN = {
        [4] = { [4]=true, [6]=true }, -- Armor: Plate, Shields
        [2] = { [0]=true, [4]=true, [7]=true, [6]=true, [1]=true, [5]=true, [8]=true }
    },
    PRIEST = {
        [4] = { [1]=true, [0]=true }, -- Armor: Cloth + Off-hand focus items
        [2] = { [15]=true, [4]=true, [10]=true, [19]=true, [14]=true }
    },
    ROGUE = {
        [4] = { [2]=true }, -- Armor: Leather
        [2] = { [2]=true, [18]=true, [15]=true, [13]=true, [3]=true, [0]=true, [4]=true, [7]=true }
    },
    SHAMAN = {
        [4] = { [3]=true, [6]=true, [0]=true }, -- Armor: Mail, Shields + Off-hand focus items
        [2] = { [15]=true, [13]=true, [0]=true, [4]=true, [10]=true, [1]=true, [5]=true, [14]=true }
    },
    WARLOCK = {
        [4] = { [1]=true, [0]=true }, -- Armor: Cloth + Off-hand focus items
        [2] = { [15]=true, [7]=true, [10]=true, [19]=true, [14]=true }
    },
    WARRIOR = {
        [4] = { [4]=true, [6]=true }, -- Armor: Plate, Shields
        [2] = { [2]=true, [18]=true, [15]=true, [13]=true, [3]=true, [0]=true, [4]=true, [7]=true, [6]=true, [10]=true, [1]=true, [5]=true, [8]=true }
    }
}

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
        showOneRing = false
    }

    -- Initialize or update the database
    PawnStarOmegaDB = PawnStarOmegaDB or {}
    if PawnStarOmegaDB.settings == nil then PawnStarOmegaDB.settings = {} end
    
    PawnStarOmegaDB.settings.showWelcomeWindow = (PawnStarOmegaDB.settings.showWelcomeWindow == nil) and defaults.settings.showWelcomeWindow or PawnStarOmegaDB.settings.showWelcomeWindow
    PawnStarOmegaDB.selectedPawnScale = PawnStarOmegaDB.selectedPawnScale or defaults.selectedPawnScale
    PawnStarOmegaDB.minimap = PawnStarOmegaDB.minimap or defaults.minimap
    PawnStarOmegaDB.soundEnabled = (PawnStarOmegaDB.soundEnabled == nil) and defaults.soundEnabled or PawnStarOmegaDB.soundEnabled
    PawnStarOmegaDB.debugMode = PawnStarOmegaDB.debugMode or defaults.debugMode
    PawnStarOmegaDB.hasShownPawnRecommendation = PawnStarOmegaDB.hasShownPawnRecommendation or defaults.hasShownPawnRecommendation
    PawnStarOmegaDB.pauseInCombat = (PawnStarOmegaDB.pauseInCombat == nil) and defaults.pauseInCombat or PawnStarOmegaDB.pauseInCombat
    PawnStarOmegaDB.safeZonesOnly = (PawnStarOmegaDB.safeZonesOnly == nil) and defaults.safeZonesOnly or PawnStarOmegaDB.safeZonesOnly
    PawnStarOmegaDB.ignoreBoE = (PawnStarOmegaDB.ignoreBoE == nil) and defaults.ignoreBoE or PawnStarOmegaDB.ignoreBoE
    PawnStarOmegaDB.showOneRing = (PawnStarOmegaDB.showOneRing == nil) and defaults.showOneRing or PawnStarOmegaDB.showOneRing

    -- Clean up old variables
    PawnStarOmegaDB.firstTimeUser = nil
    PawnStarOmegaDB.usePawn = nil

    self.playerClass = select(2, UnitClass("player"))
    self.playerSpec = GetSpecialization()

    self:DebugPrint("OnLoad called.")
    self:DebugPrint("Player Class:", self.playerClass)
    self:DebugPrint("Player Spec ID:", self.playerSpec)

    -- Initialize Welcome module
    if self.Welcome and self.Welcome.OnInitialize then
        self.Welcome:OnInitialize()
    end
    
    -- Create main frame
    self.frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "BasicFrameTemplateWithInset")
    self.frame:SetSize(500, 500)
    self.frame:SetPoint("CENTER")
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", self.frame.StartMoving)
    self.frame:SetScript("OnDragStop", self.frame.StopMovingOrSizing)
    
    -- Add Logo
    self.frame.logo = self.frame:CreateTexture(nil, "ARTWORK")
    self.frame.logo:SetSize(128, 128)
    self.frame.logo:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Media\\PawnStarUpgradeOmegaLogo.tga")
    self.frame.logo:SetPoint("TOP", self.frame, "TOP", 0, -10)
    
    -- Create animated arrows (only for main upgrade frame)
    self.frame.arrowLeft = self.frame:CreateTexture(nil, "ARTWORK")
    self.frame.arrowLeft:SetSize(64, 64)
    self.frame.arrowLeft:SetPoint("RIGHT", self.frame.logo, "LEFT", -10, 0)
    
    self.frame.arrowRight = self.frame:CreateTexture(nil, "ARTWORK")
    self.frame.arrowRight:SetSize(64, 64)
    self.frame.arrowRight:SetPoint("LEFT", self.frame.logo, "RIGHT", 10, 0)
    
    self.frame.title = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.frame.title:SetPoint("TOP", self.frame.TitleBg, "TOP", 0, -5)
    self.frame.title:SetText("Gear Upgrades")
    
    -- Create scroll frame for results
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self.frame, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", 10, -150)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    self.content = CreateFrame("Frame")
    self.content:SetSize(450, 1)
    self.scrollFrame:SetScrollChild(self.content)

    -- Create Minimap Icon
    self:CreateMinimapIcon()

    -- Start timers
    self:StartArrowAnimation()
    self:StartScanning()
    
    self.frame:Hide()
    print("|cff00ff00" .. addonName .. " loaded!|r Type |cffffffff/pawnstar|r to open. " .. 
          (self:IsPawnAvailable() and "Pawn integration active!" or "Consider installing Pawn for better accuracy."))
end

function GO:WipeSavedVariables()
    PawnStarOmegaDB = nil -- Clearing the variable will cause it to be re-initialized on reload
    print("|cff00ff00" .. addonName .. ":|r All saved data has been deleted. Reloading UI.")
    ReloadUI()
end

-- Icon Configuration Section
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
        -- Using arrowup3.tga (64x64) for minimap icon
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
    -- Use the enhanced scanning function that checks options
    self.scanTimer = C_Timer.NewTicker(6, function() self:ScanGearWithOptions() end)
end

function GO:StartArrowAnimation()
    if self.animationTimer then self.animationTimer:Cancel() end
    self.animationTimer = C_Timer.NewTicker(0.1, function() self:UpdateArrowAnimation() end)
end

function GO:UpdateArrowAnimation()
    self.currentArrowFrame = (self.currentArrowFrame % #self.arrowFrames) + 1
    local texture = self.arrowFrames[self.currentArrowFrame]
    
    -- Only update main frame arrows (upgrade window)
    if self.frame and self.frame.arrowLeft and self.frame.arrowRight then
        self.frame.arrowLeft:SetTexture(texture)
        self.frame.arrowRight:SetTexture(texture)
    end
    
    -- Note: Options frame no longer has arrows
end

-- Legacy function maintained for compatibility - now redirects to enhanced version
function GO:ScanGear()
    self:ScanGearWithOptions()
end

function GO:ScanEquippedGear()
    self.equippedGear = {}
    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local stats = self:GetItemStats(itemLink)
            self.equippedGear[slot] = { 
                link = itemLink, 
                stats = stats, 
                score = self:CalculateItemScore(stats)
            }
            local _, _, _, itemLevel = GetItemInfo(itemLink)
            self:DebugPrint(string.format("Equipped slot %d [%s] ilvl %d: Score %.2f", 
                slot, itemLink, itemLevel or 0, self.equippedGear[slot].score))
        end
    end
end

-- Enhanced function to check if item can be equipped by character level
function GO:CanPlayerUseItem(itemLink)
    if not itemLink then return false end
    
    local itemLevel, itemMinLevel = select(4, GetItemInfo(itemLink)), select(5, GetItemInfo(itemLink))
    local playerLevel = UnitLevel("player")
    
    if itemMinLevel and playerLevel < itemMinLevel then
        self:DebugPrint(string.format("Item [%s] requires level %d, player is level %d - CANNOT USE", 
            itemLink, itemMinLevel, playerLevel))
        return false
    end
    
    self:DebugPrint(string.format("Item [%s] level requirement check passed (req: %s, player: %d)", 
        itemLink, tostring(itemMinLevel), playerLevel))
    return true
end

function GO:IsItemEquippableByClass(itemLink)
    local itemName = GetItemInfo(itemLink)
    local _, _, _, equipSlot, _, classID, subClassID = C_Item.GetItemInfoInstant(itemLink)
    
    -- If the item doesn't have an equip slot (like a Keystone), it's not equippable gear.
    -- This check prevents the function from processing non-gear items and causing errors.
    if not equipSlot or equipSlot == "INVTYPE_NON_EQUIP" then
        self:DebugPrint(string.format("Checking [%s]: SKIPPED. Not an equippable item.", itemName or itemLink))
        return false
    end
    
    -- Check level requirement first
    if not self:CanPlayerUseItem(itemLink) then
        return false
    end
    
    if not self.playerClass or not self.classEquipmentRules[self.playerClass] then
        -- Fallback to itemLink for debug message if itemName is nil
        self:DebugPrint(string.format("Checking [%s]: FAILED. Player class '%s' not found in rules.", itemName or itemLink, self.playerClass))
        return false
    end

    if equipSlot == "INVTYPE_NECK" or equipSlot == "INVTYPE_CLOAK" or equipSlot == "INVTYPE_FINGER" or equipSlot == "INVTYPE_TRINKET" or equipSlot == "INVTYPE_SHIRT" or equipSlot == "INVTYPE_TABARD" then
        self:DebugPrint(string.format("Checking [%s]: PASSED. Universal slot type '%s'.", itemName or itemLink, equipSlot))
        return true
    end

    local rules = self.classEquipmentRules[self.playerClass]
    
    -- Also check if classID or subClassID are nil, which can happen for some items.
    if not classID or not subClassID then
        self:DebugPrint(string.format("Checking [%s]: FAILED. Could not determine ClassID or SubClassID.", itemName or itemLink))
        return false
    end

    local result = rules[classID] and rules[classID][subClassID]
    if result then
        self:DebugPrint(string.format("Checking [%s]: PASSED. ClassID: %d, SubClassID: %d are valid for %s.", itemName or itemLink, classID, subClassID, self.playerClass))
        return true
    else
        self:DebugPrint(string.format("Checking [%s]: FAILED. ClassID: %d, SubClassID: %d are NOT valid for %s.", itemName or itemLink, classID, subClassID, self.playerClass))
        return false
    end
end

-- Legacy function maintained for compatibility - now redirects to enhanced version
function GO:ScanBagItemsWithOptions()
    self.bagItems = {}
    self:DebugPrint("Scanning bag items with options...")
    
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                self:DebugPrint(string.format("Processing item: %s", itemInfo.hyperlink))
                
                -- Check if we should ignore BoE items
                if PawnStarOmegaDB.ignoreBoE and self:IsItemBindOnEquip(itemInfo.hyperlink) then
                    self:DebugPrint("Skipping BoE item: " .. itemInfo.hyperlink)
                else
                    if self:IsItemEquippableByClass(itemInfo.hyperlink) then
                        local equipSlot = self:GetItemEquipSlot(itemInfo.hyperlink)
                        if equipSlot then
                            local stats = self:GetItemStats(itemInfo.hyperlink)
                            local score = self:CalculateItemScore(stats)
                            local slotsToCheck = type(equipSlot) == "table" and equipSlot or {equipSlot}
                            
                            self:DebugPrint(string.format("Item %s can equip to slots: %s", 
                                itemInfo.hyperlink, table.concat(slotsToCheck, ", ")))
                            
                            for _, slotNum in ipairs(slotsToCheck) do
                                local shouldSkip = PawnStarOmegaDB.showOneRing and slotNum == 12
                                
                                if not shouldSkip then
                                    if not self.bagItems[slotNum] then self.bagItems[slotNum] = {} end
                                    table.insert(self.bagItems[slotNum], {
                                        link = itemInfo.hyperlink, 
                                        stats = stats,
                                        score = score, 
                                        bag = bag, 
                                        slot = slot,
                                        isBoE = self:IsItemBindOnEquip(itemInfo.hyperlink)
                                    })
                                    self:DebugPrint(string.format("  ADDED item [%s] for slot %d. Score: %.2f, BoE: %s", 
                                        itemInfo.hyperlink, slotNum, score, tostring(self:IsItemBindOnEquip(itemInfo.hyperlink))))
                                else
                                    self:DebugPrint(string.format("  SKIPPED item [%s] for slot %d due to showOneRing option", 
                                        itemInfo.hyperlink, slotNum))
                                end
                            end
                        else
                            self:DebugPrint(string.format("Item %s has no valid equip slot mapping", itemInfo.hyperlink))
                        end
                    else
                        self:DebugPrint(string.format("Item %s not equippable by class", itemInfo.hyperlink))
                    end
                end
            end
        end
    end
    
    -- Debug summary
    self:DebugPrint("=== BAG SCAN SUMMARY ===")
    for slotNum, items in pairs(self.bagItems) do
        self:DebugPrint(string.format("Slot %d has %d items available", slotNum, #items))
    end
end

-- Legacy function maintained for compatibility - now redirects to enhanced version
function GO:CompareGear()
    self:CompareGearWithOptions()
end

-- Simple upgrade check - pure stat weight comparison (no item level barriers)
function GO:IsValidUpgrade(bagItem, equippedItem)
    -- No equipped item = automatic upgrade
    if not equippedItem then 
        self:DebugPrint(string.format("Empty slot upgrade: [%s] (Score: %.2f)", 
            bagItem.link, bagItem.score))
        return true 
    end
    
    -- Simple comparison: is the bag item's score better?
    local isUpgrade = bagItem.score > equippedItem.score
    
    local _, _, _, bagIlvl = GetItemInfo(bagItem.link)
    local _, _, _, equippedIlvl = GetItemInfo(equippedItem.link)
    
    self:DebugPrint(string.format("Pure stat comparison: [%s] ilvl %d score %.2f vs [%s] ilvl %d score %.2f - Upgrade: %s", 
        bagItem.link, bagIlvl or 0, bagItem.score, 
        equippedItem.link, equippedIlvl or 0, equippedItem.score,
        tostring(isUpgrade)))
    
    return isUpgrade
end

-- Enhanced role detection for smart filtering
function GO:GetPlayerRole()
    local specID = GetSpecialization()
    if not specID then return "UNKNOWN" end
    
    local _, _, _, _, role = GetSpecializationInfo(specID)
    return role -- TANK, HEALER, DAMAGER
end

function GO:IsHybridSpec()
    -- Specs that can meaningfully use different weapon configurations
    local specID = GetSpecialization()
    if not specID then return false end
    
    local specName = select(2, GetSpecializationInfo(specID))
    local _, classFile = UnitClass("player")
    
    local hybridSpecs = {
        SHAMAN = { "Enhancement" }, -- Can use 2H or dual wield
        WARRIOR = { "Arms", "Fury" }, -- Different weapon preferences
        DEATHKNIGHT = { "Frost" }, -- Can dual wield or 2H
        PRIEST = { "Discipline" }, -- Can use different healing setups
    }
    
    if hybridSpecs[classFile] then
        for _, allowedSpec in ipairs(hybridSpecs[classFile]) do
            if specName == allowedSpec then return true end
        end
    end
    return false
end

-- Enhanced weapon type detection
function GO:IsTwoHandedWeapon(itemLink)
    if not itemLink then return false end
    local _, _, _, equipSlot = GetItemInfo(itemLink)
    return equipSlot == "INVTYPE_2HWEAPON"
end

function GO:IsOneHandedWeapon(itemLink)
    if not itemLink then return false end
    local _, _, _, equipSlot = GetItemInfo(itemLink)
    return equipSlot == "INVTYPE_WEAPON" or equipSlot == "INVTYPE_WEAPONMAINHAND"
end

function GO:IsOffHandWeapon(itemLink)
    if not itemLink then return false end
    local _, _, _, equipSlot = GetItemInfo(itemLink)
    return equipSlot == "INVTYPE_WEAPONOFFHAND"
end

function GO:IsShield(itemLink)
    if not itemLink then return false end
    local _, _, _, equipSlot = GetItemInfo(itemLink)
    return equipSlot == "INVTYPE_SHIELD"
end

function GO:IsFocusItem(itemLink)
    if not itemLink then return false end
    local _, _, _, equipSlot = GetItemInfo(itemLink)
    return equipSlot == "INVTYPE_HOLDABLE"
end

function GO:IsOffHandItem(itemLink)
    return self:IsOffHandWeapon(itemLink) or self:IsShield(itemLink) or self:IsFocusItem(itemLink)
end

-- Determine if a weapon setup is valid for the current spec
function GO:IsValidWeaponSetup(mainHand, offHand)
    local role = self:GetPlayerRole()
    local _, classFile = UnitClass("player")
    
    -- Handle empty slots - these should be valid for comparison purposes
    if not mainHand and not offHand then
        return false -- Both empty is not a valid setup
    end
    
    -- Single off-hand item (no main hand) - allow for comparison
    if not mainHand and offHand then
        if self:IsShield(offHand) then
            return role == "TANK" or self:IsHybridSpec()
        elseif self:IsFocusItem(offHand) then
            return role == "HEALER" or (role == "DAMAGER" and self:IsCasterDPS())
        elseif self:IsOffHandWeapon(offHand) then
            return self:PrefersDualWield()
        end
        return false
    end
    
    -- No main hand = invalid (unless we're checking a lone off-hand above)
    if not mainHand then return false end
    
    -- 2-hander checks
    if self:IsTwoHandedWeapon(mainHand) then
        -- 2-hander with offhand = invalid
        if offHand then return false end
        -- Check if spec can use 2-handers
        return self:CanUse2HandedWeapons()
    end
    
    -- 1-hander checks
    if self:IsOneHandedWeapon(mainHand) then
        if not offHand then
            -- Single 1-hander - allow for most specs (players often level with just main hand)
            return true -- Changed from restrictive check to allow single 1H
        end
        
        -- 1-hander + offhand checks
        if self:IsShield(offHand) then
            -- Shield only for tanks or hybrid specs
            return role == "TANK" or self:IsHybridSpec()
        elseif self:IsFocusItem(offHand) then
            -- Focus items for casters
            return role == "HEALER" or (role == "DAMAGER" and self:IsCasterDPS())
        elseif self:IsOffHandWeapon(offHand) then
            -- Dual wield for appropriate specs
            return self:PrefersDualWield()
        end
    end
    
    return false
end

function GO:CanUseSingleOneHander()
    -- Very few specs can effectively use a 1-hander without offhand
    local specID = GetSpecialization()
    if not specID then return false end
    
    local specName = select(2, GetSpecializationInfo(specID))
    local _, classFile = UnitClass("player")
    
    -- Generally not recommended, but some leveling scenarios
    return false -- For now, require complete setups
end

function GO:IsCasterDPS()
    local specID = GetSpecialization()
    if not specID then return false end
    
    local _, classFile = UnitClass("player")
    local casterClasses = {
        MAGE = true,
        WARLOCK = true,
        PRIEST = true, -- Shadow
        SHAMAN = true, -- Elemental
        DRUID = true, -- Balance
        EVOKER = true,
    }
    
    return casterClasses[classFile] and self:GetPlayerRole() == "DAMAGER"
end

-- Create a weapon configuration object for comparison
function GO:CreateWeaponConfig(mainHand, offHand, configType)
    local config = {
        mainHand = mainHand,
        offHand = offHand,
        configType = configType, -- "2H", "1H+SHIELD", "1H+FOCUS", "DUAL_WIELD", "SINGLE_1H"
        totalScore = 0,
        isValid = false,
        description = ""
    }
    
    -- Calculate total score
    if mainHand then
        config.totalScore = config.totalScore + mainHand.score
    end
    if offHand then
        config.totalScore = config.totalScore + offHand.score
    end
    
    -- Check validity
    config.isValid = self:IsValidWeaponSetup(mainHand and mainHand.link, offHand and offHand.link)
    
    -- Generate description
    if mainHand and offHand then
        config.description = string.format("%s + %s", mainHand.link, offHand.link)
    elseif mainHand then
        config.description = mainHand.link
    else
        config.description = "Empty"
    end
    
    return config
end

-- Enhanced weapon slot comparison with comprehensive logic
function GO:CompareWeaponSlots(bagItems)
    local upgrades = {}
    local currentMainHand = self.equippedGear[16]
    local currentOffHand = self.equippedGear[17]
    
    self:DebugPrint("=== WEAPON COMPARISON START ===")
    
    -- Create current configuration
    local currentConfig = self:CreateWeaponConfig(currentMainHand, currentOffHand, "CURRENT")
    self:DebugPrint(string.format("Current setup: %s (Score: %.2f, Valid: %s)", 
        currentConfig.description, currentConfig.totalScore, tostring(currentConfig.isValid)))
    
    local possibleConfigs = {}
    
    -- Generate all possible weapon configurations from bag items
    
    -- 1. Two-handed weapons (slot 16)
    if bagItems[16] then
        for _, bagItem in ipairs(bagItems[16]) do
            if self:IsTwoHandedWeapon(bagItem.link) then
                local config = self:CreateWeaponConfig(bagItem, nil, "2H")
                if config.isValid then
                    table.insert(possibleConfigs, {
                        config = config,
                        replaces = "both",
                        bagItem = bagItem,
                        slot = 16
                    })
                    self:DebugPrint(string.format("2H option: %s (Score: %.2f)", config.description, config.totalScore))
                end
            end
        end
    end
    
    -- 2. Main hand + existing offhand combinations
    if bagItems[16] and currentOffHand then
        for _, bagItem in ipairs(bagItems[16]) do
            if self:IsOneHandedWeapon(bagItem.link) then
                local config = self:CreateWeaponConfig(bagItem, currentOffHand, "1H+EXISTING_OH")
                if config.isValid then
                    table.insert(possibleConfigs, {
                        config = config,
                        replaces = "mainhand",
                        bagItem = bagItem,
                        slot = 16
                    })
                    self:DebugPrint(string.format("MH+existing OH: %s (Score: %.2f)", config.description, config.totalScore))
                end
            end
        end
    end
    
    -- 3. Existing main hand + new offhand combinations
    if bagItems[17] and currentMainHand and self:IsOneHandedWeapon(currentMainHand.link) then
        for _, bagItem in ipairs(bagItems[17]) do
            if self:IsOffHandItem(bagItem.link) then
                local config = self:CreateWeaponConfig(currentMainHand, bagItem, "EXISTING_MH+OH")
                if config.isValid then
                    table.insert(possibleConfigs, {
                        config = config,
                        replaces = "offhand",
                        bagItem = bagItem,
                        slot = 17
                    })
                    self:DebugPrint(string.format("Existing MH+new OH: %s (Score: %.2f)", config.description, config.totalScore))
                end
            end
        end
    end
    
    -- 4. NEW: Single off-hand items when no main hand equipped
    if bagItems[17] and not currentMainHand then
        for _, bagItem in ipairs(bagItems[17]) do
            if self:IsOffHandItem(bagItem.link) then
                local config = self:CreateWeaponConfig(nil, bagItem, "SINGLE_OH")
                if config.isValid then
                    table.insert(possibleConfigs, {
                        config = config,
                        replaces = "offhand",
                        bagItem = bagItem,
                        slot = 17
                    })
                    self:DebugPrint(string.format("Single OH: %s (Score: %.2f)", config.description, config.totalScore))
                end
            end
        end
    end
    
    -- 5. Complete dual-wield setups (both items from bags)
    if bagItems[16] and bagItems[17] then
        for _, mainHandItem in ipairs(bagItems[16]) do
            if self:IsOneHandedWeapon(mainHandItem.link) then
                for _, offHandItem in ipairs(bagItems[17]) do
                    if self:IsOffHandItem(offHandItem.link) then
                        local config = self:CreateWeaponConfig(mainHandItem, offHandItem, "FULL_DUAL")
                        if config.isValid then
                            table.insert(possibleConfigs, {
                                config = config,
                                replaces = "both",
                                bagItems = {mainHandItem, offHandItem},
                                slot = "both"
                            })
                            self:DebugPrint(string.format("Full dual setup: %s (Score: %.2f)", config.description, config.totalScore))
                        end
                    end
                end
            end
        end
    end
    
    -- 6. Single main hand upgrades (when no offhand equipped OR allow replacement)
    if bagItems[16] then
        for _, bagItem in ipairs(bagItems[16]) do
            if self:IsOneHandedWeapon(bagItem.link) then
                local config = self:CreateWeaponConfig(bagItem, nil, "SINGLE_1H")
                if config.isValid then
                    table.insert(possibleConfigs, {
                        config = config,
                        replaces = "mainhand",
                        bagItem = bagItem,
                        slot = 16
                    })
                    self:DebugPrint(string.format("Single 1H: %s (Score: %.2f)", config.description, config.totalScore))
                end
            end
        end
    end
    
    -- Compare all valid configurations against current setup
    for _, configData in ipairs(possibleConfigs) do
        local config = configData.config
        
        -- Use simple stat weight comparison
        if config.totalScore > currentConfig.totalScore then
            local improvement = config.totalScore - currentConfig.totalScore
            
            local upgrade = {
                slot = configData.slot,
                improvement = improvement,
                replaces = configData.replaces,
                configType = config.configType
            }
            
            if configData.bagItems then
                -- Multiple items
                upgrade.bagItems = configData.bagItems
                upgrade.upgrade = config -- Store the full config for display
            else
                -- Single item
                upgrade.upgrade = configData.bagItem
            end
            
            table.insert(upgrades, upgrade)
            self:DebugPrint(string.format("FOUND WEAPON UPGRADE: %s (Score: %.2f vs %.2f, +%.2f)", 
                config.description, config.totalScore, currentConfig.totalScore, improvement))
        end
    end
    
    self:DebugPrint("=== WEAPON COMPARISON END ===")
    return upgrades
end

-- Updated CompareGearWithOptions function - removes item level barriers completely
function GO:CompareGearWithOptions()
    local upgrades = {}
    self:DebugPrint("--- CompareGear Start (Pure Stat Weights Only) ---")

    -- Handle regular gear slots (excluding weapon slots)
    for slotNum = 1, 18 do
        -- Skip slots we don't handle (Shirt, Trinkets, Weapons)
        if slotNum ~= 4 and slotNum ~= 13 and slotNum ~= 14 and slotNum ~= 16 and slotNum ~= 17 then
            -- Handle showOneRing option for ring slot 2
            if PawnStarOmegaDB.showOneRing and slotNum == 12 then
                self:DebugPrint("Skipping ring slot 2 comparison due to showOneRing option")
            else
                self:DebugPrint(string.format("Comparing slot %d (%s)", slotNum, self.slotNames[slotNum] or "Unknown"))
                local equippedItem = self.equippedGear[slotNum]

                if self.bagItems[slotNum] then
                    for _, bagItem in ipairs(self.bagItems[slotNum]) do
                        if self:IsValidUpgrade(bagItem, equippedItem) then
                            local improvement = equippedItem and (bagItem.score - equippedItem.score) or bagItem.score
                            self:DebugPrint(string.format("  FOUND UPGRADE for slot %d: [%s] vs equipped [%s]", 
                                slotNum, bagItem.link, equippedItem and equippedItem.link or "EMPTY"))
                            table.insert(upgrades, {
                                slot = slotNum,
                                upgrade = bagItem,
                                improvement = improvement
                            })
                        else
                             self:DebugPrint(string.format("  Item NOT an upgrade for slot %d: [%s]", 
                                 slotNum, bagItem.link))
                        end
                    end
                else
                     self:DebugPrint("  No suitable bag items found for this slot.")
                end
            end
        end
    end
    
    -- Handle weapon slots with the comprehensive new logic
    local weaponUpgrades = self:CompareWeaponSlots(self.bagItems)
    for _, upgrade in ipairs(weaponUpgrades) do
        table.insert(upgrades, upgrade)
    end

    table.sort(upgrades, function(a, b) return a.improvement > b.improvement end)
    
    if #upgrades > 0 and not self.frame:IsShown() then
        self:PlayUpgradeSound()
    end
    
    self:DebugPrint(string.format("--- CompareGear End (Pure Stat Weights) --- Found %d total upgrades.", #upgrades))
    self:DisplayUpgrades(upgrades)
end

function GO:GetItemStats(itemLink)
    local stats = {}
    if not self.scanTooltip then
        self.scanTooltip = CreateFrame("GameTooltip", "PawnStarScanTooltip", nil, "GameTooltipTemplate")
        self.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    self.scanTooltip:ClearLines()
    self.scanTooltip:SetHyperlink(itemLink)
    
    for i = 1, self.scanTooltip:NumLines() do
        local line = _G["PawnStarScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                local value, statType = text:match("%+(%d+) (.+)")
                if value and statType then
                    value = tonumber(value)
                    if statType:find("Strength") then stats.strength = value
                    elseif statType:find("Agility") then stats.agility = value
                    elseif statType:find("Intellect") then stats.intellect = value
                    elseif statType:find("Stamina") then stats.stamina = value
                    elseif statType:find("Critical Strike") then stats.criticalStrike = value
                    elseif statType:find("Haste") then stats.haste = value
                    elseif statType:find("Mastery") then stats.mastery = value
                    elseif statType:find("Versatility") then stats.versatility = value
                    end
                end
                local armor = text:match("(%d+) Armor")
                if armor then stats.armor = tonumber(armor) end
            end
        end
    end
    return stats
end

function GO:CalculateItemScore(stats)
    local weights, _ = self:GetCurrentStatWeights()
    local score = 0
    
    -- Calculate pure stat score without any item level scaling
    for stat, value in pairs(stats) do
        if weights[stat] then
            score = score + (value * weights[stat])
        end
    end
    
    return score
end

function GO:GetItemEquipSlot(itemLink)
    local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemLink)
    local slotMap = {
        INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4,
        INVTYPE_CHEST = 5, INVTYPE_ROBE = 5,
        INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
        INVTYPE_FINGER = {11, 12}, INVTYPE_TRINKET = {13, 14}, INVTYPE_WEAPON = 16, INVTYPE_SHIELD = 17,
        INVTYPE_RANGED = 18, INVTYPE_CLOAK = 15, INVTYPE_2HWEAPON = 16, INVTYPE_WEAPONMAINHAND = 16,
        INVTYPE_WEAPONOFFHAND = 17, INVTYPE_HOLDABLE = 17
    }
    
    -- Enhanced debug output
    self:DebugPrint(string.format("GetItemEquipSlot for [%s]: equipSlot token '%s'. Mapped to game slot %s.", 
        itemLink, tostring(equipSlot), tostring(slotMap[equipSlot])))
    
    -- Additional debug for off-hand items
    if equipSlot and (equipSlot == "INVTYPE_WEAPONOFFHAND" or equipSlot == "INVTYPE_HOLDABLE" or equipSlot == "INVTYPE_SHIELD") then
        self:DebugPrint(string.format("OFF-HAND ITEM DETECTED: [%s] with equipSlot '%s'", itemLink, equipSlot))
    end
    
    return slotMap[equipSlot]
end

function GO:CanUse2HandedWeapons()
    local specID = GetSpecialization()
    if not specID then return true end
    
    local specName = select(2, GetSpecializationInfo(specID))
    local _, classFile = UnitClass("player")
    
    local twoHandedSpecs = {
        WARRIOR = { "Arms", "Fury" },
        PALADIN = { "Retribution" },
        DEATHKNIGHT = { "Frost", "Unholy" },
        HUNTER = { "Survival", "Beast Mastery", "Marksmanship" },
        SHAMAN = { "Enhancement" },
    }
    
    if twoHandedSpecs[classFile] then
        for _, allowedSpec in ipairs(twoHandedSpecs[classFile]) do
            if specName == allowedSpec then return true end
        end
    end
    return false
end

function GO:PrefersDualWield()
    local specID = GetSpecialization()
    if not specID then return false end
    
    local specName = select(2, GetSpecializationInfo(specID))
    local _, classFile = UnitClass("player")
    
    local dualWieldSpecs = {
        ROGUE = { "Assassination", "Outlaw", "Subtlety" },
        SHAMAN = { "Enhancement" },
        WARRIOR = { "Fury" },
        DEATHKNIGHT = { "Frost" },
        MONK = { "Windwalker" },
        DEMONHUNTER = { "Havoc", "Vengeance" },
    }
    
    if dualWieldSpecs[classFile] then
        for _, preferredSpec in ipairs(dualWieldSpecs[classFile]) do
            if specName == preferredSpec then return true end
        end
    end
    return false
end

function GO:DisplayUpgrades(upgrades)
    self:DebugPrint(string.format("DisplayUpgrades called with %d items.", #upgrades))
    
    -- Clear previous content
    self.content:SetScript("OnUpdate", nil)
    for i = 1, self.content:GetNumChildren() do
        select(i, self.content:GetChildren()):Hide()
    end
    
    if #upgrades > 0 then
        self:DebugPrint("Showing upgrade frame.")
        self.frame:Show()
    else
        self:DebugPrint("No upgrades to show, hiding frame.")
        self.frame:Hide()
        return
    end
    
    local yOffset = -10
    
    for i, upgrade in ipairs(upgrades) do
        local isWeaponUpgrade = upgrade.bagItems or upgrade.configType or upgrade.replaces
        
        if isWeaponUpgrade then
            -- Handle weapon upgrades (can be single or multiple items)
            self:CreateWeaponUpgradeDisplay(upgrade, yOffset)
            yOffset = yOffset - 50 -- Extra space for weapon upgrades
        else
            -- Handle regular gear upgrades
            self:CreateRegularUpgradeDisplay(upgrade, yOffset)
            yOffset = yOffset - 45
        end
    end
    
    self.content:SetHeight(math.abs(yOffset))
end

function GO:CreateRegularUpgradeDisplay(upgrade, yOffset)
    local content = self.content
    
    -- Create item icon
    local iconFrame = CreateFrame("Button", nil, content)
    iconFrame:SetSize(38, 38)
    iconFrame:SetPoint("TOPLEFT", 15, yOffset)
    
    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    
    local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(upgrade.upgrade.link)
    if itemIcon then
        iconTexture:SetTexture(itemIcon)
    end
    
    iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(upgrade.upgrade.link)
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Create equip button
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetSize(380, 40)
    button:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
    
    button.bag = upgrade.upgrade.bag
    button.slot = upgrade.upgrade.slot
    
    local slotName = self.slotNames[upgrade.slot] or ("Slot " .. upgrade.slot)
    local improvementText = string.format("+%.1f", upgrade.improvement)
    
    -- Add BoE indicator if applicable
    local boEIndicator = ""
    if upgrade.upgrade.isBoE then
        boEIndicator = " |cffff6600(BoE)|r"
    end
    
    -- Add level requirement warning if item is too high level
    local levelWarning = ""
    local _, _, _, _, itemMinLevel = GetItemInfo(upgrade.upgrade.link)
    local playerLevel = UnitLevel("player")
    if itemMinLevel and playerLevel < itemMinLevel then
        levelWarning = string.format(" |cffff0000(Req: %d)|r", itemMinLevel)
    end
    
    -- Add item level display for user reference
    local _, _, _, bagIlvl = GetItemInfo(upgrade.upgrade.link)
    local ilvlText = bagIlvl and string.format(" |cff888888[%d]|r", bagIlvl) or ""
    
    button:SetText(string.format("%s (%s): %s%s%s%s", slotName, improvementText, upgrade.upgrade.link, ilvlText, boEIndicator, levelWarning))
    button:GetFontString():SetJustifyH("LEFT")
    button:GetFontString():SetPoint("LEFT", 10, 0)
    
    button:SetScript("OnClick", function(self)
        C_Container.UseContainerItem(self.bag, self.slot)
        GO.frame:Hide()
        C_Timer.After(1.5, function() GO:ScanGearWithOptions() end)
    end)
end

function GO:CreateWeaponUpgradeDisplay(upgrade, yOffset)
    local content = self.content
    
    if upgrade.bagItems then
        -- Multiple items (dual wield setup)
        self:CreateDualWeaponUpgradeDisplay(upgrade, yOffset)
    else
        -- Single weapon item
        self:CreateSingleWeaponUpgradeDisplay(upgrade, yOffset)
    end
end

function GO:CreateSingleWeaponUpgradeDisplay(upgrade, yOffset)
    local content = self.content
    
    -- Create item icon
    local iconFrame = CreateFrame("Button", nil, content)
    iconFrame:SetSize(38, 38)
    iconFrame:SetPoint("TOPLEFT", 15, yOffset)
    
    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)
    
    local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(upgrade.upgrade.link)
    if itemIcon then
        iconTexture:SetTexture(itemIcon)
    end
    
    iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(upgrade.upgrade.link)
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Create equip button
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetSize(380, 40)
    button:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
    
    button.bag = upgrade.upgrade.bag
    button.slot = upgrade.upgrade.slot
    
    -- Generate weapon-specific slot name
    local slotName = self:GetWeaponSlotDisplayName(upgrade)
    local improvementText = string.format("+%.1f", upgrade.improvement)
    
    -- Add BoE indicator if applicable
    local boEIndicator = ""
    if upgrade.upgrade.isBoE then
        boEIndicator = " |cffff6600(BoE)|r"
    end
    
    -- Add level requirement warning
    local levelWarning = ""
    local _, _, _, _, itemMinLevel = GetItemInfo(upgrade.upgrade.link)
    local playerLevel = UnitLevel("player")
    if itemMinLevel and playerLevel < itemMinLevel then
        levelWarning = string.format(" |cffff0000(Req: %d)|r", itemMinLevel)
    end
    
    -- Add item level display
    local _, _, _, bagIlvl = GetItemInfo(upgrade.upgrade.link)
    local ilvlText = bagIlvl and string.format(" |cff888888[%d]|r", bagIlvl) or ""
    
    button:SetText(string.format("%s (%s): %s%s%s%s", slotName, improvementText, upgrade.upgrade.link, ilvlText, boEIndicator, levelWarning))
    button:GetFontString():SetJustifyH("LEFT")
    button:GetFontString():SetPoint("LEFT", 10, 0)
    
    button:SetScript("OnClick", function(self)
        C_Container.UseContainerItem(self.bag, self.slot)
        GO.frame:Hide()
        C_Timer.After(1.5, function() GO:ScanGearWithOptions() end)
    end)
end

function GO:CreateDualWeaponUpgradeDisplay(upgrade, yOffset)
    local content = self.content
    local mainHandItem = upgrade.bagItems[1]
    local offHandItem = upgrade.bagItems[2]
    
    -- Create dual icons
    local iconFrame1 = CreateFrame("Button", nil, content)
    iconFrame1:SetSize(32, 32)
    iconFrame1:SetPoint("TOPLEFT", 15, yOffset)
    
    local iconTexture1 = iconFrame1:CreateTexture(nil, "ARTWORK")
    iconTexture1:SetAllPoints(iconFrame1)
    
    local _, _, _, _, _, _, _, _, _, itemIcon1 = GetItemInfo(mainHandItem.link)
    if itemIcon1 then
        iconTexture1:SetTexture(itemIcon1)
    end
    
    local iconFrame2 = CreateFrame("Button", nil, content)
    iconFrame2:SetSize(32, 32)
    iconFrame2:SetPoint("LEFT", iconFrame1, "RIGHT", 6, 0)
    
    local iconTexture2 = iconFrame2:CreateTexture(nil, "ARTWORK")
    iconTexture2:SetAllPoints(iconFrame2)
    
    local _, _, _, _, _, _, _, _, _, itemIcon2 = GetItemInfo(offHandItem.link)
    if itemIcon2 then
        iconTexture2:SetTexture(itemIcon2)
    end
    
    -- Tooltips for both items
    iconFrame1:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(mainHandItem.link)
        GameTooltip:Show()
    end)
    iconFrame1:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    iconFrame2:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(offHandItem.link)
        GameTooltip:Show()
    end)
    iconFrame2:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Create equip button that handles both items
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetSize(340, 40)
    button:SetPoint("LEFT", iconFrame2, "RIGHT", 10, 0)
    
    button.mainHandBag = mainHandItem.bag
    button.mainHandSlot = mainHandItem.slot
    button.offHandBag = offHandItem.bag
    button.offHandSlot = offHandItem.slot
    
    local slotName = self:GetWeaponSlotDisplayName(upgrade)
    local improvementText = string.format("+%.1f", upgrade.improvement)
    
    -- Check for BoE items
    local boEIndicator = ""
    if mainHandItem.isBoE or offHandItem.isBoE then
        local boEItems = {}
        if mainHandItem.isBoE then table.insert(boEItems, "MH") end
        if offHandItem.isBoE then table.insert(boEItems, "OH") end
        boEIndicator = " |cffff6600(BoE: " .. table.concat(boEItems, ",") .. ")|r"
    end
    
    button:SetText(string.format("%s (%s): Dual Wield Upgrade%s", slotName, improvementText, boEIndicator))
    button:GetFontString():SetJustifyH("LEFT")
    button:GetFontString():SetPoint("LEFT", 10, 0)
    
    button:SetScript("OnClick", function(self)
        -- Equip main hand first, then off hand
        C_Container.UseContainerItem(self.mainHandBag, self.mainHandSlot)
        C_Timer.After(0.5, function()
            C_Container.UseContainerItem(self.offHandBag, self.offHandSlot)
        end)
        GO.frame:Hide()
        C_Timer.After(2, function() GO:ScanGearWithOptions() end)
    end)
end

function GO:GetWeaponSlotDisplayName(upgrade)
    if upgrade.replaces == "both" then
        if upgrade.configType == "2H" then
            return "Weapon (2H)"
        elseif upgrade.configType == "FULL_DUAL" then
            return "Weapons (Dual)"
        else
            return "Weapons"
        end
    elseif upgrade.slot == 16 then
        return "Main Hand"
    elseif upgrade.slot == 17 then
        if upgrade.upgrade then
            if self:IsShield(upgrade.upgrade.link) then
                return "Off Hand (Shield)"
            elseif self:IsFocusItem(upgrade.upgrade.link) then
                return "Off Hand (Focus)"
            elseif self:IsOffHandWeapon(upgrade.upgrade.link) then
                return "Off Hand (Weapon)"
            end
        end
        return "Off Hand"
    else
        return "Weapon"
    end
end

-- Helper function to check if player is in combat
function GO:IsInCombat()
    return InCombatLockdown()
end

-- Helper function to check if player is in a safe zone (rest area)
function GO:IsInSafeZone()
    return IsResting()
end

-- Helper function to check if an item is Bind on Equip
function GO:IsItemBindOnEquip(itemLink)
    if not itemLink then return false end
    
    -- Create temporary tooltip to scan item binding info
    if not self.bindScanTooltip then
        self.bindScanTooltip = CreateFrame("GameTooltip", "PawnStarBindScanTooltip", nil, "GameTooltipTemplate")
        self.bindScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    
    self.bindScanTooltip:ClearLines()
    self.bindScanTooltip:SetHyperlink(itemLink)
    
    -- Check tooltip lines for binding information
    for i = 1, self.bindScanTooltip:NumLines() do
        local line = _G["PawnStarBindScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and (text:find("Binds when equipped") or text:find("Bind when Equipped")) then
                return true
            end
        end
    end
    
    return false
end

-- Enhanced ScanGear function with new option checks
function GO:ScanGearWithOptions()
    -- Check if scanning should be paused in combat
    if PawnStarOmegaDB.pauseInCombat and self:IsInCombat() then
        self:DebugPrint("Gear scan skipped - player is in combat and pauseInCombat is enabled")
        return
    end
    
    -- Check if scanning should only happen in safe zones
    if PawnStarOmegaDB.safeZonesOnly and not self:IsInSafeZone() then
        self:DebugPrint("Gear scan skipped - player not in safe zone and safeZonesOnly is enabled")
        return
    end
    
    self:DebugPrint("ScanGear initiated with option checks passed.")
    self:ScanEquippedGear()
    self:ScanBagItemsWithOptions()
    self:CompareGearWithOptions()
end

-- Slash command handler with enhanced messaging
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
    elseif msg == "pawn" then
        if GO:IsPawnAvailable() then
            print("|cff00ff00PawnStarUpgradeOmega:|r Pawn is installed and active!")
        else
            GO:ShowPawnRecommendation()
        end
    else
        -- Default action for "", "options", or any other unrecognized command is to toggle the options panel.
        GO:ToggleOptionsPanel()
    end
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            GO:OnLoad()
        elseif loadedAddonName == "Pawn" and GO.OnPawnAddonLoaded then
            -- Pawn was loaded after our addon
            C_Timer.After(1, function()
                GO:OnPawnAddonLoaded()
            end)
        end
    elseif event == "PLAYER_LOGIN" then
        if PawnStarOmegaDB and PawnStarOmegaDB.settings and PawnStarOmegaDB.settings.showWelcomeWindow then
            C_Timer.After(3, function()
                if GO.Welcome and GO.Welcome.ShowWindow then
                    GO.Welcome:ShowWindow()
                end
            end)
        end
        C_Timer.After(5, function() GO:ScanGearWithOptions() end)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" then
        C_Timer.After(1.5, function() GO:ScanGearWithOptions() end)
    end
end)