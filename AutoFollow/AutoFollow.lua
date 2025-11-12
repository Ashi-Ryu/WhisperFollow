-- AutoFollow Addon for Bronzebeard 3.3.5
-- Author: Ashi-Ryu
-- Version: 1.7

-- Saved settings
AutoFollowSettings = AutoFollowSettings or {
    enabled = true,
    keyPhrase = "follow",
}

-- Helper: strip realm from name (Name-Realm -> Name)
local function ShortName(name)
    if not name then return nil end
    return name:match("^[^-]+") or name
end

-- Main frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_WHISPER")

-- Check if sender is in party or raid
local function UnitInGroupByName(name)
    name = ShortName(name)
    -- Party
    for i = 1, GetNumPartyMembers() do
        if UnitName("party"..i) == name then return "party"..i end
    end
    -- Raid
    for i = 1, GetNumRaidMembers() do
        if UnitName("raid"..i) == name then return "raid"..i end
    end
    return nil
end

-- Follow logic
local function StartFollow(senderRaw)
    if not AutoFollowSettings.enabled then return end
    local sender = ShortName(senderRaw)
    local me = UnitName("player")
    if not sender or sender == me then return end

    if InCombatLockdown and InCombatLockdown() then
        print("AutoFollow: Cannot follow while in combat.")
        return
    end

    -- Follow current target if it matches
    if UnitExists("target") and UnitName("target") == sender then
        FollowUnit("target")
        print("AutoFollow: Following current target " .. sender)
        return
    end

    -- Follow party/raid member if found
    local groupUnit = UnitInGroupByName(sender)
    if groupUnit then
        FollowUnit(groupUnit)
        print("AutoFollow: Following group member " .. sender)
        return
    end

    print("AutoFollow: Cannot follow " .. sender .. " — must be your target or a group member.")
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
    local msg, sender = tostring(arg1 or ""), tostring(arg2 or "")
    if not AutoFollowSettings.enabled then return end

    if event == "CHAT_MSG_WHISPER" then
        if msg:lower():find(AutoFollowSettings.keyPhrase:lower(), 1, true) then
            StartFollow(sender)
        end
    end
end)

-- Minimap button
local button = CreateFrame("Button", "AutoFollowMinimapButton", Minimap)
button:SetSize(22, 22) -- standard minimap button size
button:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
button:SetFrameStrata("MEDIUM")
button:EnableMouse(true)
button:SetMovable(true)
button:RegisterForDrag("LeftButton")
button:SetScript("OnDragStart", function(self) self:StartMoving() end)
button:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
icon:SetTexture("Interface\\Icons\\Ability_Hunter_MendPet")
icon:SetTexCoord(0.08,0.92,0.08,0.92)

button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("AutoFollow", 1, 1, 0)
    GameTooltip:AddLine("Click to toggle AutoFollow", 1, 1, 1)
    GameTooltip:AddLine("Status: " .. (AutoFollowSettings.enabled and "Enabled" or "Disabled"), 0, 1, 0)
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

button:SetScript("OnClick", function(self)
    AutoFollowSettings.enabled = not AutoFollowSettings.enabled
    print("AutoFollow " .. (AutoFollowSettings.enabled and "Enabled" or "Disabled"))
end)

-- Options panel
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "AutoFollowOptionsPanel", UIParent)
    panel.name = "AutoFollow"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AutoFollow Settings")

    -- Key phrase
    local keyLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    keyLabel:SetText("Key Phrase (Whisper Trigger):")

    local keyEdit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    keyEdit:SetPoint("TOPLEFT", keyLabel, "BOTTOMLEFT", 0, -4)
    keyEdit:SetSize(200, 20)
    keyEdit:SetText(AutoFollowSettings.keyPhrase)
    keyEdit:SetAutoFocus(false)
    keyEdit:SetScript("OnEnterPressed", function(self)
        AutoFollowSettings.keyPhrase = self:GetText()
        self:ClearFocus()
        print("AutoFollow: Key phrase updated to '" .. AutoFollowSettings.keyPhrase .. "'")
    end)

    -- Default Settings button
    local defaultButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    defaultButton:SetSize(120, 22)
    defaultButton:SetPoint("TOPLEFT", keyEdit, "BOTTOMLEFT", 0, -16)
    defaultButton:SetText("Default Settings")
    defaultButton:SetScript("OnClick", function()
        AutoFollowSettings.enabled = true
        AutoFollowSettings.keyPhrase = "follow"
        keyEdit:SetText(AutoFollowSettings.keyPhrase)
        print("AutoFollow: Settings reset to default")
    end)

    InterfaceOptions_AddCategory(panel)
end

CreateOptionsPanel()