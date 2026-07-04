--[[--------------------------------------------------------------------------
    Inri's Achievements! - On-screen Objective Tracker

    A small quest-tracker-style frame listing up to 5 achievements the player
    pinned via right-click in the main window. Shows live progress, updates on
    PROGRESS/COMPLETED, auto-unpins completed entries, hides when empty.
    Draggable; position persists account-wide. Right-click a line to unpin.
----------------------------------------------------------------------------]]

local _, ns = ...
local L    = ns.L
local Util = ns.Util

local Tracker = {}
ns.Tracker = Tracker

local MAX_LINES = 5
local frame, lines

local function SavePosition()
    local point, _, relPoint, x, y = frame:GetPoint()
    ns.DB:Settings().tracker = { point = point, relPoint = relPoint, x = x, y = y }
end

local function BuildFrame()
    frame = CreateFrame("Frame", "InrisTrackerFrame", UIParent)
    frame:SetSize(220, 20 + MAX_LINES * 18)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)
    frame:SetClampedToScreen(true)

    local pos = ns.DB:Settings().tracker
    if pos and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
        frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
    end

    frame.header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.header:SetPoint("TOPLEFT", 0, 0)
    frame.header:SetText("|cffffd100" .. L["TRACKER_TITLE"] .. "|r")

    local rule = frame:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(1, 0.82, 0, 0.4)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 0, -2)
    rule:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -16)

    lines = {}
    for i = 1, MAX_LINES do
        local line = CreateFrame("Button", nil, frame)
        line:SetSize(220, 16)
        line:SetPoint("TOPLEFT", 0, -20 - (i - 1) * 18)
        line.text = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.text:SetPoint("LEFT", 2, 0)
        line.text:SetJustifyH("LEFT")
        line.text:SetWidth(216)
        line:RegisterForClicks("RightButtonUp")
        line:SetScript("OnClick", function(self)
            if self.achID then
                ns.DB:ToggleTracked(self.achID)
                Tracker:Refresh()
            end
        end)
        lines[i] = line
    end
end

function Tracker:Refresh()
    local tracked = ns.DB:GetTracked()
    if not frame then
        if #tracked == 0 then return end
        BuildFrame()
    end

    local shown = 0
    for i = 1, MAX_LINES do
        local id = tracked[i]
        local def = id and ns.GetAchievement(id)
        local line = lines[i]
        if def and not ns.DB:IsCompleted(id) then
            shown = shown + 1
            line.achID = id
            local c = Util.RarityInfo(def.rarity).hex
            local progress = ""
            if def.progressType ~= ns.PROGRESS.BOOLEAN then
                local cur = (def.progressType == ns.PROGRESS.STAGED)
                    and ns.DB:CountStages(id) or ns.DB:GetValue(id)
                progress = "  |cffffffff" .. Util.FormatFraction(cur, def.target) .. "|r"
            end
            line.text:SetText("|cff" .. c .. "- " .. def.name .. "|r" .. progress)
            line:Show()
        else
            line.achID = nil
            line:Hide()
        end
    end

    frame:SetShown(shown > 0)
end

-- Live updates + auto-unpin on completion.
ns.Engine:RegisterCallback("PROGRESS", function() Tracker:Refresh() end)
ns.Engine:RegisterCallback("COMPLETED", function(id)
    local tracked = ns.DB:GetTracked()
    for i = #tracked, 1, -1 do
        if tracked[i] == id then table.remove(tracked, i) end
    end
    Tracker:Refresh()
end)
