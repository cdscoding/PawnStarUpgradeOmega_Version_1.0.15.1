-- WelcomePSUO.lua - Handles the welcome window for first-time users.

local addonName = "PawnStarUpgradeOmega"
local GO = _G[addonName]
GO.Welcome = {}
local Welcome = GO.Welcome

-- Constants for the popup window
local WELCOME_WINDOW_WIDTH = 420
local WELCOME_WINDOW_HEIGHT = 690 -- Increased height for new sections
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

function Welcome:OnInitialize()
    -- No specific init needed, window is created on demand.
end

-- Creates the welcome window
function Welcome:CreateWindow()
    if Welcome.Window then return end
    local ww = CreateFrame("Frame", addonName .. "WelcomeWindow", UIParent, "BasicFrameTemplateWithInset")
    Welcome.Window = ww
    ww:SetSize(WELCOME_WINDOW_WIDTH, WELCOME_WINDOW_HEIGHT)
    ww:SetFrameStrata("DIALOG")
    ww:SetFrameLevel(GO.optionsFrame and (GO.optionsFrame:GetFrameLevel() or 5) + 5 or 10)
    ww.TitleText:SetText("Welcome to " .. addonName .. "!")
    ww:SetMovable(true)
    ww:EnableMouse(true)
    ww:RegisterForDrag("LeftButton")
    ww:SetScript("OnDragStart", function(self) self:StartMoving() end)
    ww:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    ww:SetClampedToScreen(true)
    
    -- Set strata for the close button to match the parent frame
    ww.CloseButton:SetFrameStrata(ww:GetFrameStrata())
    ww.CloseButton:SetFrameLevel(ww:GetFrameLevel() + 1)
    ww.CloseButton:SetScript("OnClick", function() Welcome:HideWindow() end)

    -- Tutorial Text
    local tutorialText = ww:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tutorialText:SetPoint("TOPLEFT", 15, -40)
    tutorialText:SetWidth(ww:GetWidth() - 30)
    tutorialText:SetJustifyH("LEFT")
    tutorialText:SetJustifyV("TOP")
    local tutorialContent = {
        CT(COLORS.SECTION_TITLE, "Getting Started") .. "\n",
        "Upgrade detection is fully automatic! An alert will pop up when an upgrade is found.\n\n",
        "To open the options window, type " .. CT(COLORS.SUB_HIGHLIGHT, "/psuo") .. " or " .. CT(COLORS.SUB_HIGHLIGHT, "/pawnstar") .. " in chat, or simply click the minimap icon.\n\n",
        "For the most accurate gear recommendations, it is highly recommended to also install the |cff00ff00Pawn|r addon!"
    }
    tutorialText:SetText(table.concat(tutorialContent, ""))

    -- Discord Logo and Link (positioned below tutorial)
    local discordLogo = ww:CreateTexture(nil, "ARTWORK")
    discordLogo:SetSize(328, 108) 
    discordLogo:SetTexture(DISCORD_LOGO_PATH)
    discordLogo:SetPoint("TOP", tutorialText, "BOTTOM", 0, -20)

    local discordLinkBox = CreateFrame("EditBox", addonName.."WelcomeDiscordLinkBox", ww, "InputBoxTemplate")
    discordLinkBox:SetPoint("TOP", discordLogo, "BOTTOM", 0, -10)
    discordLinkBox:SetSize(ww:GetWidth() - 60, 30)
    discordLinkBox:SetText("https://discord.com/invite/5TfC7ey3Te")
    discordLinkBox:SetAutoFocus(false)
    discordLinkBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    discordLinkBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discordLinkBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local discordInstructionLabel = ww:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    discordInstructionLabel:SetPoint("TOP", discordLinkBox, "BOTTOM", 0, -5)
    discordInstructionLabel:SetTextColor(1, 1, 1)
    discordInstructionLabel:SetText("Press Ctrl+C to copy the URL.")

    -- Patreon Logo and Link
    local patreonLogo = ww:CreateTexture(nil, "ARTWORK")
    patreonLogo:SetSize(256, 64) 
    patreonLogo:SetTexture(PATREON_LOGO_PATH)
    patreonLogo:SetPoint("TOP", discordInstructionLabel, "BOTTOM", 0, -20)

    local messageFS = ww:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    messageFS:SetPoint("TOP", patreonLogo, "BOTTOM", 0, -15)
    messageFS:SetWidth(ww:GetWidth() - 40)
    messageFS:SetJustifyH("CENTER")
    messageFS:SetJustifyV("TOP")
    messageFS:SetTextColor(1, 0.82, 0) -- Gold color
    messageFS:SetText("Join the community to chat, get help, and report bugs! Signing up is free, and your feedback is crucial for improving the addon. If you wish to support development, donations are gratefully accepted as an option.")

    local patreonLinkBox = CreateFrame("EditBox", addonName.."WelcomePatreonLinkBox", ww, "InputBoxTemplate")
    patreonLinkBox:SetPoint("TOP", messageFS, "BOTTOM", 0, -15)
    patreonLinkBox:SetSize(ww:GetWidth() - 60, 30)
    patreonLinkBox:SetText("https://www.patreon.com/csasoftware")
    patreonLinkBox:SetAutoFocus(false)
    patreonLinkBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    patreonLinkBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    patreonLinkBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local patreonInstructionLabel = ww:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    patreonInstructionLabel:SetPoint("TOP", patreonLinkBox, "BOTTOM", 0, -5)
    patreonInstructionLabel:SetTextColor(1, 1, 1)
    patreonInstructionLabel:SetText("Press Ctrl+C to copy the URL.")

    -- "Do not show again" Checkbox
    local dontShowCheck = CreateFrame("CheckButton", addonName .. "DontShowWelcomeCheck", ww, "UICheckButtonTemplate")
    dontShowCheck:SetPoint("BOTTOMLEFT", 10, 10)
    _G[dontShowCheck:GetName() .. "Text"]:SetText("Do not show this again")
    
    dontShowCheck:SetScript("OnClick", function(self)
        if not PawnStarOmegaDB.settings then PawnStarOmegaDB.settings = {} end
        PawnStarOmegaDB.settings.showWelcomeWindow = not self:GetChecked()
    end)
    
    dontShowCheck:SetScript("OnShow", function(self)
        if PawnStarOmegaDB and PawnStarOmegaDB.settings then
            self:SetChecked(not PawnStarOmegaDB.settings.showWelcomeWindow)
        end
    end)

    ww:Hide()
end

function Welcome:ShowWindow()
    if not Welcome.Window then Welcome:CreateWindow() end
    if not Welcome.Window then return end
    Welcome.Window:ClearAllPoints()
    Welcome.Window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    Welcome.Window:Show()
    Welcome.Window:Raise()
end

function Welcome:HideWindow()
    if Welcome.Window and Welcome.Window:IsShown() then Welcome.Window:Hide() end
end

function Welcome:ToggleWindow()
    if not Welcome.Window or not Welcome.Window:IsShown() then Welcome:ShowWindow() else Welcome:HideWindow() end
end
