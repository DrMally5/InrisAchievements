--[[--------------------------------------------------------------------------
    Inri's Achievements! - Main Window

    The achievement browser: category list, search, rarity filters, a scrolling
    achievement list with progress bars, and a header showing total points and
    completion. Built programmatically on top of the XML templates.
----------------------------------------------------------------------------]]

local _, ns = ...
local L    = ns.L
local Util = ns.Util

local UI = {}
ns.UI = UI

local ROW_HEIGHT = 56
local NUM_ROWS   = 7
local CAT_ALL    = "ALL"
local CAT_RECENT = "RECENT"
local CAT_GUILD  = "__GUILD"   -- leaderboard (roster + your alts)
local CAT_STATS  = "__STATS"   -- statistics pane

-- View state
UI.selectedCategory = CAT_ALL
UI.search           = ""
UI.rarityFilter     = { [1] = true, [2] = true, [3] = true, [4] = true }
UI.showCompleted    = true
UI.showIncomplete   = true

local frame, rows, catButtons, scroll, scrollbar

----------------------------------------------------------------------
-- List building
----------------------------------------------------------------------
-- A hidden achievement stays masked only until SOMEONE known has earned it
-- (you, or an addon user whose earned-broadcast we heard). Once discovered,
-- it is revealed for everyone with a "First discovered by X" credit.
local function IsMasked(def)
    return def.hidden
        and not ns.DB:IsCompleted(def.id)
        and not ns.DB:GetDiscovery(def.id)
end

local function PassesFilters(def)
    if not UI.rarityFilter[def.rarity] then return false end
    local completed = ns.DB:IsCompleted(def.id)
    if completed and not UI.showCompleted then return false end
    if not completed and not UI.showIncomplete then return false end

    if UI.search ~= "" then
        if IsMasked(def) then return false end
        local hay = (def.name .. " " .. (def.description or "")):lower()
        if not hay:find(UI.search, 1, true) then return false end
    end
    return true
end

-- Which tab a definition belongs to. Hidden achievements live ONLY in the
-- Hidden tab (and appear masked in All) - never in their nominal category.
local function DefInCategory(def, key)
    if key == "HIDDEN" then return def.hidden == true end
    if def.hidden then return false end
    return def.category == key
end

local function SortDefs(t)
    table.sort(t, function(a, b)
        local ca, cb = ns.DB:IsCompleted(a.id), ns.DB:IsCompleted(b.id)
        if ca ~= cb then return ca end
        if ca then
            return (ns.DB:GetCompletedTime(a.id) or 0) > (ns.DB:GetCompletedTime(b.id) or 0)
        end
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.name < b.name
    end)
end

-- Leaderboard: you (live) + your alts (last snapshot) + every addon user in
-- the roster cache, deduped by Name-Realm, sorted by points.
local function BuildLeaderboard()
    local byKey = {}
    local myKey = Util.PlayerKey()

    for key, a in pairs(ns.DB:GetAlts()) do
        if key ~= myKey then
            byKey[key] = { isPlayer = true, isAlt = true, name = a.name or key,
                classToken = a.classToken, points = a.points or 0, count = a.count or 0 }
        end
    end
    for key, e in pairs(ns.DB:GetRoster()) do
        if key ~= myKey and e.hasAddon and not byKey[key] then
            byKey[key] = { isPlayer = true, name = e.name or key,
                classToken = e.classToken, points = e.points or 0, count = e.count or 0 }
        end
    end
    byKey[myKey] = { isPlayer = true, isSelf = true, name = ns.DB:GetMeta().name,
        classToken = ns.DB:GetMeta().classToken,
        points = ns.DB:GetPoints(), count = ns.DB:GetCount() }

    local list = {}
    for _, e in pairs(byKey) do list[#list + 1] = e end
    table.sort(list, function(a, b)
        if a.points ~= b.points then return a.points > b.points end
        return (a.name or "") < (b.name or "")
    end)
    for i, e in ipairs(list) do e.rank = i end
    return list
end

-- Statistics pane rows.
local function BuildStats()
    local s = ns.Engine:GetStats()
    local byRarity, titles, hiddenTotal, hiddenFound = { 0, 0, 0, 0 }, 0, 0, 0
    for _, def in ipairs(ns.Achievements) do
        if def.hidden then hiddenTotal = hiddenTotal + 1 end
        if ns.DB:IsCompleted(def.id) then
            byRarity[def.rarity] = byRarity[def.rarity] + 1
            if def.title then titles = titles + 1 end
            if def.hidden then hiddenFound = hiddenFound + 1 end
        end
    end
    local function stat(label, value) return { isStat = true, label = label, value = value } end
    return {
        stat(L["TOTAL_POINTS"], s.points .. " / " .. s.maxPoints),
        stat(L["COMPLETION"], string.format("%d / %d  (%.0f%%)", s.completed, s.total, s.percent)),
        stat(Util.Colorize(L["RARITY_COMMON"],    Util.RarityColor(1)), byRarity[1]),
        stat(Util.Colorize(L["RARITY_RARE"],      Util.RarityColor(2)), byRarity[2]),
        stat(Util.Colorize(L["RARITY_EPIC"],      Util.RarityColor(3)), byRarity[3]),
        stat(Util.Colorize(L["RARITY_LEGENDARY"], Util.RarityColor(4)), byRarity[4]),
        stat(L["TITLES"], titles),
        stat(L["CAT_HIDDEN"], hiddenFound .. " / " .. hiddenTotal),
        stat("Deaths (tracked)", ns.DB:GetDeaths()),
    }
end

local function BuildList()
    -- Recently earned: flat, already newest-first.
    if UI.selectedCategory == CAT_RECENT then
        local list = {}
        for _, r in ipairs(ns.DB:GetRecent()) do
            local def = ns.GetAchievement(r.id)
            if def then list[#list + 1] = def end
        end
        return list
    end

    if UI.selectedCategory == CAT_GUILD then return BuildLeaderboard() end
    if UI.selectedCategory == CAT_STATS then return BuildStats() end

    -- All: flat. Hidden achievements are excluded here - they live only in the
    -- Hidden tab (and Recently Earned once revealed).
    if UI.selectedCategory == CAT_ALL then
        local list = {}
        for _, def in ipairs(ns.Achievements) do
            if not def.hidden and PassesFilters(def) then list[#list + 1] = def end
        end
        SortDefs(list)
        return list
    end

    -- A specific category: group by subcategory with header rows.
    local groups, order = {}, {}
    for _, def in ipairs(ns.Achievements) do
        if DefInCategory(def, UI.selectedCategory) and PassesFilters(def) then
            local sub = def.subcategory or ""
            if not groups[sub] then groups[sub] = {}; order[#order + 1] = sub end
            local g = groups[sub]; g[#g + 1] = def
        end
    end

    local out = {}
    local multi = #order > 1
    for _, sub in ipairs(order) do
        SortDefs(groups[sub])
        if multi and sub ~= "" then out[#out + 1] = { isHeader = true, text = sub } end
        for _, d in ipairs(groups[sub]) do out[#out + 1] = d end
    end
    return out
end

----------------------------------------------------------------------
-- Tooltip
----------------------------------------------------------------------
local function ShowTooltip(row)
    local def = row.def
    if not def then return end
    local completed = ns.DB:IsCompleted(def.id)
    local masked = IsMasked(def)

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    local color = Util.RarityColor(def.rarity)
    if masked then
        GameTooltip:AddLine(L["HIDDEN_NAME"], 0.6, 0.6, 0.6)
        GameTooltip:AddLine(L["HIDDEN_DESC"], 0.8, 0.8, 0.8, true)
    else
        GameTooltip:AddLine(def.name, color[1], color[2], color[3])
        GameTooltip:AddLine(Util.RarityName(def.rarity) .. " - " .. def.points .. " " .. L["POINTS_SUFFIX"],
            1, 0.82, 0)
        GameTooltip:AddLine(def.description or "", 0.9, 0.9, 0.9, true)

        if def.title and def.title.text then
            GameTooltip:AddLine(ns.STAR_ICON .. string.format(L["TITLE_REWARD"], def.title.text),
                1, 0.82, 0)
        end

        -- Progress
        if def.progressType ~= ns.PROGRESS.BOOLEAN and not completed then
            local cur = (def.progressType == ns.PROGRESS.STAGED)
                and ns.DB:CountStages(def.id) or ns.DB:GetValue(def.id)
            GameTooltip:AddLine(L["PROGRESS"] .. ": " .. Util.FormatFraction(cur, def.target),
                0.4, 0.8, 1)
        end

        -- Dependencies
        if def.requires then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["REQUIRES"], 1, 0.82, 0)
            for _, reqID in ipairs(def.requires) do
                local rdef = ns.GetAchievement(reqID)
                if rdef then
                    local done = ns.DB:IsCompleted(reqID)
                    GameTooltip:AddLine((done and "|cff40ff40" or "|cffff4040") .. rdef.name .. "|r")
                end
            end
        end

        if completed then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format(L["EARNED_ON"], Util.FormatDate(ns.DB:GetCompletedTime(def.id))),
                0.5, 1, 0.5)
        end

        -- Hidden achievements carry their finder's name forever.
        if def.hidden then
            local disc = ns.DB:GetDiscovery(def.id)
            if disc and disc.name then
                GameTooltip:AddLine(string.format(L["FIRST_DISCOVERED"], disc.name), 0.9, 0.7, 1)
            end
        end

        if not completed then
            GameTooltip:AddLine("|cff808080" .. L["TRACK_HINT"] .. "|r")
        end
    end
    GameTooltip:Show()
end

----------------------------------------------------------------------
-- Row rendering
----------------------------------------------------------------------
-- A subcategory section header row.
local function RenderHeader(row, text)
    row.def = nil
    row.icon:Hide(); row.iconBorder:Hide()
    if row.iconGlow then row.iconGlow:Hide() end
    row.name:Hide(); row.desc:Hide(); row.progress:Hide()
    row.points:SetText(""); row.meta:SetText("")
    row.rarity:SetColorTexture(0, 0, 0, 0)
    row.bg:SetColorTexture(0, 0, 0, 0)
    if not row.headerFS then
        row.headerFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.headerFS:SetPoint("LEFT", 14, 0)
        row.headerFS:SetTextColor(1, 0.82, 0)
    end
    row.headerFS:SetText(text)
    row.headerFS:Show()
    row:Show()
end

-- A leaderboard entry (you / an alt / a guildmate with the addon).
local function RenderPlayerRow(row, e)
    row.def = nil
    if row.headerFS then row.headerFS:Hide() end
    row.icon:Show(); row.iconBorder:Show(); row.name:Show()
    if row.iconGlow then row.iconGlow:Hide() end
    row.progress:Hide()

    local tc = e.classToken and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[e.classToken]
    if tc then
        row.icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        row.icon:SetTexCoord(unpack(tc))
    else
        row.icon:SetTexture(ns.DEFAULT_ICON)
        row.icon:SetTexCoord(0, 1, 0, 1)
    end
    row.icon:SetDesaturated(false)

    local cc = Util.ClassColor(e.classToken)
    local suffix = e.isSelf and L["YOU_SUFFIX"] or (e.isAlt and L["ALT_SUFFIX"] or "")
    row.name:SetText((e.name or "?") .. "|cff808080" .. suffix .. "|r")
    row.name:SetTextColor(cc[1], cc[2], cc[3])
    row.desc:SetText(string.format("%d / %d achievements", e.count or 0, #ns.Achievements))
    row.desc:Show()
    row.points:SetText("|cffffd100" .. (e.points or 0) .. "|r")
    row.meta:SetText("|cff808080#" .. (e.rank or "?") .. "|r")
    row.rarity:SetColorTexture(cc[1], cc[2], cc[3], 0.8)
    if e.isSelf then
        row.bg:SetColorTexture(0.25, 0.20, 0.05, 0.55)
    else
        row.bg:SetColorTexture(0.10, 0.07, 0.04, 0.5)
    end
    row:Show()
end

-- A statistics line.
local function RenderStatRow(row, e)
    row.def = nil
    if row.headerFS then row.headerFS:Hide() end
    row.icon:Hide(); row.iconBorder:Hide()
    if row.iconGlow then row.iconGlow:Hide() end
    row.desc:Hide(); row.progress:Hide()
    row.name:Show()
    row.name:SetText(e.label)
    row.name:SetTextColor(0.9, 0.9, 0.9)
    row.points:SetText("|cffffd100" .. tostring(e.value) .. "|r")
    row.meta:SetText("")
    row.rarity:SetColorTexture(1, 0.82, 0, 0.35)
    row.bg:SetColorTexture(0.10, 0.07, 0.04, 0.35)
    row:Show()
end

local function RenderRow(row, def)
    row.def = def
    if row.headerFS then row.headerFS:Hide() end
    row.icon:Show(); row.iconBorder:Show(); row.name:Show()
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)   -- trim baked icon border
    local completed = ns.DB:IsCompleted(def.id)
    local masked = IsMasked(def)
    local color = Util.RarityColor(def.rarity)

    if masked then
        row.icon:SetTexture(ns.DEFAULT_ICON)
        row.name:SetText(L["HIDDEN_NAME"])
        row.name:SetTextColor(0.6, 0.6, 0.6)
        row.desc:SetText(L["HIDDEN_DESC"])
        row.points:SetText("|cff808080?|r")
        row.meta:SetText("")
        row.progress:Hide()
        row.icon:SetDesaturated(true)
        row.iconGlow:Hide()
        row.rarity:SetColorTexture(0.4, 0.4, 0.4, 0.6)
        row.bg:SetColorTexture(0.10, 0.07, 0.04, 0.5)
        row.desc:Show()
        row:Show()
        return
    end

    row.icon:SetTexture(def.icon)
    row.icon:SetDesaturated(not completed)

    -- Earned achievements glow in their rarity colour; locked stay unlit.
    if completed then
        row.iconGlow:SetVertexColor(color[1], color[2], color[3], 0.8)
        row.iconGlow:Show()
    else
        row.iconGlow:Hide()
    end
    row.name:SetText(def.name)
    row.name:SetTextColor(color[1], color[2], color[3])
    row.rarity:SetColorTexture(color[1], color[2], color[3], completed and 1 or 0.5)

    -- Completed rows get a faint rarity tint; locked rows a warm parchment-dark.
    if completed then
        row.bg:SetColorTexture(color[1] * 0.20, color[2] * 0.20, color[3] * 0.20, 0.55)
    else
        row.bg:SetColorTexture(0.10, 0.07, 0.04, 0.5)
    end

    row.points:SetText((completed and "|cffffd100" or "|cff808080")
        .. def.points .. "|r")

    -- Progress bar for unfinished counters / staged / progress achievements.
    local barShown = def.progressType ~= ns.PROGRESS.BOOLEAN and not completed
    if barShown then
        local cur = (def.progressType == ns.PROGRESS.STAGED)
            and ns.DB:CountStages(def.id) or ns.DB:GetValue(def.id)
        row.progress:SetMinMaxValues(0, def.target)
        row.progress:SetValue(cur)
        row.progress.text:SetText(Util.FormatFraction(cur, def.target))
        row.progress:Show()
        row.desc:Hide()
    else
        row.progress:Hide()
        row.desc:SetText(def.description or "")
        row.desc:Show()
    end

    if completed then
        -- Earned: show BOTH the title reward and the earn date.
        local when = "|cff40ff40" .. Util.FormatDate(ns.DB:GetCompletedTime(def.id)) .. "|r"
        if def.title and def.title.text then
            row.meta:SetText("|cffffd100" .. ns.STAR_ICON .. def.title.text .. "|r  " .. when)
        else
            row.meta:SetText(when)
        end
    elseif def.hidden then
        -- Revealed-but-unearned hidden achievement: credit its finder.
        local disc = ns.DB:GetDiscovery(def.id)
        row.meta:SetText(disc and ("|cffb080ff" .. (disc.name or "") .. "|r") or "")
    elseif def.title and def.title.text and not barShown then
        -- Unearned title-granting achievement: advertise the prize (skipped
        -- when the progress bar occupies the line; the tooltip covers it).
        row.meta:SetText("|cffffd100" .. ns.STAR_ICON .. def.title.text .. "|r")
    else
        row.meta:SetText("")
    end

    row:Show()
end

----------------------------------------------------------------------
-- Scroll update
----------------------------------------------------------------------
local function UpdateList()
    local list = UI._list or BuildList()
    UI._list = list

    local offset = FauxScrollFrame_GetOffset(scroll)
    FauxScrollFrame_Update(scroll, #list, NUM_ROWS, ROW_HEIGHT + 2)

    for i = 1, NUM_ROWS do
        local row = rows[i]
        local entry = list[i + offset]
        if entry then
            if entry.isHeader then RenderHeader(row, entry.text)
            elseif entry.isPlayer then RenderPlayerRow(row, entry)
            elseif entry.isStat then RenderStatRow(row, entry)
            else RenderRow(row, entry) end
        else
            row:Hide()
            row.def = nil
        end
    end

    UI.empty:SetShown(#list == 0)
end

----------------------------------------------------------------------
-- Category list
----------------------------------------------------------------------
local function CategoryCompletion(key)
    local done, total = 0, 0
    for _, def in ipairs(ns.Achievements) do
        if DefInCategory(def, key) then
            total = total + 1
            if ns.DB:IsCompleted(def.id) then done = done + 1 end
        end
    end
    return done, total
end

local function UpdateCategories()
    for _, btn in ipairs(catButtons) do
        btn.selected:SetShown(btn.key == UI.selectedCategory)
        if btn.key == CAT_ALL then
            btn.count:SetText(ns.DB:GetCount() .. "/" .. #ns.Achievements)
        elseif btn.key == CAT_RECENT or btn.key == CAT_GUILD or btn.key == CAT_STATS then
            btn.count:SetText("")
        else
            local d, t = CategoryCompletion(btn.key)
            btn.count:SetText(d .. "/" .. t)
        end
    end
end

----------------------------------------------------------------------
-- Header
----------------------------------------------------------------------
local function UpdateHeader()
    local stats = ns.Engine:GetStats()
    UI.points:SetText(tostring(stats.points))
    UI.completion:SetText(string.format("%d / %d  (%.0f%%)",
        stats.completed, stats.total, stats.percent))
    UI.completionBar:SetMinMaxValues(0, stats.total)
    UI.completionBar:SetValue(stats.completed)
end

----------------------------------------------------------------------
-- Public refresh
----------------------------------------------------------------------
function UI:Refresh()
    if not frame or not frame:IsShown() then return end
    self._list = nil
    UpdateHeader()
    UpdateCategories()
    UpdateList()
end

function UI:SelectCategory(key)
    self.selectedCategory = key
    self._list = nil
    FauxScrollFrame_SetOffset(scroll, 0)
    if scrollbar then scrollbar:SetValue(0) end
    self:Refresh()
end

----------------------------------------------------------------------
-- Build the window
----------------------------------------------------------------------
local function CreateRow(parent, index)
    local row = CreateFrame("Button", "InriAchRow" .. index, parent, "InriAchievementButtonTemplate")
    row:SetScript("OnEnter", ShowTooltip)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Same icon treatment as the toast: slot ring proportioned to the icon
    -- (the textures carry ~30% transparent margin) plus a rarity glow drawn
    -- OVER the ring with ADD blend. Lit only on earned achievements.
    row.iconBorder:SetSize(66, 66)
    row.iconGlow = row:CreateTexture(nil, "OVERLAY", nil, 2)
    row.iconGlow:SetSize(70, 70)
    row.iconGlow:SetPoint("CENTER", row.icon, "CENTER")
    row.iconGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    row.iconGlow:SetBlendMode("ADD")
    row.iconGlow:Hide()

    -- Taller row with a dedicated bottom line: description is capped to two
    -- lines that can never reach the meta text, points sit top-right, and the
    -- meta line (title reward and/or earn date) owns the full bottom width.
    row:SetHeight(ROW_HEIGHT)
    row.points:ClearAllPoints()
    row.points:SetPoint("TOPRIGHT", -10, -3)
    row.desc:SetWidth(235)
    pcall(row.desc.SetMaxLines, row.desc, 2)
    row.meta:ClearAllPoints()
    row.meta:SetPoint("BOTTOMRIGHT", -10, 5)
    row.meta:SetWidth(300)
    row.meta:SetJustifyH("RIGHT")
    row.meta:SetWordWrap(false)
    pcall(row.meta.SetMaxLines, row.meta, 1)
    -- Right-click pins/unpins an incomplete achievement to the on-screen tracker.
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, btn)
        local def = self.def
        if btn ~= "RightButton" or not def then return end
        if ns.DB:IsCompleted(def.id) or IsMasked(def) then return end
        local result = ns.DB:ToggleTracked(def.id)
        if result == "added" then
            Util.Print(string.format(L["TRACK_ADDED"], def.name))
        elseif result == "removed" then
            Util.Print(string.format(L["TRACK_REMOVED"], def.name))
        else
            Util.Print(L["TRACK_FULL"])
        end
        if ns.Tracker then ns.Tracker:Refresh() end
    end)
    return row
end

-- A thin horizontal rule.
local function Divider(parent, x1, x2, y)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetColorTexture(1, 0.82, 0, 0.25)
    t:SetHeight(1)
    t:SetPoint("TOPLEFT", x1, y)
    t:SetPoint("TOPRIGHT", x2, y)
    return t
end

local LEFT_W = 192   -- category panel width

local function BuildFrame()
    frame = CreateFrame("Frame", "InrisAchievementsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(760, 580)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, "InrisAchievementsFrame")  -- ESC closes

    ------------------------------------------------------------------
    -- Header band: the classic curved dialog ribbon with the title on it,
    -- exactly like Blizzard's own Classic windows.
    ------------------------------------------------------------------
    local headerTex = frame:CreateTexture(nil, "ARTWORK")
    headerTex:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    headerTex:SetSize(380, 64)
    headerTex:SetPoint("TOP", 0, 12)

    -- Offset by half the logo width so the logo+text ensemble is centered.
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", headerTex, "TOP", 14, -14)
    title:SetText(L["WINDOW_TITLE"])

    local logo = frame:CreateTexture(nil, "OVERLAY")
    logo:SetSize(22, 22)
    logo:SetPoint("RIGHT", title, "LEFT", -6, 0)
    logo:SetTexture(ns.LOGO)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    -- Points (top-right), with a trophy-ish icon.
    UI.points = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
    UI.points:SetPoint("TOPRIGHT", -46, -16)
    UI.points:SetTextColor(1, 0.82, 0)
    local ptsIcon = frame:CreateTexture(nil, "OVERLAY")
    ptsIcon:SetSize(22, 22)
    ptsIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    ptsIcon:SetPoint("RIGHT", UI.points, "LEFT", -6, 0)
    local ptsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ptsLabel:SetPoint("TOPRIGHT", UI.points, "BOTTOMRIGHT", 0, -2)
    ptsLabel:SetText(L["TOTAL_POINTS"])

    -- Completion bar under the title.
    UI.completionBar = CreateFrame("StatusBar", nil, frame)
    UI.completionBar:SetSize(300, 16)
    UI.completionBar:SetPoint("TOPLEFT", 24, -52)
    UI.completionBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    UI.completionBar:SetStatusBarColor(0.1, 0.65, 0.25)
    local cbBg = UI.completionBar:CreateTexture(nil, "BACKGROUND")
    cbBg:SetAllPoints(); cbBg:SetColorTexture(0, 0, 0, 0.55)
    local cbBorder = CreateFrame("Frame", nil, UI.completionBar, "BackdropTemplate")
    cbBorder:SetPoint("TOPLEFT", -2, 2); cbBorder:SetPoint("BOTTOMRIGHT", 2, -2)
    cbBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10 })
    cbBorder:SetBackdropBorderColor(0.4, 0.4, 0.4)
    UI.completion = UI.completionBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    UI.completion:SetPoint("CENTER")

    Divider(frame, 16, -16, -72)

    ------------------------------------------------------------------
    -- Left: category panel
    ------------------------------------------------------------------
    local leftBg = frame:CreateTexture(nil, "BACKGROUND")
    leftBg:SetPoint("TOPLEFT", 14, -78)
    leftBg:SetPoint("BOTTOMLEFT", 14, 16)
    leftBg:SetWidth(LEFT_W)
    leftBg:SetColorTexture(0, 0, 0, 0.25)

    catButtons = {}
    local catY = -82
    local function AddCat(key, name, icon)
        local btn = CreateFrame("Button", nil, frame, "InriCategoryButtonTemplate")
        btn:SetPoint("TOPLEFT", 18, catY)
        btn:SetWidth(LEFT_W - 8)
        btn.key = key
        btn.label:SetText(name)
        btn.icon:SetTexture(icon)
        btn:SetScript("OnClick", function() UI:SelectCategory(key) end)
        catButtons[#catButtons + 1] = btn
        catY = catY - 26
    end
    AddCat(CAT_ALL,    L["ALL"],             "Interface\\Icons\\INV_Misc_Book_09")
    AddCat(CAT_RECENT, L["RECENTLY_EARNED"], "Interface\\Icons\\INV_Misc_PocketWatch_01")
    AddCat(CAT_GUILD,  L["LEADERBOARD"],     "Interface\\Icons\\INV_Misc_Coin_02")
    AddCat(CAT_STATS,  L["STATISTICS"],      "Interface\\Icons\\INV_Misc_Note_01")
    for _, cat in ipairs(ns.Categories) do
        AddCat(cat.key, cat.name, cat.icon)
    end

    ------------------------------------------------------------------
    -- Right: search + rarity filters + list
    ------------------------------------------------------------------
    local rightX = 14 + LEFT_W + 10   -- left edge of the right pane

    local search = CreateFrame("EditBox", "InriSearchBox", frame, "InputBoxTemplate")
    search:SetSize(260, 20)
    search:SetPoint("TOPRIGHT", -40, -86)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function(self)
        UI.search = (self:GetText() or ""):lower()
        UI._list = nil
        UI:Refresh()
    end)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchLabel:SetPoint("RIGHT", search, "LEFT", -6, 0)
    searchLabel:SetText("Search")

    -- Rarity filters (horizontal, under the header on the right pane).
    local rarities = { ns.RARITY.COMMON, ns.RARITY.RARE, ns.RARITY.EPIC, ns.RARITY.LEGENDARY }
    local rx = rightX
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    filterLabel:SetPoint("TOPLEFT", rightX, -116)
    filterLabel:SetText(L["FILTER_RARITY"] .. ":")
    rx = rx + filterLabel:GetStringWidth() + 8
    for _, rarity in ipairs(rarities) do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", rx, -112)
        cb:SetChecked(true)
        local info = Util.RarityInfo(rarity)
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 1, 0)
        cb.text:SetText(Util.Colorize(L[info.locKey], info.color))
        cb:SetScript("OnClick", function(self)
            UI.rarityFilter[rarity] = self:GetChecked() and true or false
            UI._list = nil; UI:Refresh()
        end)
        rx = rx + 24 + cb.text:GetStringWidth() + 12
    end

    -- Earned / Unearned toggles (left side of the search line). These drive
    -- UI.showCompleted / UI.showIncomplete, which PassesFilters already honours.
    local function StateToggle(label, x, getter, setter)
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", x, -82)
        cb:SetChecked(getter())
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 1, 0)
        cb.text:SetText(label)
        cb:SetScript("OnClick", function(self)
            setter(self:GetChecked() and true or false)
            UI._list = nil; UI:Refresh()
        end)
        return x + 24 + cb.text:GetStringWidth() + 12
    end
    local sx = rightX
    sx = StateToggle(L["FILTER_EARNED"], sx,
        function() return UI.showCompleted end, function(v) UI.showCompleted = v end)
    StateToggle(L["FILTER_UNEARNED"], sx,
        function() return UI.showIncomplete end, function(v) UI.showIncomplete = v end)

    -- Mousewheel scrolls the list from anywhere over the window.
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        if scrollbar then
            scrollbar:SetValue(scrollbar:GetValue() - delta * (ROW_HEIGHT + 2))
        end
    end)

    -- Achievement list (FauxScrollFrame).
    scroll = CreateFrame("ScrollFrame", "InriAchScroll", frame, "FauxScrollFrameTemplate")
    scroll:SetSize(380, NUM_ROWS * (ROW_HEIGHT + 2))
    scroll:SetPoint("TOPLEFT", rightX, -140)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT + 2, UpdateList)
    end)
    scrollbar = _G["InriAchScrollScrollBar"]

    rows = {}
    for i = 1, NUM_ROWS do
        local row = CreateRow(frame, i)
        row:SetWidth(380)
        if i == 1 then
            row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", rows[i - 1], "BOTTOMLEFT", 0, -2)
        end
        rows[i] = row
    end

    -- Empty-state text
    UI.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    UI.empty:SetPoint("CENTER", scroll, "CENTER")
    UI.empty:SetText(L["NO_RESULTS"])
    UI.empty:Hide()

    -- Titles button (top-right, so its dropdown opens down into open space)
    local titlesBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    titlesBtn:SetSize(100, 22)
    titlesBtn:SetPoint("TOPRIGHT", -40, -110)
    titlesBtn:SetText(L["TITLES"])
    titlesBtn:SetScript("OnClick", function(self) ns.TitlesUI:Toggle(self) end)

    -- Report Bug button (bottom-right corner)
    local bugBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    bugBtn:SetSize(100, 22)
    bugBtn:SetPoint("BOTTOMRIGHT", -34, 16)
    bugBtn:SetText(L["BUG_BUTTON"])
    bugBtn:SetScript("OnClick", function() ns.BugReport:Show() end)

    UI.frame = frame
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function UI:Toggle()
    if not frame then BuildFrame() end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        self:Refresh()
    end
end

function UI:Show()
    if not frame then BuildFrame() end
    frame:Show()
    self:Refresh()
end

function UI:SetSearch(text)
    if not frame then BuildFrame() end
    frame:Show()
    _G["InriSearchBox"]:SetText(text or "")
    self:Refresh()
end

-- Jump to a specific achievement (from a toast click).
function UI:OpenToAchievement(id)
    local def = ns.GetAchievement(id)
    if not def then return end
    if not frame then BuildFrame() end
    frame:Show()
    self:SelectCategory(def.category)

    -- Scroll so the achievement is visible.
    local list = self._list or BuildList()
    for i, d in ipairs(list) do
        if d.id == id then
            local offset = math.max(0, i - 3)
            FauxScrollFrame_SetOffset(scroll, offset)
            if scrollbar then scrollbar:SetValue(offset * (ROW_HEIGHT + 2)) end
            UpdateList()
            break
        end
    end
end

-- Keep the window live as progress happens.
ns.Engine:RegisterCallback("PROGRESS",  function() UI:Refresh() end)
ns.Engine:RegisterCallback("COMPLETED", function() UI:Refresh() end)

----------------------------------------------------------------------
-- Chat announcements with a clickable link that opens the achievement.
-- The link uses a custom "inriach:" hyperlink type; clicking it routes through
-- SetItemRef (hooked below) to OpenToAchievement.
----------------------------------------------------------------------
function ns.AchievementLink(def)
    local hex = Util.RarityInfo(def.rarity).hex
    return string.format("|cff%s|Hinriach:%s|h[%s]|h|r", hex, def.id, def.name)
end

hooksecurefunc("SetItemRef", function(link)
    local id = link and link:match("^inriach:(.+)$")
    if id then ns.UI:OpenToAchievement(id) end
end)

-- charName/classColor are nil for the local player (we fill them in).
function ns.AnnounceEarned(charName, def, classColor)
    local who = charName or UnitName("player")
    local nameStr = classColor and Util.Colorize(who, classColor) or Util.Colorize(who, { 0, 1, 0.59 })
    DEFAULT_CHAT_FRAME:AddMessage(string.format("%s has earned the achievement %s!",
        nameStr, ns.AchievementLink(def)))
end

ns.Engine:RegisterCallback("COMPLETED", function(id, def)
    if not ns.DB:Settings().announce or ns._suppressNotify then return end
    ns.AnnounceEarned(nil, def, Util.ClassColor(ns.DB:GetMeta().classToken))
    if ns.Comm then ns.Comm:AnnounceEarned(id) end
end)
