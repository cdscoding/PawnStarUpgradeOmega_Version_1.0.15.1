-- Display.lua - All UI display and upgrade presentation logic

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]

function GO:DisplayUpgrades(upgrades)
    -- Clear previous content
    self.content:SetScript("OnUpdate", nil)
    for i = 1, self.content:GetNumChildren() do
        select(i, self.content:GetChildren()):Hide()
    end

    if #upgrades > 0 then
        self.frame:Show()
    else
        self.frame:Hide()
        return
    end

    -- Reduced starting offset by 50%
    local yOffset = -5 

    for i, upgrade in ipairs(upgrades) do
        local isWeaponUpgrade = upgrade.bagItems or upgrade.configType or upgrade.replaces

        if isWeaponUpgrade then
            self:CreateWeaponUpgradeDisplay(upgrade, yOffset)
            yOffset = yOffset - 25 -- Reduced from 50
        else
            self:CreateRegularUpgradeDisplay(upgrade, yOffset)
            yOffset = yOffset - 22.5 -- Reduced from 45
        end
    end

    self.content:SetHeight(math.abs(yOffset))
end

function GO:CreateRegularUpgradeDisplay(upgrade, yOffset)
    local content = self.content

    -- Reduced size by 50% and adjusted point
    local iconFrame = CreateFrame("Button", nil, content)
    iconFrame:SetSize(19, 19) -- Reduced from 38, 38
    iconFrame:SetPoint("TOPLEFT", 7.5, yOffset) -- Reduced from 15

    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)

    local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(upgrade.upgrade.link)
    if itemIcon then
        iconTexture:SetTexture(itemIcon)
    end

    iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(upgrade.upgrade.link)
        GameTooltip:SetFrameStrata("TOOLTIP")
        GameTooltip:SetFrameLevel(50) -- Ensure tooltip is on top
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Increased width from 310 to 410
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetSize(410, 20) 
    button:SetPoint("LEFT", iconFrame, "RIGHT", 5, 0) 

    button.bag = upgrade.upgrade.bag
    button.slot = upgrade.upgrade.slot

    local slotName = self.slotNames[upgrade.slot] or ("Slot " .. upgrade.slot)
    local improvementText = string.format("+%.1f", upgrade.improvement)

    local boEIndicator = ""
    if upgrade.upgrade.isBoE then
        boEIndicator = " |cffff6600(BoE)|r"
    end

    local levelWarning = ""
    local _, _, _, _, itemMinLevel = GetItemInfo(upgrade.upgrade.link)
    local playerLevel = UnitLevel("player")
    if itemMinLevel and playerLevel < itemMinLevel then
        levelWarning = string.format(" |cffff0000(Req: %d)|r", itemMinLevel)
    end

    local _, _, _, bagIlvl = GetItemInfo(upgrade.upgrade.link)
    local ilvlText = bagIlvl and string.format(" |cff888888[%d]|r", bagIlvl) or ""

    button:SetText(string.format("%s (%s): %s%s%s%s", slotName, improvementText, upgrade.upgrade.link, ilvlText, boEIndicator, levelWarning))
    -- Note: Retaining GameFontNormalSmall as it's the smallest standard font object available.
    button:SetNormalFontObject(GameFontNormalSmall) 
    button:SetHighlightFontObject(GameFontNormalSmall)
    button:GetFontString():SetJustifyH("LEFT")
    button:GetFontString():SetPoint("LEFT", 5, 0) 

    button:SetScript("OnClick", function(self)
        C_Container.UseContainerItem(self.bag, self.slot)
        GO.frame:Hide()
        C_Timer.After(1.5, function() GO:ScanGearWithOptions() end)
    end)

    -- Block Button - Increased width from 25 to 40
    local blockButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    blockButton:SetSize(40, 20) 
    blockButton:SetPoint("LEFT", button, "RIGHT", 2.5, 0) 
    blockButton:SetText("Block")
    blockButton:SetScript("OnClick", function()
        -- FIX: Use a reliable method to get itemID from a hyperlink
        local itemID = select(1, C_Item.GetItemInfoInstant(upgrade.upgrade.link))
        GO:BlockItem(itemID, upgrade.upgrade.link)
    end)
end

function GO:CreateWeaponUpgradeDisplay(upgrade, yOffset)
    if upgrade.upgrade then
        self:CreateSingleWeaponUpgradeDisplay(upgrade, yOffset)
    end
end

function GO:CreateSingleWeaponUpgradeDisplay(upgrade, yOffset)
    local content = self.content

    -- Reduced size by 50% and adjusted point
    local iconFrame = CreateFrame("Button", nil, content)
    iconFrame:SetSize(19, 19) -- Reduced from 38, 38
    iconFrame:SetPoint("TOPLEFT", 7.5, yOffset) -- Reduced from 15

    local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints(iconFrame)

    local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(upgrade.upgrade.link)
    if itemIcon then
        iconTexture:SetTexture(itemIcon)
    end

    iconFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(upgrade.upgrade.link)
        GameTooltip:SetFrameStrata("TOOLTIP")
        GameTooltip:SetFrameLevel(50) -- Ensure tooltip is on top
        GameTooltip:Show()
    end)
    iconFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Increased width from 310 to 410
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetSize(410, 20)
    button:SetPoint("LEFT", iconFrame, "RIGHT", 5, 0) 

    -- Store the bag and slot from the upgrade item's data
    local itemToEquip = upgrade.upgrade
    button:SetAttribute("bag", itemToEquip.bag)
    button:SetAttribute("slot", itemToEquip.slot)

    local slotName = self:GetWeaponSlotDisplayName(upgrade)
    local improvementText = string.format("+%.1f", upgrade.improvement)

    local boEIndicator = ""
    if itemToEquip.isBoE then
        boEIndicator = " |cffff6600(BoE)|r"
    end

    local levelWarning = ""
    local _, _, _, _, itemMinLevel = GetItemInfo(itemToEquip.link)
    local playerLevel = UnitLevel("player")
    if itemMinLevel and playerLevel < itemMinLevel then
        levelWarning = string.format(" |cffff0000(Req: %d)|r", itemMinLevel)
    end

    local _, _, _, bagIlvl = GetItemInfo(itemToEquip.link)
    local ilvlText = bagIlvl and string.format(" |cff888888[%d]|r", bagIlvl) or ""

    button:SetText(string.format("%s (%s): %s%s%s%s", slotName, improvementText, itemToEquip.link, ilvlText, boEIndicator, levelWarning))
    -- Note: Retaining GameFontNormalSmall as it's the smallest standard font object available.
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontNormalSmall)
    button:GetFontString():SetJustifyH("LEFT")
    button:GetFontString():SetPoint("LEFT", 5, 0) 

    button:SetScript("OnClick", function(self)
        local bag = self:GetAttribute("bag")
        local slot = self:GetAttribute("slot")
        if bag and slot then
            C_Container.UseContainerItem(bag, slot)
            GO.frame:Hide()
            C_Timer.After(1.5, function() GO:ScanGearWithOptions() end)
        else
            GO:DebugPrint("Error: Button is missing bag/slot attributes for single weapon equip.")
        end
    end)

    -- Block Button - Increased width from 25 to 40
    local blockButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    blockButton:SetSize(40, 20) 
    blockButton:SetPoint("LEFT", button, "RIGHT", 2.5, 0) 
    blockButton:SetText("Block")
    blockButton:SetScript("OnClick", function()
        local itemID = select(1, C_Item.GetItemInfoInstant(itemToEquip.link))
        GO:BlockItem(itemID, itemToEquip.link)
    end)
end

function GO:GetWeaponSlotDisplayName(upgrade)
    if upgrade.replaces == "both" then
        if upgrade.configType and upgrade.configType:find("2H") then
            return "Weapon (2H)"
        else
            return "Main Hand & Off Hand"
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
