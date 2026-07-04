--[[--------------------------------------------------------------------------
    Inri's Achievements! - Inspect / Profiles

    Adds a "View Achievements" entry to the unit right-click menu and shows a
    networked profile of another player who has the addon: points, completion,
    notable (epic+) achievements, and recent earns. Data is pulled live from
    the roster cache and topped up with a profile request over the comm layer.

    If the player does not have the addon, the menu option is hidden / the
    command reports gracefully.
----------------------------------------------------------------------------]]

local _, ns = ...
local L    = ns.L
local Util = ns.Util

local Inspect = {}
ns.Inspect = Inspect

local frame
local currentKey

----------------------------------------------------------------------
-- Analyse a roster entry's completed list into stats + notable list.
----------------------------------------------------------------------
local function Analyze(entry)
    local byRarity = { 0, 0, 0, 0 }
    local notable = {}
    for _, id in ipairs(entry.completed or {}) do
        local def = ns.GetAchievement(id)
        if def then
            byRarity[def.rarity] = (byRarity[def.rarity] or 0) + 1
            if def.rarity >= ns.RARITY.EPIC then notable[#notable + 1] = def end
        end
    end
    table.sort(notable, function(a, b)
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.name < b.name
    end)
    return byRarity, notable
end

----------------------------------------------------------------------
-- Frame
----------------------------------------------------------------------
local function BuildFrame()
    frame = CreateFrame("Frame", "InrisInspectFrame", UIParent, "BackdropTemplate")
    frame:SetSize(360, 440)
    frame:SetPoint("CENTER", 280, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetMovable(true); frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    tinsert(UISpecialFrames, "InrisInspectFrame")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    frame.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.name:SetPoint("TOP", 0, -18)

    frame.titleLine = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.titleLine:SetPoint("TOP", frame.name, "BOTTOM", 0, -3)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOP", frame.titleLine, "BOTTOM", 0, -4)

    frame.points = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
    frame.points:SetPoint("TOP", frame.subtitle, "BOTTOM", 0, -10)
    frame.points:SetTextColor(1, 0.82, 0)

    frame.pointsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.pointsLabel:SetPoint("TOP", frame.points, "BOTTOM", 0, -2)
    frame.pointsLabel:SetText(L["TOTAL_POINTS"])

    frame.completion = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.completion:SetPoint("TOP", frame.pointsLabel, "BOTTOM", 0, -8)

    frame.rarityLine = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.rarityLine:SetPoint("TOP", frame.completion, "BOTTOM", 0, -4)

    -- Notable header + rows
    frame.notableHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.notableHeader:SetPoint("TOPLEFT", 20, -170)
    frame.notableHeader:SetText(L["INSPECT_HIGHEST"])
    frame.notableRows = {}
    for i = 1, 6 do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 28, -188 - (i - 1) * 16)
        fs:SetJustifyH("LEFT")
        frame.notableRows[i] = fs
    end

    -- Recent header + rows
    frame.recentHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.recentHeader:SetPoint("TOPLEFT", 20, -300)
    frame.recentHeader:SetText(L["RECENTLY_EARNED"])
    frame.recentRows = {}
    for i = 1, 5 do
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 28, -318 - (i - 1) * 16)
        fs:SetJustifyH("LEFT")
        frame.recentRows[i] = fs
    end

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.status:SetPoint("BOTTOM", 0, 18)
end

----------------------------------------------------------------------
-- Populate from a roster entry
----------------------------------------------------------------------
local function Populate(entry)
    if not frame then return end

    local classColor = Util.ClassColor(entry.classToken)
    frame.name:SetText(entry.name or "?")
    frame.name:SetTextColor(classColor[1], classColor[2], classColor[3])

    if entry.titleText and entry.titleText ~= "" then
        local tc = Util.RarityColor(entry.titleRarity or 1)
        frame.titleLine:SetText(ns.STAR_ICON .. entry.titleText)  -- star icon + title
        frame.titleLine:SetTextColor(tc[1], tc[2], tc[3])
    else
        frame.titleLine:SetText("")
    end

    local classLoc = entry.classToken and (LOCALIZED_CLASS_NAMES_MALE
        and LOCALIZED_CLASS_NAMES_MALE[entry.classToken]) or entry.classToken or "?"
    local guildPart = (entry.guild and entry.guild ~= "")
        and ("  -  <" .. entry.guild .. ">") or ""
    frame.subtitle:SetText((entry.faction or "") .. " " .. classLoc .. guildPart)

    frame.points:SetText(tostring(entry.points or 0))

    local total = #ns.Achievements
    frame.completion:SetText(string.format("%s: %d / %d", L["COMPLETION"], entry.count or 0, total))

    if entry.completed then
        local byRarity, notable = Analyze(entry)
        frame.rarityLine:SetText(string.format(
            "%s %d   %s %d   %s %d   %s %d",
            Util.Colorize(L["RARITY_COMMON"],    Util.RarityColor(1)), byRarity[1],
            Util.Colorize(L["RARITY_RARE"],      Util.RarityColor(2)), byRarity[2],
            Util.Colorize(L["RARITY_EPIC"],      Util.RarityColor(3)), byRarity[3],
            Util.Colorize(L["RARITY_LEGENDARY"], Util.RarityColor(4)), byRarity[4]))

        for i, fs in ipairs(frame.notableRows) do
            local def = notable[i]
            if def then
                fs:SetText(Util.Colorize(def.name, Util.RarityColor(def.rarity)))
            else
                fs:SetText("")
            end
        end
        frame.status:SetText("")
    else
        frame.rarityLine:SetText("")
        for _, fs in ipairs(frame.notableRows) do fs:SetText("") end
        frame.status:SetText(string.format(L["INSPECT_REQUESTING"], entry.name or "?"))
    end

    -- Recent (available once a profile/full has arrived)
    for i, fs in ipairs(frame.recentRows) do
        local id = entry.recent and entry.recent[i]
        local def = id and ns.GetAchievement(id)
        if def then
            fs:SetText(Util.Colorize(def.name, Util.RarityColor(def.rarity)))
        else
            fs:SetText("")
        end
    end
end

----------------------------------------------------------------------
-- Public open
----------------------------------------------------------------------
function Inspect:Open(name)
    local key = Util.NormalizeName(name)

    -- Inspecting yourself just opens your own achievement window.
    if key == (Util.PlayerKey()) then
        ns.UI:Show()
        return
    end

    local entry = ns.DB:GetRosterEntry(key)
    if not entry or not entry.hasAddon then
        Util.Print(string.format(L["INSPECT_NO_ADDON"], name))
        return
    end

    if not frame then BuildFrame() end
    currentKey = key
    frame:Show()
    Populate(entry)

    -- Ask for a fresh full profile.
    if ns.Comm then ns.Comm:RequestProfile(name) end
end

-- Called by the comm layer when new data for someone arrives.
function Inspect:OnSummary(key, entry)
    if frame and frame:IsShown() and key == currentKey then Populate(entry) end
end

function Inspect:OnFullReceived(key, entry)
    if frame and frame:IsShown() and key == currentKey then Populate(entry) end
end

----------------------------------------------------------------------
-- Right-click unit menu integration.
-- The 1.15 Era client uses the modern Menu API (Menu.ModifyMenu); the old
-- UnitPopupButtons table no longer exists there, so we try the modern path
-- first and keep the legacy one only as a fallback for older clients.
----------------------------------------------------------------------
local function ResolveContextName(contextData)
    if not contextData then return nil end
    local name = contextData.name
    if not name and contextData.unit and UnitExists(contextData.unit) then
        local n, realm = UnitName(contextData.unit)
        name = n
        if realm and realm ~= "" then name = n .. "-" .. realm end
    end
    if not name then return nil end
    local server = contextData.server
    if server and server ~= "" and not name:find("-") then
        name = name .. "-" .. server
    end
    return name
end

local function HookModernMenu()
    if not (Menu and Menu.ModifyMenu) then return false end
    local tags = {
        "MENU_UNIT_SELF", "MENU_UNIT_PLAYER", "MENU_UNIT_PARTY",
        "MENU_UNIT_RAID_PLAYER", "MENU_UNIT_FRIEND", "MENU_UNIT_ENEMY_PLAYER",
    }
    local function AddEntry(owner, rootDescription, contextData)
        local name = ResolveContextName(contextData)
        if not name then return end
        rootDescription:CreateDivider()
        rootDescription:CreateButton(L["INSPECT_MENU"], function()
            Inspect:Open(name)
        end)
    end
    local any = false
    for _, tag in ipairs(tags) do
        local ok = pcall(Menu.ModifyMenu, tag, AddEntry)
        any = any or ok
    end
    return any
end

local function HookLegacyMenu()
    return pcall(function()
        if not UnitPopupButtons or not UnitPopupMenus then error("no legacy menu") end
        UnitPopupButtons["INRI_VIEW_ACH"] = { text = L["INSPECT_MENU"], dist = 0 }

        local menus = { "PLAYER", "FRIEND", "PARTY", "RAID_PLAYER", "SELF" }
        for _, m in ipairs(menus) do
            local menu = UnitPopupMenus[m]
            if menu then tinsert(menu, #menu, "INRI_VIEW_ACH") end
        end

        hooksecurefunc("UnitPopup_OnClick", function(self)
            if self.value ~= "INRI_VIEW_ACH" then return end
            local dropdown = UIDROPDOWNMENU_INIT_MENU
            local name = dropdown and dropdown.name
            if not name then return end
            local server = dropdown.server
            if server and server ~= "" and not name:find("-") then
                name = name .. "-" .. server
            end
            Inspect:Open(name)
        end)
    end)
end

function Inspect:HookUnitMenu()
    if HookModernMenu() then return end
    if HookLegacyMenu() then return end
    -- Neither menu system available: /ia inspect <name> still works.
end
