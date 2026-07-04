--[[--------------------------------------------------------------------------
    Inri's Achievements! - Minimap Button

    A self-contained minimap button (no external libraries). Left-click toggles
    the window; drag repositions it around the minimap. Position persists in
    the account settings.
----------------------------------------------------------------------------]]

local _, ns = ...
local L = ns.L

-- The global "Minimap" is WoW's minimap frame. Capture it under a distinct
-- name so our module table below does not shadow it (that shadowing was the
-- "Wrong object type" bug - CreateFrame was being handed this table as parent).
local MinimapFrame = _G.Minimap

local Minimap = {}
ns.Minimap = Minimap

local button

local function UpdatePosition()
    local angle = math.rad(ns.DB:Settings().minimap.angle or 215)
    local radius = 80
    button:SetPoint("CENTER", MinimapFrame, "CENTER",
        radius * math.cos(angle), radius * math.sin(angle))
end

local function OnDrag(self)
    local mx, my = MinimapFrame:GetCenter()
    local px, py = GetCursorPosition()
    local scale = MinimapFrame:GetEffectiveScale()
    px, py = px / scale, py / scale
    local angle = math.deg(math.atan2(py - my, px - mx))
    ns.DB:Settings().minimap.angle = angle
    UpdatePosition()
end

function Minimap:Create()
    if button or ns.DB:Settings().minimap.hide then return end

    button = CreateFrame("Button", "InrisMinimapButton", MinimapFrame)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetTexture(ns.LOGO)
    icon:SetPoint("CENTER", 0, 1)

    button:SetScript("OnClick", function(_, btn)
        if btn == "RightButton" then
            ns.UI:Show()
            ns.UI:SelectCategory("RECENT")
        else
            ns.UI:Toggle()
        end
    end)

    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", OnDrag) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L["ADDON_TITLE"], 0, 1, 0.59)
        local stats = ns.Engine:GetStats()
        GameTooltip:AddLine(string.format("%d %s  (%.0f%%)",
            stats.points, L["POINTS_SUFFIX"], stats.percent), 1, 0.82, 0)
        GameTooltip:AddLine("|cffffffffLeft-click:|r Open", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cffffffffRight-click:|r Recent", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdatePosition()
end
