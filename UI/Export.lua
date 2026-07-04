--[[--------------------------------------------------------------------------
    Inri's Achievements! - Export / Import

    /ia export  - opens a window with a copyable string of this character's
                  completed achievement ids ("IA1:id1,id2,...").
    /ia import <string> - restores those completions (silent: no toasts or
                  announces), e.g. after a data loss or a transfer between
                  accounts. META/POINTS chains re-evaluate automatically.
----------------------------------------------------------------------------]]

local _, ns = ...
local Util = ns.Util

local Export = {}
ns.Export = Export

local frame

----------------------------------------------------------------------
-- Serialisation
----------------------------------------------------------------------
function Export:Serialize()
    local ids = {}
    for _, def in ipairs(ns.Achievements) do
        if ns.DB:IsCompleted(def.id) then ids[#ids + 1] = def.id end
    end
    table.sort(ids)
    return "IA1:" .. table.concat(ids, ",")
end

function Export:Import(str)
    local body = str and str:match("^%s*IA1:(.*)$")
    if not body then
        Util.Print("Import string must start with |cffffd100IA1:|r (from /ia export).")
        return
    end
    local restored, unknown = 0, 0
    ns._suppressNotify = true
    for id in body:gmatch("[^,%s]+") do
        if ns.GetAchievement(id) then
            if not ns.DB:IsCompleted(id) then
                ns.Engine:CompleteAchievement(id)
                restored = restored + 1
            end
        else
            unknown = unknown + 1
        end
    end
    ns._suppressNotify = false
    ns.DB:Prune()             -- recompute totals defensively
    if ns.UI then ns.UI:Refresh() end
    Util.Print(string.format("Import complete: %d restored, %d unknown ids skipped.",
        restored, unknown))
end

----------------------------------------------------------------------
-- Export window (copyable box)
----------------------------------------------------------------------
local function BuildFrame()
    frame = CreateFrame("Frame", "InrisExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(420, 190)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
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
    tinsert(UISpecialFrames, "InrisExportFrame")

    local ribbon = frame:CreateTexture(nil, "OVERLAY")
    ribbon:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    ribbon:SetSize(260, 58)
    ribbon:SetPoint("TOP", 0, 26)
    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOP", ribbon, "TOP", 0, -13)
    heading:SetText("Export")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 24, -42)
    hint:SetText("Ctrl+C to copy. Restore on another install with /ia import <string>.")

    local box = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    box:SetPoint("TOPLEFT", 24, -62)
    box:SetSize(372, 100)
    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    box:SetBackdropColor(0, 0, 0, 0.5)
    box:SetBackdropBorderColor(0.6, 0.5, 0.3)

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(336)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self, user)
        if user and self.lockedText then self:SetText(self.lockedText) end
    end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    scroll:SetScrollChild(edit)
    frame.edit = edit
end

function Export:Show()
    if not frame then BuildFrame() end
    local s = self:Serialize()
    frame.edit.lockedText = s
    frame.edit:SetText(s)
    frame:Show()
    frame.edit:SetFocus()
    frame.edit:HighlightText()
end
