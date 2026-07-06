--[[--------------------------------------------------------------------------
    Inri's Achievements! - Bootstrap

    Loaded last. Wires up the saved variables, enables every subsystem in the
    right order, runs the initial state scan, and registers slash commands.
----------------------------------------------------------------------------]]

local addonName, ns = ...
local L    = ns.L
local Util = ns.Util

local booted = false

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
local function HandleSlash(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "show" or cmd == "open" then
        ns.UI:Toggle()

    elseif cmd == "search" then
        ns.UI:SetSearch(rest)

    elseif cmd == "stats" then
        local s = ns.Engine:GetStats()
        Util.Print(string.format("%s: |cffffd100%d|r   %s: %d/%d (%.0f%%)",
            L["TOTAL_POINTS"], s.points, L["COMPLETION"], s.completed, s.total, s.percent))

    elseif cmd == "inspect" or cmd == "view" then
        if rest ~= "" then ns.Inspect:Open(rest)
        else Util.Print("Usage: /ia inspect <name>") end

    elseif cmd == "bug" or cmd == "report" then
        ns.BugReport:Show()

    elseif cmd == "flex" then
        ns.Extras:Flex()

    elseif cmd == "here" then
        -- What's still earnable around your current location. Matches explicit
        -- zone conditions, staged zone keys, zone-named subcategories, and
        -- zone mentions in descriptions (our texts name their places).
        local zone, sub = GetRealZoneText() or "", GetSubZoneText() or ""
        local hits = {}
        for _, def in ipairs(ns.Achievements) do
            if not ns.DB:IsCompleted(def.id)
               and not (def.hidden and not ns.DB:GetDiscovery(def.id)) then
                local c = def.conditions or {}
                local match = false
                for _, z in ipairs(c.zones or {}) do
                    if z == zone or (sub ~= "" and z == sub) then match = true end
                end
                if not match then
                    for _, z in ipairs(c.inZone or {}) do
                        if z == zone or (sub ~= "" and z == sub) then match = true end
                    end
                end
                if not match and def.stages then
                    for _, s in ipairs(def.stages) do
                        if s.key == zone or (sub ~= "" and s.key == sub) then match = true end
                    end
                end
                if not match and def.subcategory and zone ~= "" then
                    if def.subcategory:find(zone, 1, true)
                       or zone:find(def.subcategory, 1, true) then match = true end
                end
                if not match and zone ~= "" and def.description
                   and def.description:find(zone, 1, true) then match = true end
                if match then hits[#hits + 1] = def end
            end
        end
        table.sort(hits, function(a, b)
            if a.rarity ~= b.rarity then return a.rarity > b.rarity end
            return a.name < b.name
        end)
        if #hits == 0 then
            Util.Print("Nothing left to earn in " .. (zone ~= "" and zone or "this area") .. ".")
        else
            Util.Print("|cffffd100Still to earn in " .. zone .. ":|r")
            for i = 1, math.min(#hits, 15) do
                local d = hits[i]
                Util.Print("  " .. ns.AchievementLink(d) .. " |cff808080" .. d.points .. " pts|r")
            end
            if #hits > 15 then Util.Print("  ...and " .. (#hits - 15) .. " more.") end
        end

    elseif cmd == "icons" then
        -- Audit every icon path against the client's file database.
        if not GetFileIDFromPath then
            Util.Print("This client cannot verify file paths.")
        else
            local bad = 0
            for _, def in ipairs(ns.Achievements) do
                if def.iconMissing then
                    bad = bad + 1
                    Util.Print("|cffff4040missing:|r " .. def.id .. " -> " .. def.iconMissing)
                end
            end
            for _, cat in ipairs(ns.Categories) do
                if cat.icon and not GetFileIDFromPath(cat.icon) then
                    bad = bad + 1
                    Util.Print("|cffff4040missing (category):|r " .. cat.key .. " -> " .. cat.icon)
                end
            end
            if not GetFileIDFromPath(ns.LOGO) then
                bad = bad + 1
                Util.Print("|cffff4040missing:|r addon logo -> " .. ns.LOGO)
            end
            Util.Print(bad == 0 and "All icons OK."
                or (bad .. " bad icon path(s) - they show as '?' until fixed."))
        end

    elseif cmd == "verify" then
        -- Check the current target against every kill achievement. Used to
        -- confirm mob names in the database while leveling (see VERIFY flags).
        local name = UnitName("target")
        if not name then
            Util.Print("Target a creature, then /ia verify.")
        else
            local npcID = Util.NpcIDFromGUID(UnitGUID("target"))
            local hits = 0
            for _, def in ipairs(ns.Achievements) do
                if def.trigger == "KILL" and def.conditions then
                    local match = false
                    for _, n in ipairs(def.conditions.mobNames or {}) do
                        if n == name then match = true end
                    end
                    for _, id in ipairs(def.conditions.npcIDs or {}) do
                        if npcID and id == npcID then match = true end
                    end
                    if match then
                        hits = hits + 1
                        Util.Print("|cff40ff40tracked:|r " .. def.name .. " |cff808080(" .. def.id .. ")|r")
                    end
                end
            end
            if hits == 0 then
                Util.Print("|cffff4040no achievement matches|r '" .. name .. "'"
                    .. (npcID and (" (npc " .. npcID .. ")") or ""))
            end
        end

    elseif cmd == "whoami" then
        local tag = BNGetInfo and (select(2, BNGetInfo()))
        if tag then
            Util.Print("Account hash: |cffffd100" .. Util.HashString(tag) .. "|r")
            Util.Print("Set this as CREATOR_HASH in Core\\Constants.lua to claim 'Make This Addon'.")
        else
            Util.Print("Battle.net info not available right now - try again in a moment.")
        end

    elseif cmd == "titles" then
        ns.TitlesUI:Toggle()

    elseif cmd == "sync" then
        ns.Comm:BroadcastSummary(true)
        ns.Comm:Hello()
        Util.Print("Roster sync sent.")

    elseif cmd == "config" then
        local s = ns.DB:Settings()
        if rest == "sound" then
            s.toastSound = not s.toastSound
            Util.Print("Toast sound: " .. (s.toastSound and "ON" or "OFF"))
        elseif rest == "toast" then
            s.toast = not s.toast
            Util.Print("Toasts: " .. (s.toast and "ON" or "OFF"))
        elseif rest == "guild" then
            s.shareGuild = not s.shareGuild
            Util.Print("Guild sharing: " .. (s.shareGuild and "ON" or "OFF"))
        elseif rest == "announce" then
            s.announce = not s.announce
            Util.Print("Earned announcements: " .. (s.announce and "ON" or "OFF"))
        elseif rest == "radar" then
            s.radar = not s.radar
            Util.Print("Rare Radar: " .. (s.radar and "ON" or "OFF"))
        elseif rest == "screenshot" then
            s.screenshot = not s.screenshot
            Util.Print("Auto-screenshots: " .. (s.screenshot and "ON" or "OFF"))
        elseif rest == "guildflex" then
            s.guildFlex = not s.guildFlex
            Util.Print("Guild chat flex (Rare+): " .. (s.guildFlex and "ON" or "OFF"))
        elseif rest == "muteflex" then
            s.muteGuildFlex = not s.muteGuildFlex
            Util.Print("Hide others' flex lines: " .. (s.muteGuildFlex and "ON" or "OFF"))
        else
            -- No (or unknown) option: show every toggle with its current
            -- state and what it does.
            local function line(opt, on, desc)
                Util.Print(string.format("  |cffffd100%s|r %s |cff808080- %s|r",
                    opt, on and "|cff40ff40ON|r" or "|cffff4040OFF|r", desc))
            end
            Util.Print("Toggle with |cffffd100/ia config <option>|r:")
            line("toast",      s.toast,         "achievement popup banners")
            line("sound",      s.toastSound,    "toast sound effects")
            line("announce",   s.announce,      "chat lines when achievements are earned")
            line("guild",      s.shareGuild,    "share your progress with guildmates")
            line("guildflex",  s.guildFlex,     "post Rare+ earns to real guild chat (everyone sees)")
            line("muteflex",   s.muteGuildFlex, "hide other addon users' flex lines (you get the clickable version)")
            line("radar",      s.radar,         "ping when a named mob you still need is nearby")
            line("screenshot", s.screenshot,    "auto-screenshot on Epic+ earns")
            Util.Print("|cff808080Also in Interface Options > AddOns > Inri's Achievements.|r")
        end

    elseif cmd == "reset" then
        if rest == "confirm" then
            ns.DB:WipeCharacter()
            ns.UI:Refresh()
            Util.Print("This character's achievement progress has been wiped.")
        else
            Util.Print("|cffff4040This wipes ALL progress on this character.|r Type |cffffd100/ia reset confirm|r to proceed.")
        end

    else
        Util.Print(L["SLASH_HELP_HEADER"])
        Util.Print("/ia here - what you can still earn around you")
        Util.Print(L["SLASH_OPEN"]); Util.Print(L["SLASH_SEARCH"])
        Util.Print(L["SLASH_STATS"]); Util.Print(L["SLASH_SYNC"])
        Util.Print(L["SLASH_TITLE"]); Util.Print(L["SLASH_BUG"])
        Util.Print(L["SLASH_CONFIG"]); Util.Print(L["SLASH_RESET"])
    end
end

SLASH_INRISACHIEVEMENTS1 = "/ia"
SLASH_INRISACHIEVEMENTS2 = "/inri"
SLASH_INRISACHIEVEMENTS3 = "/achievements"
SlashCmdList["INRISACHIEVEMENTS"] = HandleSlash

----------------------------------------------------------------------
-- Boot sequence
----------------------------------------------------------------------
local function Boot()
    if booted then return end
    booted = true

    ns.DB:Initialize()
    ns.DB:Prune()   -- drop orphaned progress (e.g. removed test achievements)

    -- Re-reveal sealed hidden achievements that are already discovered (the
    -- seal key persists with the discovery record / completion).
    for _, def in ipairs(ns.Achievements) do
        if def.sealed then
            local d = ns.DB.account.discoveries[def.id]
            if d or ns.DB:IsCompleted(def.id) then
                ns.TryRevealHidden(def, d and d.k)
            end
        end
    end
    ns.Events:Enable()
    ns.Comm:Enable()
    ns.Inspect:HookUnitMenu()
    ns.TitlesUI:HookTooltip()
    ns.Options:Register()
    ns.Minimap:Create()
end

local function OnLogin()
    -- Scan current state so already-satisfied achievements/progress are caught,
    -- then announce ourselves to the group/guild.
    ns.DB:RefreshMeta()

    -- Stamp the level we first watched this character at (once). Deathless
    -- feats are only honest if that is level 1; otherwise void any that slipped
    -- through before this failsafe existed.
    local meta = ns.DB:GetMeta()
    if not meta.firstSeenLevel then meta.firstSeenLevel = UnitLevel("player") end
    ns.DB:ValidateDeathless()

    ns.Events:InitialScan()

    -- Snapshot this character for the account-wide leaderboard (kept fresh
    -- on every future completion too), then bring up the tracker.
    ns.DB:SnapshotAlt()
    ns.Engine:RegisterCallback("COMPLETED", function() ns.DB:SnapshotAlt() end)
    ns.Tracker:Refresh()

    C_Timer.After(3, function()
        ns.Comm:Hello()
    end)

    Util.Print(L["ADDON_LOADED"])
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("ADDON_LOADED")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Boot()
    elseif event == "PLAYER_LOGIN" then
        if not booted then Boot() end  -- safety if ADDON_LOADED was missed
        OnLogin()
    end
end)
