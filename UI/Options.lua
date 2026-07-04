--[[--------------------------------------------------------------------------
    Inri's Achievements! - Options Panel

    Registers a simple canvas in Interface Options -> AddOns mirroring the
    /ia config toggles. Entirely pcall-guarded: if the Settings API differs on
    a given client, the addon silently falls back to /ia config.
----------------------------------------------------------------------------]]

local _, ns = ...
local L = ns.L

local Options = {}
ns.Options = Options

local TOGGLES = {
    { key = "toast",      label = "Show achievement toasts" },
    { key = "toastSound", label = "Play toast sound" },
    { key = "announce",   label = "Chat announcements (yours and others')" },
    { key = "shareGuild", label = "Share progress with guild" },
    { key = "radar",      label = "Rare Radar (alert when a needed mob is nearby)" },
    { key = "screenshot", label = "Auto-screenshot on Epic+ achievements" },
}

function Options:Register()
    local ok = pcall(function()
        if not (Settings and Settings.RegisterCanvasLayoutCategory
                and Settings.RegisterAddOnCategory) then
            error("no Settings API")
        end

        local panel = CreateFrame("Frame")
        panel.name = L["ADDON_TITLE"]

        local logo = panel:CreateTexture(nil, "ARTWORK")
        logo:SetSize(28, 28)
        logo:SetPoint("TOPLEFT", 16, -14)
        logo:SetTexture(ns.LOGO)

        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
        title:SetText(L["ADDON_TITLE"])

        local boxes = {}
        local y = -60
        for _, t in ipairs(TOGGLES) do
            local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            cb:SetSize(24, 24)
            cb:SetPoint("TOPLEFT", 16, y)
            cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            cb.text:SetText(t.label)
            cb:SetScript("OnClick", function(self)
                ns.DB:Settings()[t.key] = self:GetChecked() and true or false
            end)
            cb.settingKey = t.key
            boxes[#boxes + 1] = cb
            y = y - 30
        end

        panel:SetScript("OnShow", function()
            for _, cb in ipairs(boxes) do
                cb:SetChecked(ns.DB:Settings()[cb.settingKey])
            end
        end)

        local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        hint:SetPoint("TOPLEFT", 16, y - 10)
        hint:SetText("More commands: /ia  (help), /ia bug, /ia titles, /ia flex")

        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    end)
    -- On failure: /ia config remains the configuration path.
    return ok
end
