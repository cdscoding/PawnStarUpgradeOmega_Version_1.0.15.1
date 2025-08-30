-- PawnStarUpgradeOmega.lua - Main addon file with smart Pawn integration

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

-- Defines what item class and subclass IDs each class can equip.
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
        [4] = { [2]=true }, -- Armor: Leather
        [2] = { [15]=true, [13]=true, [4]=true, [6]=true, [10]=true, [5]=true, [14]=true }
    },
    EVOKER = {
        [4] = { [3]=true }, -- Armor: Mail
        [2] = { [15]=true, [13]=true, [0]=true, [4]=true, [7]=true, [10]=true, [14]=true }
    },
    HUNTER = {
        [4] = { [3]=true }, -- Armor: Mail
        [2] = { [2]=true, [18]=true, [3]=true, [15]=true, [13]=true, [0]=true, [7]=true, [6]=true, [10]=true, [1]=true, [8]=true }
    },
    MAGE = {
        [4] = { [1]=true }, -- Armor: Cloth
        [2] = { [15]=true, [7]=true, [10]=true, [19]=true, [14]=true }
    },
    MONK = {
        [4] = { [2]=true }, -- Armor: Leather
        [2] = { [13]=true, [0]=true, [4]=true, [7]=true, [6]=true, [10]=true }
    },
    PALADIN = {
        [4] = { [4]=true, [6]=true }, -- Armor: Plate, Shields
        [2] = { [0]=true, [4]=true, [7]=true, [6]=true, [1]=true, [5]=true, [8]=true }
    },
    PRIEST = {
        [4] = { [1]=true }, -- Armor: Cloth
        [2] = { [15]=true, [4]=true, [10]=true, [19]=true, [14]=true }
    },
    ROGUE = {
        [4] = { [2]=true }, -- Armor: Leather
        [2] = { [2]=true, [18]=true, [15]=true, [13]=true, [3]=true, [0]=true, [4]=true, [7]=true }
    },
    SHAMAN = {
        [4] = { [3]=true, [6]=true }, -- Armor: Mail, Shields
        [2] = { [15]=true, [13]=true, [0]=true, [4]=true, [10]=true, [1]=true, [5]=true, [14]=true }
    },
    WARLOCK = {
        [4] = { [1]=true }, -- Armor: Cloth
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
    -- Initialize saved variables with new Pawn tracking
    if PawnStarOmegaDB == nil then
        PawnStarOmegaDB = {
            selectedPawnScale = "AUTO",
            minimap = { hide = false },
            soundEnabled = true,
            debugMode = false,
            hasShownPawnRecommendation = false,
            firstTimeUser = true
        }
    end

    -- Ensure all necessary variables exist
    PawnStarOmegaDB.debugMode = PawnStarOmegaDB.debugMode or false
    PawnStarOmegaDB.hasShownPawnRecommendation = PawnStarOmegaDB.hasShownPawnRecommendation or false
    PawnStarOmegaDB.firstTimeUser = PawnStarOmegaDB.firstTimeUser ~= false -- Default to true
    if PawnStarOmegaDB.selectedPawnScale == nil then
        PawnStarOmegaDB.selectedPawnScale = "AUTO"
    end
    PawnStarOmegaDB.usePawn = nil -- Remove deprecated setting

    self.playerClass = select(2, UnitClass("player"))
    self.playerSpec = GetSpecialization()

    self:DebugPrint("OnLoad called.")
    self:DebugPrint("Player Class:", self.playerClass)
    self:DebugPrint("Player Spec ID:", self.playerSpec)
    
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

    -- Check for first-time user experience
    if PawnStarOmegaDB.firstTimeUser then
        self:ShowFirstTimeWelcome()
        PawnStarOmegaDB.firstTimeUser = false
    end

    -- Start timers
    self:StartArrowAnimation()
    self:StartScanning()
    
    self.frame:Hide()
    print("|cff00ff00" .. addonName .. " loaded!|r Type |cffffffff/pawnstar|r to open. " .. 
          (self:IsPawnAvailable() and "Pawn integration active!" or "Consider installing Pawn for better accuracy."))
end

function GO:ShowFirstTimeWelcome()
    -- Brief, friendly welcome for new users
    C_Timer.After(3, function()
        print("|cff00ff00Welcome to PawnStarUpgradeOmega!|r")
        print("This addon automatically scans for gear upgrades every 6 seconds.")
        if not self:IsPawnAvailable() then
            print("For the most accurate results, consider installing the |cffffffff'Pawn'|r addon.")
            print("Type |cffffffff/pawnstar options|r to learn more!")
        else
            print("Pawn detected - you're all set for maximum accuracy!")
        end
    end)
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
    self.scanTimer = C_Timer.NewTicker(6, function() self:ScanGear() end)
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

function GO:ScanGear()
    self:DebugPrint("ScanGear initiated.")
    self:ScanEquippedGear()
    self:ScanBagItems()
    self:CompareGear()
end

function GO:ScanEquippedGear()
    self.equippedGear = {}
    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local stats = self:GetItemStats(itemLink)
            self.equippedGear[slot] = { link = itemLink, stats = stats, score = self:CalculateItemScore(stats) }
            self:DebugPrint(string.format("Equipped item in slot %d [%s]: Score %.2f", slot, itemLink, self.equippedGear[slot].score))
        end
    end
end

function GO:IsItemEquippableByClass(itemLink)
    local itemName = GetItemInfo(itemLink)
    local _, _, _, equipSlot, _, classID, subClassID = C_Item.GetItemInfoInstant(itemLink)
    
    if not self.playerClass or not self.classEquipmentRules[self.playerClass] then
        self:DebugPrint(string.format("Checking [%s]: FAILED. Player class '%s' not found in rules.", itemName, self.playerClass))
        return false
    end

    if equipSlot == "INVTYPE_NECK" or equipSlot == "INVTYPE_CLOAK" or equipSlot == "INVTYPE_FINGER" or equipSlot == "INVTYPE_TRINKET" or equipSlot == "INVTYPE_SHIRT" or equipSlot == "INVTYPE_TABARD" then
        self:DebugPrint(string.format("Checking [%s]: PASSED. Universal slot type '%s'.", itemName, equipSlot))
        return true
    end

    local rules = self.classEquipmentRules[self.playerClass]
    local result = rules[classID] and rules[classID][subClassID]
    if result then
        self:DebugPrint(string.format("Checking [%s]: PASSED. ClassID: %d, SubClassID: %d are valid for %s.", itemName, classID, subClassID, self.playerClass))
        return true
    else
        self:DebugPrint(string.format("Checking [%s]: FAILED. ClassID: %d, SubClassID: %d are NOT valid for %s.", itemName, classID, subClassID, self.playerClass))
        return false
    end
end

function GO:ScanBagItems()
    self.bagItems = {}
    self:DebugPrint("Scanning bag items...")
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                if self:IsItemEquippableByClass(itemInfo.hyperlink) then
                    local equipSlot = self:GetItemEquipSlot(itemInfo.hyperlink)
                    if equipSlot then
                        local stats = self:GetItemStats(itemInfo.hyperlink)
                        local score = self:CalculateItemScore(stats)
                        local slotsToCheck = type(equipSlot) == "table" and equipSlot or {equipSlot}
                        for _, slotNum in ipairs(slotsToCheck) do
                            if not self.bagItems[slotNum] then self.bagItems[slotNum] = {} end
                            table.insert(self.bagItems[slotNum], {
                                link = itemInfo.hyperlink, stats = stats,
                                score = score, bag = bag, slot = slot
                            })
                            self:DebugPrint(string.format("  Found suitable item [%s] for slot %d. Score: %.2f", itemInfo.hyperlink, slotNum, score))
                        end
                    end
                end
            end
        end
    end
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
    self:DebugPrint(string.format("GetItemEquipSlot for [%s]: equipSlot token '%s'. Mapped to game slot %s.", itemLink, tostring(equipSlot), tostring(slotMap[equipSlot])))
    return slotMap[equipSlot]
end

function GO:CompareGear()
    local upgrades = {}
    self:DebugPrint("--- CompareGear Start ---")

    for slotNum = 1, 18 do
        -- Skip slots we don't handle (Shirt, Trinkets)
        if slotNum ~= 4 and slotNum ~= 13 and slotNum ~= 14 then
            self:DebugPrint(string.format("Comparing slot %d (%s)", slotNum, self.slotNames[slotNum] or "Unknown"))
            local equippedItem = self.equippedGear[slotNum]
            local equippedScore = equippedItem and equippedItem.score or 0
            self:DebugPrint(string.format("  Equipped Score: %.2f", equippedScore))

            if self.bagItems[slotNum] then
                for _, bagItem in ipairs(self.bagItems[slotNum]) do
                    if not equippedItem or bagItem.score > equippedScore then
                        self:DebugPrint(string.format("  FOUND UPGRADE for slot %d: [%s] (Score: %.2f) vs Equipped (Score: %.2f). Empty slot: %s", slotNum, bagItem.link, bagItem.score, equippedScore, tostring(not equippedItem)))
                        table.insert(upgrades, {
                            slot = slotNum,
                            upgrade = bagItem,
                            improvement = bagItem.score - equippedScore
                        })
                    else
                         self:DebugPrint(string.format("  Item NOT an upgrade for slot %d: [%s] (Score: %.2f) vs Equipped (Score: %.2f).", slotNum, bagItem.link, bagItem.score, equippedScore))
                    end
                end
            else
                 self:DebugPrint("  No suitable bag items found for this slot.")
            end
        end
    end

    table.sort(upgrades, function(a, b) return a.improvement > b.improvement end)
    
    if #upgrades > 0 and not self.frame:IsShown() then
        self:PlayUpgradeSound()
    end
    
    self:DebugPrint(string.format("--- CompareGear End --- Found %d total upgrades.", #upgrades))
    self:DisplayUpgrades(upgrades)
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
        -- Create item icon
        local iconFrame = CreateFrame("Button", nil, self.content)
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
        local button = CreateFrame("Button", nil, self.content, "UIPanelButtonTemplate")
        button:SetSize(380, 40)
        button:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
        
        button.bag = upgrade.upgrade.bag
        button.slot = upgrade.upgrade.slot
        
        local slotName = self.slotNames[upgrade.slot] or ("Slot " .. upgrade.slot)
        local improvementText = string.format("+%.1f", upgrade.improvement)
        button:SetText(string.format("%s (%s): %s", slotName, improvementText, upgrade.upgrade.link))
        button:GetFontString():SetJustifyH("LEFT")
        button:GetFontString():SetPoint("LEFT", 10, 0)
        
        button:SetScript("OnClick", function(self)
            C_Container.UseContainerItem(self.bag, self.slot)
            GO.frame:Hide()
            C_Timer.After(1.5, function() GO:ScanGear() end)
        end)
        
        yOffset = yOffset - 45
    end
    
    self.content:SetHeight(math.abs(yOffset))
end

-- Slash command handler with enhanced messaging
SLASH_PAWNSTAR1 = "/pawnstar"
SLASH_PAWNSTAR2 = "/psuo"
SlashCmdList["PAWNSTAR"] = function(msg)
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
        print("Pawn available: " .. tostring(GO:IsPawnAvailable()))
        print("Equipped items (" .. #GO.equippedGear .. "):")
        for slot, item in pairs(GO.equippedGear) do
             print(string.format("  Slot %d: [%s], Score: %.2f", slot, item.link, item.score))
        end
        print("Bag items found:")
        for slot, items in pairs(GO.bagItems) do
            print("  Slot " .. slot .. " can hold " .. #items .. " items:")
            for i, item in ipairs(items) do
                print(string.format("    Item %d: [%s] bag=%d slot=%d score=%.1f", i, item.link, item.bag, item.slot, item.score))
            end
        end
    elseif msg == "options" then
        GO:ToggleOptionsPanel()
    elseif msg == "pawn" then
        if GO:IsPawnAvailable() then
            print("|cff00ff00PawnStarUpgradeOmega:|r Pawn is installed and active!")
        else
            GO:ShowPawnRecommendation()
        end
    else
        if GO.frame:IsShown() then
            GO.frame:Hide()
        else
            GO:ScanGear()
            if not GO.frame:IsShown() then
                print("|cff00ff00PawnStar:|r No upgrades found. " .. 
                      (GO:IsPawnAvailable() and "Your gear is optimized!" or "Install Pawn for more accurate recommendations."))
            end
        end
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
        C_Timer.After(5, function() GO:ScanGear() end)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "BAG_UPDATE" then
        C_Timer.After(1.5, function() GO:ScanGear() end)
    end
end)