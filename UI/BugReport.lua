--[[--------------------------------------------------------------------------
    Inri's Achievements! - Bug Report Window

    WoW addons cannot transmit data to the internet, so this follows the
    standard addon pattern: the player describes the problem, we prepend
    diagnostics (addon version, client build, character, zone, progress),
    and produce a ready-to-copy report plus the issue-tracker URL.

    Opened via /ia bug or the "Report Bug" button on the main window.
----------------------------------------------------------------------------]]

local _, ns = ...
local L    = ns.L
local Util = ns.Util

local BugReport = {}
ns.BugReport = BugReport

local frame

----------------------------------------------------------------------
-- Report text
----------------------------------------------------------------------
local function BuildReport(desc)
    local version, build = GetBuildInfo()
    local m = ns.DB:GetMeta()
    local lines = {
        "=== Inri's Achievements! bug report ===",
        "Addon:     v" .. ns.VERSION,
        "Client:    " .. tostring(version) .. " (build " .. tostring(build) .. ")",
        "Character: " .. (m.key or "?") .. " - " .. (m.race or "?") .. " "
            .. (m.class or "?") .. ", level " .. tostring(UnitLevel("player")),
        "Zone:      " .. (GetRealZoneText() or "?"),
        "Date:      " .. date("%Y-%m-%d %H:%M"),
        string.format("Progress:  %d pts, %d/%d earned",
            ns.DB:GetPoints(), ns.DB:GetCount(), #ns.Achievements),
        "",
        "Description:",
        (desc and desc ~= "") and desc or "(none provided)",
    }
    return table.concat(lines, "\n")
end

----------------------------------------------------------------------
-- Widgets
----------------------------------------------------------------------
-- A bordered, scrollable multi-line edit box. Returns (container, editbox).
local function MultiLineBox(parent, width, height, readOnlyText)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(width, height)
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
    edit:SetWidth(width - 36)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)

    -- Clicking anywhere in the box focuses the edit field.
    box:EnableMouse(true)
    box:SetScript("OnMouseUp", function() edit:SetFocus() end)

    if readOnlyText then
        -- Output box: any attempted edit snaps back to the generated report,
        -- and focusing selects everything so Ctrl+C just works.
        edit:SetScript("OnTextChanged", function(self, user)
            if user and self.lockedText then self:SetText(self.lockedText) end
        end)
        edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    end

    return box, edit
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
local function BuildFrame()
    frame = CreateFrame("Frame", "InrisBugReportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(440, 470)
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
    tinsert(UISpecialFrames, "InrisBugReportFrame")

    -- Classic ribbon header.
    local ribbon = frame:CreateTexture(nil, "OVERLAY")
    ribbon:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    ribbon:SetSize(300, 58)
    ribbon:SetPoint("TOP", 0, 26)
    local heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOP", ribbon, "TOP", 0, -13)
    heading:SetText(L["BUG_TITLE"])

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    -- Instructions + description input.
    local instr = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instr:SetPoint("TOPLEFT", 24, -44)
    instr:SetWidth(392)
    instr:SetJustifyH("LEFT")
    instr:SetText(L["BUG_INSTR"])

    local inputBox, inputEdit = MultiLineBox(frame, 392, 130)
    inputBox:SetPoint("TOPLEFT", 24, -78)
    frame.inputEdit = inputEdit

    -- Generate button.
    local gen = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    gen:SetSize(150, 24)
    gen:SetPoint("TOP", inputBox, "BOTTOM", 0, -8)
    gen:SetText(L["BUG_GENERATE"])

    -- Output (read-only) + copy hint + URL.
    local outBox, outEdit = MultiLineBox(frame, 392, 120, true)
    outBox:SetPoint("TOP", gen, "BOTTOM", 0, -8)
    frame.outEdit = outEdit

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", outBox, "BOTTOMLEFT", 0, -8)
    hint:SetText(L["BUG_COPY"])

    local url = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    url:SetSize(384, 20)
    url:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 8, -4)
    url:SetAutoFocus(false)
    url:SetText(ns.BUGREPORT_URL)
    url:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    url:SetScript("OnTextChanged", function(self, user)
        if user then self:SetText(ns.BUGREPORT_URL); self:HighlightText() end
    end)
    url:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    gen:SetScript("OnClick", function()
        local report = BuildReport(frame.inputEdit:GetText())
        frame.outEdit.lockedText = report
        frame.outEdit:SetText(report)
        frame.outEdit:SetFocus()
        frame.outEdit:HighlightText()
    end)
end

----------------------------------------------------------------------
-- Public
----------------------------------------------------------------------
function BugReport:Show()
    if not frame then BuildFrame() end
    frame:Show()
end

function BugReport:Toggle()
    if not frame then BuildFrame() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end
