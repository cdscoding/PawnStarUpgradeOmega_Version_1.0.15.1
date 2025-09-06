-- Equipment.lua - All gear scanning and comparison logic

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]

-- Core equipment variables
GO.equippedGear = {}
GO.bagItems = {}

-- Updated class equipment rules with proper off-hand item support
GO.classEquipmentRules = {
    DEATHKNIGHT = {
        [4] = { [4]=true }, -- Armor: Plate
        [2] = { [0]=true, [4]=true, [7]=true, [6]=true, [1]=true, [5]=true, [8]=true }
    },
    DEMONHUNTER = {
        [4] = { [2]=true }, -- Armor: Leather
        [2] = { [9]=true, [16]=true, [15]=true, [13]=true, [0]=true, [7]=true } -- Added [9]=true for Warglaives
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

function GO:ScanEquippedGear()
    self.equippedGear = {}
    self:DebugPrint("=== SCANNING EQUIPPED GEAR ===")
    
    -- First, let's make sure we're actually finding equipped items
    local equippedCount = 0
    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            equippedCount = equippedCount + 1
        end
    end
    self:DebugPrint(string.format("Found %d equipped items total", equippedCount))
    
    for slot = 1, 18 do
        local itemLink = GetInventoryItemLink("player", slot)
        if itemLink then
            local itemName, _, _, itemLevel = GetItemInfo(itemLink)
            self:DebugPrint(string.format("Scanning equipped slot %d: %s (ilvl %d)", slot, itemName or "Unknown", itemLevel or 0))
            
            local stats = self:GetItemStats(itemLink, true) -- true = equipped item
            
            self.equippedGear[slot] = { 
                link = itemLink, 
                stats = stats, 
                score = self:CalculateItemScore(stats)
            }
            
            -- Enhanced debug output for weapons
            if slot == 16 or slot == 17 then
                self:DebugPrint(string.format("  Weapon slot %d [%s] ilvl %d:", slot, itemName or "Unknown", itemLevel or 0))
                if next(stats) then
                    self:DebugPrint("  Stats found:")
                    for stat, value in pairs(stats) do
                        self:DebugPrint(string.format("    %s: %d", stat, value))
                    end
                else
                    self:DebugPrint("  WARNING: No stats found for equipped weapon!")
                end
                self:DebugPrint(string.format("  Calculated Score: %.2f", self.equippedGear[slot].score))
                
                -- Also show the weights being used
                local weights, scaleName = self:GetCurrentStatWeights()
                self:DebugPrint("  Using weights from: " .. scaleName)
                for stat, value in pairs(stats) do
                    local weight = weights[stat] or 0
                    self:DebugPrint(string.format("    %s: %d * %.2f = %.2f", stat, value, weight, value * weight))
                end
            else
                self:DebugPrint(string.format("  Equipped slot %d [%s] ilvl %d: Score %.2f", 
                    slot, itemName or "Unknown", itemLevel or 0, self.equippedGear[slot].score))
            end
        end
    end
    
    self:DebugPrint("=== EQUIPPED GEAR SCAN COMPLETE ===")
end

function GO:CanPlayerUseItem(itemLink)
    if not itemLink then return false end
    
    local itemLevel, itemMinLevel = select(4, GetItemInfo(itemLink)), select(5, GetItemInfo(itemLink))
    local playerLevel = UnitLevel("player")
    
    if itemMinLevel and playerLevel < itemMinLevel then
        self:DebugPrint(string.format("Item [%s] requires level %d, player is level %d - CANNOT USE", 
            itemLink, itemMinLevel, playerLevel))
        return false
    end
    
    return true
end

function GO:IsItemEquippableByClass(itemLink)
    local itemName = GetItemInfo(itemLink)
    local _, _, _, equipSlot, _, classID, subClassID = C_Item.GetItemInfoInstant(itemLink)
    
    -- DEBUG: Special logging for potential Warglaives
    if itemName and itemName:lower():find("glaive") then
        self:DebugPrint(string.format("WARGLAIVE DEBUG: [%s] equipSlot=%s classID=%s subClassID=%s", 
            itemName, tostring(equipSlot), tostring(classID), tostring(subClassID)))
    end
    
    if not equipSlot or equipSlot == "INVTYPE_NON_EQUIP" then
        return false
    end
    
    if not self:CanPlayerUseItem(itemLink) then
        return false
    end
    
    if not self.playerClass or not self.classEquipmentRules[self.playerClass] then
        return false
    end

    if equipSlot == "INVTYPE_NECK" or equipSlot == "INVTYPE_CLOAK" or equipSlot == "INVTYPE_FINGER" or equipSlot == "INVTYPE_TRINKET" or equipSlot == "INVTYPE_SHIRT" or equipSlot == "INVTYPE_TABARD" then
        return true
    end

    local rules = self.classEquipmentRules[self.playerClass]
    
    if not classID or not subClassID then
        -- DEBUG: Log missing IDs for Warglaives
        if itemName and itemName:lower():find("glaive") then
            self:DebugPrint(string.format("WARGLAIVE DEBUG: Missing classID or subClassID for [%s]", itemName))
        end
        return false
    end

    local canEquip = rules[classID] and rules[classID][subClassID]
    
    -- DEBUG: Log the equipment check result for Warglaives
    if itemName and itemName:lower():find("glaive") then
        self:DebugPrint(string.format("WARGLAIVE DEBUG: [%s] Can equip: %s (classID=%s, subClassID=%s, playerClass=%s)", 
            itemName, tostring(canEquip), tostring(classID), tostring(subClassID), tostring(self.playerClass)))
        if rules[classID] then
            self:DebugPrint(string.format("WARGLAIVE DEBUG: Available subclasses for classID %s: %s", 
                tostring(classID), table.concat(self:GetTableKeys(rules[classID]), ", ")))
        end
    end

    return canEquip
end

-- Helper function to get table keys (add this to Equipment.lua)
function GO:GetTableKeys(t)
    local keys = {}
    for k, v in pairs(t) do
        if v then
            table.insert(keys, tostring(k))
        end
    end
    return keys
end

function GO:ScanBagItemsWithOptions()
    self.bagItems = {}
    self:DebugPrint("=== ENHANCED BAG SCAN START ===")
    
    local totalItemsFound = 0
    local totalItemsProcessed = 0
    
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo and itemInfo.hyperlink then
                totalItemsFound = totalItemsFound + 1
                
                -- FIX: Use itemInfo.itemID directly as it's more reliable and efficient
                local itemID = itemInfo.itemID
                
                -- Check if item is on the block list
                if self:IsItemBlocked(itemID) then
                    self:DebugPrint(string.format("SKIPPED Blocked Item: [%s]", itemInfo.hyperlink))
                elseif PawnStarOmegaDB.ignoreBoE and self:IsItemBindOnEquip(itemInfo.hyperlink) then
                    self:DebugPrint(string.format("SKIPPED BoE: [%s]", itemInfo.hyperlink))
                else
                    if self:IsItemEquippableByClass(itemInfo.hyperlink) then
                        local equipSlots = self:GetItemEquipSlot(itemInfo.hyperlink)
                        
                        if equipSlots then
                            local stats = self:GetItemStats(itemInfo.hyperlink, false) -- false = bag item
                            local score = self:CalculateItemScore(stats)
                            local slotsToCheck = type(equipSlots) == "table" and equipSlots or {equipSlots}
                            
                            for _, slotNum in ipairs(slotsToCheck) do
                                local shouldAdd = true
                                local skipReason = ""
                                
                                if PawnStarOmegaDB.showOneRing and slotNum == 12 then
                                    shouldAdd = false
                                    skipReason = "showOneRing option"
                                end
                                
                                if shouldAdd then
                                    if not self.bagItems[slotNum] then 
                                        self.bagItems[slotNum] = {} 
                                    end
                                    
                                    -- Enhanced debug for weapons in bags
                                    if slotNum == 16 or slotNum == 17 then
                                        local itemName = GetItemInfo(itemInfo.hyperlink)
                                        self:DebugPrint(string.format("  Adding WEAPON to slot %d: %s", slotNum, itemName or "Unknown"))
                                        self:DebugPrint("  Stats found:")
                                        for stat, value in pairs(stats) do
                                            self:DebugPrint(string.format("    %s: %d", stat, value))
                                        end
                                        self:DebugPrint(string.format("  Calculated Score: %.2f", score))
                                    end
                                    
                                    table.insert(self.bagItems[slotNum], {
                                        link = itemInfo.hyperlink, 
                                        stats = stats,
                                        score = score, 
                                        bag = bag, 
                                        slot = slot,
                                        guid = itemInfo.itemGUID, -- FIX: Store the unique item GUID
                                        isBoE = self:IsItemBindOnEquip(itemInfo.hyperlink)
                                    })
                                    totalItemsProcessed = totalItemsProcessed + 1
                                else
                                    self:DebugPrint(string.format("SKIPPED: [%s] for slot %d (%s)", 
                                        itemInfo.hyperlink, slotNum, skipReason))
                                end
                            end
                        else
                            self:DebugPrint(string.format("Could not determine equip slots for [%s]", itemInfo.hyperlink))
                        end
                    end
                end
            end
        end
    end
    
    self:DebugPrint(string.format("=== BAG SCAN END - Found %d items, processed %d ===", totalItemsFound, totalItemsProcessed))
end

function GO:GetItemStats(itemLink)
    local stats = {}
    local itemName = GetItemInfo(itemLink)
    self:DebugPrint(string.format("  Getting stats for: %s", itemName or "Unknown"))

    -- Preferred Method: C_Item.GetItemStats API for efficiency
    local itemStatsTable = C_Item.GetItemStats(itemLink)
    if itemStatsTable and next(itemStatsTable) then
        self:DebugPrint("    Using C_Item.GetItemStats API")
        for statName, value in pairs(itemStatsTable) do
            if statName == "ITEM_MOD_STAMINA_SHORT" then stats.stamina = value
            elseif statName == "ITEM_MOD_INTELLECT_SHORT" then stats.intellect = value
            elseif statName == "ITEM_MOD_AGILITY_SHORT" then stats.agility = value
            elseif statName == "ITEM_MOD_STRENGTH_SHORT" then stats.strength = value
            elseif statName == "ITEM_MOD_HASTE_RATING_SHORT" then stats.haste = value
            elseif statName == "ITEM_MOD_CRITICAL_STRIKE_RATING_SHORT" then stats.criticalStrike = value
            elseif statName == "ITEM_MOD_MASTERY_RATING_SHORT" then stats.mastery = value
            elseif statName == "ITEM_MOD_VERSATILITY" then stats.versatility = value
            end
        end
    else
        -- Fallback Method: Tooltip scanning for items where the API might fail
        self:DebugPrint("    C_Item.GetItemStats failed, falling back to tooltip scan")
        if not self.scanTooltip then
            self.scanTooltip = CreateFrame("GameTooltip", "PawnStarScanTooltip", nil, "GameTooltipTemplate")
            self.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
        end
        
        self.scanTooltip:ClearLines()
        self.scanTooltip:SetHyperlink(itemLink)
        
        local numLines = self.scanTooltip:NumLines()
        for i = 1, numLines do
            local line = _G["PawnStarScanTooltipTextLeft" .. i]
            if line then
                local text = line:GetText()
                if text then
                    local value, statType = text:match("%+(%d+) (.+)")
                    if value and statType then
                        value = tonumber(value)
                        if statType:find("Strength") then stats.strength = (stats.strength or 0) + value
                        elseif statType:find("Agility") then stats.agility = (stats.agility or 0) + value
                        elseif statType:find("Intellect") then stats.intellect = (stats.intellect or 0) + value
                        elseif statType:find("Stamina") then stats.stamina = (stats.stamina or 0) + value
                        elseif statType:find("Critical Strike") then stats.criticalStrike = (stats.criticalStrike or 0) + value
                        elseif statType:find("Haste") then stats.haste = (stats.haste or 0) + value
                        elseif statType:find("Mastery") then stats.mastery = (stats.mastery or 0) + value
                        elseif statType:find("Versatility") then stats.versatility = (stats.versatility or 0) + value
                        end
                    end
                    
                    local armor = text:match("(%d+) Armor")
                    if armor then 
                        stats.armor = tonumber(armor)
                    end
                end
            end
        end
    end

    -- Summary of stats found
    local statCount = 0
    for _ in pairs(stats) do
        statCount = statCount + 1
    end
    self:DebugPrint(string.format("  Total stats found: %d", statCount))
    
    return stats
end


function GO:CalculateItemScore(stats)
    local weights, scaleName = self:GetCurrentStatWeights()
    local score = 0
    
    self:DebugPrint(string.format("  Calculating score with weights from: %s", scaleName))
    
    for stat, value in pairs(stats) do
        if weights[stat] then
            local contribution = value * weights[stat]
            score = score + contribution
            self:DebugPrint(string.format("    %s: %d * %.2f = %.2f", stat, value, weights[stat], contribution))
        else
            self:DebugPrint(string.format("    %s: %d (no weight)", stat, value))
        end
    end
    
    self:DebugPrint(string.format("  Total score: %.2f", score))
    
    return score
end

function GO:IsItemBindOnEquip(itemLink)
    if not itemLink then return false end
    
    if not self.bindScanTooltip then
        self.bindScanTooltip = CreateFrame("GameTooltip", "PawnStarBindScanTooltip", nil, "GameTooltipTemplate")
        self.bindScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    
    self.bindScanTooltip:ClearLines()
    self.bindScanTooltip:SetHyperlink(itemLink)
    
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

function GO:IsInCombat()
    return InCombatLockdown()
end

function GO:IsInSafeZone()
    return IsResting()
end

function GO:ScanGearWithOptions()
    if PawnStarOmegaDB.pauseInCombat and self:IsInCombat() then
        self:DebugPrint("Gear scan skipped - player is in combat and pauseInCombat is enabled")
        return
    end
    
    if PawnStarOmegaDB.safeZonesOnly and not self:IsInSafeZone() then
        self:DebugPrint("Gear scan skipped - player not in safe zone and safeZonesOnly is enabled")
        return
    end
    
    self:DebugPrint("ScanGear initiated with option checks passed.")
    self:ScanEquippedGear()
    self:ScanBagItemsWithOptions()
    self:CompareGearWithOptions()
end

function GO:CompareGearWithOptions()
    local upgrades = {}

    -- Handle non-weapon slots
    for slotNum = 1, 18 do
        if slotNum == 4 or slotNum == 13 or slotNum == 14 or slotNum == 18 or slotNum == 16 or slotNum == 17 then
            -- Skip non-gear slots (shirt, trinkets, ranged, and weapons which are handled separately)
        else
            if PawnStarOmegaDB.showOneRing and slotNum == 12 then
                -- Skip ring slot 2 if option enabled
            else
                local equippedItem = self.equippedGear[slotNum]

                if self.bagItems[slotNum] then
                    for _, bagItem in ipairs(self.bagItems[slotNum]) do
                        if self:IsValidUpgrade(bagItem, equippedItem) then
                            local improvement = equippedItem and (bagItem.score - equippedItem.score) or bagItem.score
                            table.insert(upgrades, {
                                slot = slotNum,
                                upgrade = bagItem,
                                improvement = improvement
                            })
                        end
                    end
                end
            end
        end
    end

    -- Handle weapon upgrades
    local weaponUpgrades = self:CompareWeaponSlots(self.bagItems)
    for _, upgrade in ipairs(weaponUpgrades) do
        table.insert(upgrades, upgrade)
    end

    table.sort(upgrades, function(a, b) return a.improvement > b.improvement end)

    if #upgrades > 0 and not self.frame:IsShown() then
        self:PlayUpgradeSound()
    end

    self:DisplayUpgrades(upgrades)
end


function GO:IsValidUpgrade(bagItem, equippedItem)
    if not equippedItem then
        return true
    end

    return bagItem.score > equippedItem.score
end

-- Legacy compatibility functions
function GO:ScanGear()
    self:ScanGearWithOptions()
end

function GO:CompareGear()
    self:CompareGearWithOptions()
end
