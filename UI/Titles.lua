--[[--------------------------------------------------------------------------
    Inri's Achievements! - Titles UI

    Where a title shows:
      1. Unit tooltip (you + any addon user you hover).
      2. A dropdown off the window's "Titles" button (pick your title).
      3. On Blizzard's character sheet, appended to your name -> "Name Title".
      4. Appended to players' nameplate names - for anyone running this addon.

    Limit: Classic Era does NOT let addons grant a real Blizzard title or change
    the name that NON-addon players see. So the appended nameplate/character-sheet
    title renders only on the screens of people who also run this addon.
----------------------------------------------------------------------------]]

local _, ns = ...
local L    = ns.L
local Util = ns.Util

local TitlesUI = {}
ns.TitlesUI = TitlesUI

local STAR = ns.STAR_ICON   -- inline gold star texture (U+2605 isn't in WoW's font)

-- Title to show for a unit (self uses the live active title; others the cache).
local function TitleEntryForUnit(unit)
    if UnitIsUnit(unit, "player") then
        local active = ns.Titles:GetActive()
        if active then return active.text, active.rarity end
        return nil
    end
    local name, realm = UnitName(unit)
    local entry = ns.DB:GetRosterEntry(Util.NormalizeName(name, realm))
    if entry and entry.hasAddon and entry.titleText and entry.titleText ~= "" then
        return entry.titleText, entry.titleRarity or 1
    end
    return nil
end

----------------------------------------------------------------------
-- Unit tooltip integration
----------------------------------------------------------------------
local function OnTooltipSetUnit(self)
    local _, unit = self:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local entry
    if UnitIsUnit(unit, "player") then
        local active = ns.Titles:GetActive()
        entry = {
            hasAddon = true, points = ns.DB:GetPoints(), count = ns.DB:GetCount(),
            titleText = active and active.text, titleRarity = active and active.rarity,
        }
    else
        local name, realm = UnitName(unit)
        entry = ns.DB:GetRosterEntry(Util.NormalizeName(name, realm))
    end
    if not entry or not entry.hasAddon then return end

    if entry.titleText and entry.titleText ~= "" then
        local c = Util.RarityColor(entry.titleRarity or 1)
        self:AddLine(STAR .. entry.titleText, c[1], c[2], c[3])
    end
    self:AddLine(string.format("%s: |cffffd100%d|r   %d/%d",
        L["TOTAL_POINTS"], entry.points or 0, entry.count or 0, #ns.Achievements),
        0.9, 0.9, 0.9)
    self:Show()
end

----------------------------------------------------------------------
-- Title appended to the name on Blizzard's character sheet
----------------------------------------------------------------------
-- Rewrite the character frame's name line to "Name <Title>" as one centered
-- string, so it never overlaps. We don't assume the global's name (it differs
-- across client versions) - we discover the FontString that currently shows the
-- player's name, cache it, then keep rewriting it.
local charHooked = false
local nameFS

local function FindNameFS(frame, depth)
    if not frame or depth > 2 then return nil end
    local pname = UnitName("player")
    if frame.GetRegions then
        for _, r in ipairs({ frame:GetRegions() }) do
            if r.GetObjectType and r:GetObjectType() == "FontString" and r:GetText() == pname then
                return r
            end
        end
    end
    if frame.GetChildren then
        for _, ch in ipairs({ frame:GetChildren() }) do
            local found = FindNameFS(ch, depth + 1)
            if found then return found end
        end
    end
    return nil
end

local function UpdateCharTitle()
    if not nameFS then nameFS = FindNameFS(CharacterFrame, 0) end
    if not nameFS then return end
    local base = UnitName("player") or ""
    local active = ns.Titles:GetActive()
    if active then
        local hex = ns.RARITY_INFO[active.rarity].hex
        nameFS:SetText(base .. "|cff" .. hex .. ns.Titles.SuffixText(active.text) .. "|r")
    else
        nameFS:SetText(base)
    end
end

local function EnsureCharHook()
    if charHooked or not CharacterFrame then return end
    charHooked = true
    -- Run a frame later so we win against Blizzard's own OnShow title set.
    CharacterFrame:HookScript("OnShow", function() C_Timer.After(0, UpdateCharTitle) end)
end

----------------------------------------------------------------------
-- Title appended to player nameplate names (for fellow addon users)
----------------------------------------------------------------------
local plateTitles = {}   -- [nameplate frame] = fontstring

local function ShowPlateTitle(unit)
    if not unit or not UnitIsPlayer(unit) or not C_NamePlate then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end

    local text, rarity = TitleEntryForUnit(unit)
    local fs = plateTitles[plate]
    if not text then
        if fs then fs:Hide() end
        return
    end
    if not fs then
        fs = plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        plateTitles[plate] = fs
    end

    local c = Util.RarityColor(rarity)
    fs:ClearAllPoints()
    -- Append after the nameplate's name if we can find it; else float above.
    local nameFS = plate.UnitFrame and (plate.UnitFrame.name or plate.UnitFrame.Name)
    if nameFS then
        fs:SetPoint("LEFT", nameFS, "RIGHT", 0, 0)
        fs:SetText(ns.Titles.SuffixText(text))
    else
        fs:SetPoint("BOTTOM", plate, "TOP", 0, 4)
        fs:SetText(STAR .. text)
    end
    fs:SetTextColor(c[1], c[2], c[3])
    fs:Show()
end

local function UpdateAllPlates()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, p in ipairs(C_NamePlate.GetNamePlates()) do
        if p.namePlateUnitToken then ShowPlateTitle(p.namePlateUnitToken) end
    end
end

local function EnableNameplates()
    local f = CreateFrame("Frame")
    f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    f:SetScript("OnEvent", function(_, ev, unit)
        if ev == "NAME_PLATE_UNIT_ADDED" then
            ShowPlateTitle(unit)
        elseif C_NamePlate then
            local plate = C_NamePlate.GetNamePlateForUnit(unit)
            if plate and plateTitles[plate] then plateTitles[plate]:Hide() end
        end
    end)
end

----------------------------------------------------------------------
-- Public refresh (called when the active title changes)
----------------------------------------------------------------------
function TitlesUI:Refresh()
    EnsureCharHook()
    UpdateCharTitle()
    UpdateAllPlates()
end

----------------------------------------------------------------------
-- Title picker dropdown (Classic has no EasyMenu; use UIDropDownMenu directly)
----------------------------------------------------------------------
local menuFrame

local function InitMenu(_, level)
    if not level then return end
    local activeID = ns.DB:GetActiveTitleID()

    local info = UIDropDownMenu_CreateInfo()
    info.text = L["TITLE_PICKER"]; info.isTitle = true; info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = L["NO_TITLE"]
    info.checked = (activeID == nil)
    info.func = function() ns.Titles:SetActive(nil); CloseDropDownMenus() end
    UIDropDownMenu_AddButton(info, level)

    local unlocked = ns.Titles:GetUnlocked()
    if #unlocked == 0 then
        info = UIDropDownMenu_CreateInfo()
        info.text = "|cff808080none unlocked yet|r"; info.notCheckable = true; info.disabled = true
        UIDropDownMenu_AddButton(info, level)
    else
        for _, t in ipairs(unlocked) do
            local id = t.id
            info = UIDropDownMenu_CreateInfo()
            info.text = Util.Colorize(t.text, Util.RarityColor(t.rarity))
            info.checked = (id == activeID)
            info.func = function() ns.Titles:SetActive(id); CloseDropDownMenus() end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

function TitlesUI:Toggle(anchor)
    if not menuFrame then
        menuFrame = CreateFrame("Frame", "InriTitlesMenu", UIParent, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(menuFrame, InitMenu, "MENU")
    end
    ToggleDropDownMenu(1, nil, menuFrame, anchor or "cursor", 0, 0)
end

function TitlesUI:Show() self:Toggle("cursor") end

----------------------------------------------------------------------
-- Setup (called once at boot)
----------------------------------------------------------------------
function TitlesUI:HookTooltip()
    GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
    EnsureCharHook()
    EnableNameplates()
    self:Refresh()
end
