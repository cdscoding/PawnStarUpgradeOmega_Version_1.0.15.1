-- BlockedItems.lua - Handles the UI for displaying and managing blocked items.

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]
GO.BlockedItems = {}
local BlockedItems = GO.BlockedItems

local WIDGET_HEIGHT = 40
local WIDGET_SPACING = 5

function BlockedItems:OnInitialize()
    -- Initialization logic for the Blocked Items module, if any.
end

function BlockedItems:CreatePanel()
    if self.Frame then return end

    local f = CreateFrame("Frame", addonName .. "BlockedItemsFrame", UIParent, "BasicFrameTemplateWithInset")
    self.Frame = f
    f:SetSize(550, 510)
    f:SetPoint("CENTER")
    f:SetFrameStrata("TOOLTIP") -- Higher strata to appear over other windows
    f:SetFrameLevel(30) -- Ensure this is higher than other addon windows
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.TitleText:SetText("Blocked Items")
    
    -- Set strata for the close button to match the parent frame
    f.CloseButton:SetFrameStrata(f:GetFrameStrata())
    f.CloseButton:SetFrameLevel(f:GetFrameLevel() + 1)
    f.CloseButton:SetScript("OnClick", function() 
        BlockedItems:TogglePanel()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", addonName .. "BlockedItemsScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", addonName .. "BlockedItemsScrollContent")
    content:SetSize(500, 1)
    scrollFrame:SetScrollChild(content)
    self.Content = content

    content.widgets = {}

    content.noItemsText = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    content.noItemsText:SetPoint("TOP", 0, -20)
    content.noItemsText:SetText("No items are currently blocked.")
    content.noItemsText:Hide()

    f:Hide()
end

function BlockedItems:UpdatePanel()
    if not self.Frame or not self.Frame:IsShown() then return end

    local content = self.Content
    local yOffset = -10
    local widgetIndex = 1

    local blockedItems = PawnStarOmegaDB.blockedItems or {}
    if not next(blockedItems) then
        content.noItemsText:Show()
    else
        content.noItemsText:Hide()
    end

    for itemID, itemLink in pairs(blockedItems) do
        local widget = content.widgets[widgetIndex]
        if not widget then
            widget = {}
            content.widgets[widgetIndex] = widget

            -- Create background frame
            widget.background = CreateFrame("Frame", nil, content, "BackdropTemplate")
            widget.background:SetSize(500, WIDGET_HEIGHT)

            -- Item Icon
            widget.icon = widget.background:CreateTexture(nil, "ARTWORK")
            widget.icon:SetSize(36, 36)
            widget.icon:SetPoint("LEFT", 4, 0)

            -- Item Name/Link Text
            widget.text = widget.background:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            widget.text:SetPoint("LEFT", widget.icon, "RIGHT", 10, 0)
            widget.text:SetPoint("RIGHT", -40, 0)
            widget.text:SetJustifyH("LEFT")

            -- Unblock Button (X)
            widget.unblockButton = CreateFrame("Button", nil, widget.background, "UIPanelCloseButton")
            widget.unblockButton:SetSize(32, 32)
            widget.unblockButton:SetPoint("RIGHT", -5, 0)
        end

        widget.background:SetPoint("TOPLEFT", 5, yOffset)

        -- Set backdrop properties
        widget.background:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        widget.background:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

        -- Populate widget data
        local _, _, quality, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
        local r, g, b = C_Item.GetItemQualityColor(quality)

        widget.icon:SetTexture(icon)
        widget.text:SetText(itemLink)
        if r then
            widget.text:SetTextColor(r, g, b)
        end

        widget.unblockButton.itemID = itemID
        widget.unblockButton:SetScript("OnClick", function(self)
            GO:UnblockItem(self.itemID)
            BlockedItems:UpdatePanel() -- Refresh the panel after unblocking
        end)
        
        -- Tooltip
        widget.background:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:SetFrameStrata("TOOLTIP")
            GameTooltip:SetFrameLevel(50) -- This ensures the tooltip is drawn on top
            GameTooltip:Show()
        end)
        widget.background:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        widget.background:Show()
        yOffset = yOffset - WIDGET_HEIGHT - WIDGET_SPACING
        widgetIndex = widgetIndex + 1
    end

    -- Hide unused widgets
    for i = widgetIndex, #content.widgets do
        content.widgets[i].background:Hide()
    end

    content:SetHeight(math.abs(yOffset))
end

function BlockedItems:TogglePanel()
    if not self.Frame then self:CreatePanel() end

    if self.Frame:IsShown() then
        self.Frame:Hide()
    else
        self.Frame:Show()
        self:UpdatePanel()
    end
end

