-- WeaponLogic.lua - All weapon-specific logic and comparisons

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]

--[[
    Utility and Class/Spec check functions are moved here to ensure they are
    defined before being called by other functions in this file.
--]]
function GO:GetPlayerRole()
    local specID = GetSpecialization()
    if not specID or specID == 0 then return "UNKNOWN" end
    
    local _, _, _, _, role = GetSpecializationInfo(specID)
    return role
end

function GO:IsCasterDPS()
    local specID = GetSpecialization()
    if not specID or specID == 0 then return false end
    
    local _, classFile = UnitClass("player")
    local casterClasses = {
        MAGE = true,
        WARLOCK = true,
        PRIEST = true,
        SHAMAN = true,
        DRUID = true,
        EVOKER = true,
    }
    
    return casterClasses[classFile] and self:GetPlayerRole() == "DAMAGER"
end

function GO:CanUse2HandedWeapons()
    local specID = GetSpecialization()
    local _, classFile = UnitClass("player")

    -- Fallback for characters without a specialization (pre-level 10)
    if not specID or specID == 0 then
        local lowLevelTwoHandedClasses = {
            WARRIOR = true, PALADIN = true, DEATHKNIGHT = true, HUNTER = true,
            MAGE = true, WARLOCK = true, PRIEST = true, DRUID = true, MONK = true,
            EVOKER = true, SHAMAN = true
        }
        return lowLevelTwoHandedClasses[classFile] or false
    end
    
    local specName = select(2, GetSpecializationInfo(specID))
    
    -- Classes that can use 2H weapons in certain specs
    local twoHandedSpecs = {
        WARRIOR = { "Arms", "Fury" },
        PALADIN = { "Retribution" },
        DEATHKNIGHT = { "Blood", "Frost", "Unholy" },
        HUNTER = { "Survival", "Beast Mastery", "Marksmanship" },
        SHAMAN = { "Enhancement" },
    }
    
    -- Classes that can always use 2H weapons (casters with staves)
    local alwaysTwoHandedClasses = {
        MAGE = true, WARLOCK = true, PRIEST = true, DRUID = true, MONK = true, EVOKER = true
    }
    
    if alwaysTwoHandedClasses[classFile] then
        return true
    end
    
    if twoHandedSpecs[classFile] then
        for _, allowedSpec in ipairs(twoHandedSpecs[classFile]) do
            if specName == allowedSpec then return true end
        end
    end
    return false
end

function GO:CanDualWieldWeapons()
    local specID = GetSpecialization()
    local _, classFile = UnitClass("player")

    -- Fallback for characters without a specialization (pre-level 10)
    if not specID or specID == 0 then
        local lowLevelDualWieldClasses = {
            ROGUE = true,
            SHAMAN = true,
            WARRIOR = true,
            DEATHKNIGHT = true,
            MONK = true,
            DEMONHUNTER = true,
            HUNTER = true
        }
        return lowLevelDualWieldClasses[classFile] or false
    end
    
    local specName = select(2, GetSpecializationInfo(specID))
    
    local dualWieldSpecs = {
        ROGUE = { "Assassination", "Outlaw", "Subtlety" },
        SHAMAN = { "Enhancement" },
        WARRIOR = { "Fury" },
        DEATHKNIGHT = { "Frost" },
        MONK = { "Windwalker" },
        DEMONHUNTER = { "Havoc", "Vengeance" },
        HUNTER = { "Survival" }
    }
    
    if dualWieldSpecs[classFile] then
        for _, preferredSpec in ipairs(dualWieldSpecs[classFile]) do
            if specName == preferredSpec then return true end
        end
    end
    return false
end


function GO:PrefersDualWield()
    return self:CanDualWieldWeapons()
end


-- Enhanced function to properly detect weapon and off-hand item types
function GO:GetItemEquipSlot(itemLink)
    local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemLink)

    if equipSlot == "INVTYPE_WEAPON" and self:CanDualWieldWeapons() then
        return {16, 17}
    end
    
    local slotMap = {
        INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_BODY = 4,
        INVTYPE_CHEST = 5, INVTYPE_ROBE = 5,
        INVTYPE_WAIST = 6, INVTYPE_LEGS = 7, INVTYPE_FEET = 8, INVTYPE_WRIST = 9, INVTYPE_HAND = 10,
        INVTYPE_FINGER = {11, 12}, INVTYPE_TRINKET = {13, 14}, INVTYPE_CLOAK = 15,
        INVTYPE_WEAPON = 16,           
        INVTYPE_WEAPONMAINHAND = 16,   
        INVTYPE_2HWEAPON = 16,         
        INVTYPE_RANGED = 18,           
        INVTYPE_WEAPONOFFHAND = 17,    
        INVTYPE_SHIELD = 17,           
        INVTYPE_HOLDABLE = 17,         
    }
    
    return slotMap[equipSlot]
end

function GO:GetDetailedItemType(itemLink)
    if not itemLink then return "UNKNOWN" end
    
    local _, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemLink)
    local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemLink)
    
    local itemType = {
        equipSlot = equipSlot,
        classID = classID,
        subClassID = subClassID,
        is2H = false,
        is1H = false,
        isOffHandWeapon = false,
        isShield = false,
        isFocus = false,
        isRanged = false
    }
    
    if equipSlot == "INVTYPE_2HWEAPON" then
        itemType.is2H = true
    elseif equipSlot == "INVTYPE_WEAPON" or equipSlot == "INVTYPE_WEAPONMAINHAND" then
        itemType.is1H = true
    elseif equipSlot == "INVTYPE_WEAPONOFFHAND" then
        itemType.isOffHandWeapon = true
    elseif equipSlot == "INVTYPE_SHIELD" then
        itemType.isShield = true
    elseif equipSlot == "INVTYPE_HOLDABLE" then
        itemType.isFocus = true
    elseif equipSlot == "INVTYPE_RANGED" then
        itemType.isRanged = true
    end
    
    return itemType
end

function GO:IsTwoHandedWeapon(itemLink)
    local itemType = self:GetDetailedItemType(itemLink)
    return itemType.is2H
end

function GO:IsOneHandedWeapon(itemLink)
    local itemType = self:GetDetailedItemType(itemLink)
    return itemType.is1H
end

function GO:IsOffHandWeapon(itemLink)
    local itemType = self:GetDetailedItemType(itemLink)
    return itemType.isOffHandWeapon
end

function GO:IsShield(itemLink)
    local itemType = self:GetDetailedItemType(itemLink)
    return itemType.isShield
end

function GO:IsFocusItem(itemLink)
    local itemType = self:GetDetailedItemType(itemLink)
    return itemType.isFocus
end

function GO:IsOffHandItem(itemLink)
    local itemType = self:GetDetailedItemType(itemLink)
    return itemType.isOffHandWeapon or itemType.isShield or itemType.isFocus
end

function GO:IsValidWeaponSetup(mainHand, offHand)
    local role = self:GetPlayerRole()
    local _, classFile = UnitClass("player")
    local specID = GetSpecialization()
    local specName = specID and specID ~= 0 and select(2, GetSpecializationInfo(specID)) or "Unknown"
    
    if not mainHand and not offHand then
        return false
    end
    
    if not mainHand and offHand then
        return false
    end
    
    if not mainHand then return false end
    
    if self:IsTwoHandedWeapon(mainHand) then
        if offHand then 
            return false 
        end
        return self:CanUse2HandedWeapons()
    end
    
    if self:IsOneHandedWeapon(mainHand) then
        if not offHand then
            return true
        end
        
        if self:IsShield(offHand) then
            local canUseShield = role == "TANK" or 
                                (classFile == "PALADIN") or 
                                (classFile == "WARRIOR") or
                                (classFile == "SHAMAN" and specName ~= "Enhancement")
            return canUseShield
        elseif self:IsFocusItem(offHand) then
            local canUseFocus = role == "HEALER" or 
                              (role == "DAMAGER" and self:IsCasterDPS())
            return canUseFocus
        elseif self:IsOffHandWeapon(offHand) or self:IsOneHandedWeapon(offHand) then
            return self:CanDualWieldWeapons()
        end
    end
    
    return false
end

function GO:CompareWeaponSlots(bagItems)
    local upgrades = {}
    local currentMainHand = self.equippedGear[16]
    local currentOffHand = self.equippedGear[17]
    
    self:DebugPrint("=== WEAPON COMPARISON START ===")
    
    local currentScore = 0
    if currentMainHand then currentScore = currentScore + currentMainHand.score end
    if currentOffHand then currentScore = currentScore + currentOffHand.score end
    
    local possibleConfigs = {}
    
    if currentMainHand and self:IsTwoHandedWeapon(currentMainHand.link) then
        self:DebugPrint("SCENARIO 1: 2H weapon equipped")
        
        if bagItems[16] then
            for _, bagItem in ipairs(bagItems[16]) do
                if self:IsTwoHandedWeapon(bagItem.link) then
                    local currentItemID = select(1, C_Item.GetItemInfoInstant(currentMainHand.link))
                    local bagItemID = select(1, C_Item.GetItemInfoInstant(bagItem.link))
                    if currentItemID == bagItemID then
                        self:DebugPrint(string.format("Skipping 2H weapon - same as equipped: %s", bagItem.link))
                    elseif self:IsValidWeaponSetup(bagItem.link, nil) and bagItem.score > currentScore then
                        table.insert(possibleConfigs, {
                            type = "2H_UPGRADE",
                            score = bagItem.score,
                            mainHand = bagItem,
                            offHand = nil,
                            improvement = bagItem.score - currentScore
                        })
                        self:DebugPrint(string.format("Found 2H upgrade: %s (improvement: %.2f)", 
                            bagItem.link, bagItem.score - currentScore))
                    end
                end
            end
        end
        
    elseif currentMainHand and self:IsOneHandedWeapon(currentMainHand.link) then
        self:DebugPrint("SCENARIO 2: 1H weapon equipped")
        
        if bagItems[16] then
            for _, bagItem in ipairs(bagItems[16]) do
                if self:IsTwoHandedWeapon(bagItem.link) then
                    if self:IsValidWeaponSetup(bagItem.link, nil) and bagItem.score > currentScore then
                        table.insert(possibleConfigs, {
                            type = "2H_REPLACES_1H",
                            score = bagItem.score,
                            mainHand = bagItem,
                            offHand = nil,
                            improvement = bagItem.score - currentScore
                        })
                    end
                end
            end
        end
        
        if bagItems[16] then
            for _, bagItem in ipairs(bagItems[16]) do
                if self:IsOneHandedWeapon(bagItem.link) then
                    local currentItemID = currentMainHand and select(1, C_Item.GetItemInfoInstant(currentMainHand.link))
                    local bagItemID = select(1, C_Item.GetItemInfoInstant(bagItem.link))

                    if not (currentItemID and bagItemID and currentItemID == bagItemID) then
                        local newScore = bagItem.score + (currentOffHand and currentOffHand.score or 0)
                        if newScore > currentScore then
                            table.insert(possibleConfigs, {
                                type = "MH_UPGRADE",
                                score = newScore,
                                mainHand = bagItem,
                                offHand = currentOffHand,
                                improvement = newScore - currentScore
                            })
                        end
                    end
                end
            end
        end
        
        if not currentOffHand then
            if bagItems[17] then
                for _, bagItem in ipairs(bagItems[17]) do
                    if self:IsOffHandItem(bagItem.link) or self:IsOneHandedWeapon(bagItem.link) then
                        if self:IsValidWeaponSetup(currentMainHand.link, bagItem.link) then
                            local newScore = currentMainHand.score + bagItem.score
                            if newScore > currentScore then
                                table.insert(possibleConfigs, {
                                    type = "ADD_OH_TO_1H",
                                    score = newScore,
                                    mainHand = currentMainHand,
                                    offHand = bagItem,
                                    improvement = bagItem.score,
                                    isOffHandOnly = true
                                })
                            end
                        end
                    end
                end
            end
        else
            if bagItems[17] then
                for _, bagItem in ipairs(bagItems[17]) do
                    if self:IsOffHandItem(bagItem.link) or self:IsOneHandedWeapon(bagItem.link) then
                        local newScore = currentMainHand.score + bagItem.score
                        if self:IsValidWeaponSetup(currentMainHand.link, bagItem.link) and newScore > currentScore then
                            table.insert(possibleConfigs, {
                                type = "OH_UPGRADE", 
                                score = newScore,
                                mainHand = currentMainHand,
                                offHand = bagItem,
                                improvement = newScore - currentScore
                            })
                        end
                    end
                end
            end
        end
    
    elseif not currentMainHand and currentOffHand then
        self:DebugPrint("SCENARIO 3: Only off-hand equipped")
        
        if bagItems[16] then
            for _, bagItem in ipairs(bagItems[16]) do
                if self:IsTwoHandedWeapon(bagItem.link) then
                    if self:IsValidWeaponSetup(bagItem.link, nil) and bagItem.score > currentScore then
                        table.insert(possibleConfigs, {
                            type = "2H_REPLACES_OH",
                            score = bagItem.score,
                            mainHand = bagItem,
                            offHand = nil,
                            improvement = bagItem.score - currentScore
                        })
                    end
                end
            end
        end
        
        if bagItems[16] then
            for _, bagItem in ipairs(bagItems[16]) do
                if self:IsOneHandedWeapon(bagItem.link) then
                    local newScore = bagItem.score + currentOffHand.score
                    if self:IsValidWeaponSetup(bagItem.link, currentOffHand.link) and newScore > currentScore then
                        table.insert(possibleConfigs, {
                            type = "MH_FOR_OH",
                            score = newScore,
                            mainHand = bagItem,
                            offHand = currentOffHand,
                            improvement = newScore - currentScore
                        })
                    end
                end
            end
        end
    
    else
        self:DebugPrint("SCENARIO 4: No weapons equipped - Refactored Logic")
        
        local bestSetup = nil
        local bestScore = 0

        if bagItems[16] then
            for _, bagItem in ipairs(bagItems[16]) do
                if self:IsTwoHandedWeapon(bagItem.link) then
                    if self:IsValidWeaponSetup(bagItem.link, nil) and bagItem.score > bestScore then
                        bestScore = bagItem.score
                        bestSetup = {
                            type = "FIRST_2H",
                            score = bagItem.score,
                            mainHand = bagItem,
                            offHand = nil,
                            improvement = bagItem.score
                        }
                    end
                end
            end
        end

        if bagItems[16] then
            for _, mainHandItem in ipairs(bagItems[16]) do
                if self:IsOneHandedWeapon(mainHandItem.link) then
                    if self:IsValidWeaponSetup(mainHandItem.link, nil) and mainHandItem.score > bestScore then
                         bestScore = mainHandItem.score
                         bestSetup = {
                            type = "FIRST_1H",
                            score = mainHandItem.score,
                            mainHand = mainHandItem,
                            offHand = nil,
                            improvement = mainHandItem.score
                         }
                    end
                end
            end
        end
        
        if bestSetup then
            self:DebugPrint(string.format("Found best initial setup: type=%s, score=%.2f", bestSetup.type, bestSetup.score))
            table.insert(possibleConfigs, bestSetup)
        end
    end
    
    table.sort(possibleConfigs, function(a, b) return a.improvement > b.improvement end)
    
    for _, config in ipairs(possibleConfigs) do
        if config.improvement > 0 then
            local upgrade = {
                improvement = config.improvement,
                configType = config.type,
                replaces = (config.offHand or config.type:find("2H")) and "both" or "mainhand"
            }
            
            if config.type == "OH_UPGRADE" or config.type == "ADD_OH_TO_1H" then
                upgrade.upgrade = config.offHand
                upgrade.slot = 17
                if config.type == "ADD_OH_TO_1H" then
                    upgrade.isOffHandOnly = true
                end
                 self:DebugPrint(string.format("Adding OFF-HAND upgrade: %s (improvement: %.2f)", 
                    config.offHand.link, config.improvement))
            elseif config.mainHand then
                upgrade.upgrade = config.mainHand
                upgrade.slot = 16
                self:DebugPrint(string.format("Adding SINGLE weapon upgrade: %s (improvement: %.2f)", 
                    config.mainHand.link, config.improvement))
            end
            
            table.insert(upgrades, upgrade)
        end
    end
    
    self:DebugPrint(string.format("=== WEAPON COMPARISON END - Found %d upgrades ===", #upgrades))
    return upgrades
end

function GO:CompareGearWithOptions()
    local upgrades = {}
    
    for slotNum = 1, 18 do
        if slotNum == 4 or slotNum == 13 or slotNum == 14 or slotNum == 16 or slotNum == 17 or slotNum == 18 then
            -- Skip non-gear and weapon slots
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
    
    local weaponUpgrades = self:CompareWeaponSlots(self.bagItems)
    for _, upgrade in ipairs(weaponUpgrades) do
        table.insert(upgrades, upgrade)
    end

    table.sort(upgrades, function(a, b) return a.improvement > b.improvement end)
    
    if #upgrades > 0 then
        if not self.frame:IsShown() then
            self:PlayUpgradeSound()
        end
        -- If scanning was paused, restart it because we found an upgrade.
        if self.scanningPaused then
            self:StartScanning()
        end
    else
        -- No upgrades found, pause the periodic scan to save resources.
        if not self.scanningPaused then
            self:StopScanning()
        end
    end
    
    self:DisplayUpgrades(upgrades)
end

function GO:IsValidUpgrade(bagItem, equippedItem)
    if not equippedItem then 
        return true 
    end
    
    return bagItem.score > equippedItem.score
end
