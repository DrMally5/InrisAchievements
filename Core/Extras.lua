--[[--------------------------------------------------------------------------
    Inri's Achievements! - Fun Extras

    The delight layer:
      * Rare Radar    - targeting/mousing over/nameplating a named mob you
                        still need pings you with which achievement wants it.
      * Auto-screenshot on Epic+ earns (keepsakes folder!).
      * "Almost there" nudges at 90% on tracked counters.
      * Deathless death-knell - a somber note when a deathless run ends.
      * /ia flex - brag line to chat.
----------------------------------------------------------------------------]]

local _, ns = ...
local L    = ns.L
local Util = ns.Util

local Extras = {}
ns.Extras = Extras

----------------------------------------------------------------------
-- Rare Radar
----------------------------------------------------------------------
local radarMap          -- [mobName] = def (built lazily; outdoor names only)
local radarAlerted = {} -- [mobName] = GetTime() of last alert (session)
local RADAR_CD = 300

local function BuildRadarMap()
    radarMap = {}
    for _, def in ipairs(ns.Achievements) do
        -- Outdoor named/rare hunts only (post-merge category NAMED); never
        -- leak hidden achievements through the radar.
        if def.trigger == "KILL" and def.category == "NAMED" and not def.hidden
           and def.conditions and def.conditions.mobNames then
            for _, n in ipairs(def.conditions.mobNames) do
                radarMap[n] = radarMap[n] or def
            end
        end
    end
end

-- Called whenever a unit becomes visible (target/mouseover/nameplate).
function Extras:OnUnitSeen(unit)
    if not ns.DB:Settings().radar then return end
    if not UnitExists(unit) or UnitIsPlayer(unit) or UnitIsDead(unit) then return end
    if not radarMap then BuildRadarMap() end

    local name = UnitName(unit)
    local def = name and radarMap[name]
    if not def or ns.DB:IsCompleted(def.id) then return end

    local now = GetTime()
    if radarAlerted[name] and (now - radarAlerted[name]) < RADAR_CD then return end
    radarAlerted[name] = now

    Util.Print(string.format(L["RADAR_NEARBY"], name, ns.AchievementLink(def)))
    pcall(PlaySound, ns.SOUND.PING, "Master")
end

----------------------------------------------------------------------
-- Deathless death-knell (also owns the death bookkeeping so the check
-- happens BEFORE the death is recorded)
----------------------------------------------------------------------
function Extras:OnPlayerDead()
    local wasDeathless = ns.DB:DeathlessEligible()
    local level = UnitLevel("player") or 0
    ns.DB:AddDeath()
    if wasDeathless and level >= 10 then
        Util.Print("|cff9d9d9d" .. string.format(L["KNELL"], level) .. "|r")
        pcall(PlaySound, ns.SOUND.LEGENDARY, "Master")
    end
end

----------------------------------------------------------------------
-- /ia flex
----------------------------------------------------------------------
function Extras:Flex()
    local rarest, rarestT
    for _, def in ipairs(ns.Achievements) do
        if ns.DB:IsCompleted(def.id) then
            local t = ns.DB:GetCompletedTime(def.id) or 0
            if not rarest or def.rarity > rarest.rarity
               or (def.rarity == rarest.rarity and t > (rarestT or 0)) then
                rarest, rarestT = def, t
            end
        end
    end

    local m = ns.DB:GetMeta()
    local title = ns.Titles:GetActive()
    local who = m.name .. (title and (" " .. title.text) or "")
    local msg = string.format(L["FLEX_LINE"], who, ns.DB:GetPoints(),
        ns.DB:GetCount(), #ns.Achievements, rarest and rarest.name or "none yet")

    local channel = IsInGroup() and (IsInRaid() and "RAID" or "PARTY")
                 or (IsInGuild() and "GUILD") or "SAY"
    pcall(SendChatMessage, msg, channel)
end

----------------------------------------------------------------------
-- Guild flex: post big earns to REAL guild chat, visible to every
-- guildmate (addon or not). Rare+/hidden only, and staggered so a meta
-- cascade (one kill completing several achievements) never spams.
--
-- Addon users get the prettier clickable announcement through the comm
-- layer, so by default a chat filter hides these raw lines for them -
-- only guildmates WITHOUT the addon see them (which is the point).
----------------------------------------------------------------------
local FLEX_TAG = "[Inri's Achievements]"
local flexQueue = {}
local flexBusy = false

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(_, _, msg, sender, ...)
    if not (msg and msg:find(FLEX_TAG, 1, true)) then return false end
    -- Make the achievement name clickable for addon users. The plain text is
    -- what travels the wire; non-addon guildmates never run this and see it
    -- unchanged.
    local linked = ns.LinkifyFlex and ns.LinkifyFlex(msg)
    if linked and linked ~= msg then
        return false, linked, sender, ...
    end
    return false
end)

local function PumpFlex()
    if flexBusy then return end
    local msg = table.remove(flexQueue, 1)
    if not msg then return end
    flexBusy = true
    pcall(SendChatMessage, msg, "GUILD")
    C_Timer.After(3, function() flexBusy = false; PumpFlex() end)
end

ns.Engine:RegisterCallback("COMPLETED", function(id, def)
    if ns._suppressNotify then return end
    if not ns.DB:Settings().guildFlex or not IsInGuild() then return end
    if def.rarity < ns.RARITY.RARE and not def.hidden then return end

    local msg
    if def.hidden then
        msg = string.format("just discovered a hidden achievement: %s! %s",
            def.name, FLEX_TAG)
    else
        msg = string.format("just earned %s (%s, %d pts)%s %s",
            def.name, Util.RarityName(def.rarity), def.points,
            (def.title and def.title.text)
                and (" and the title \"" .. def.title.text .. "\"") or "",
            FLEX_TAG)
    end
    flexQueue[#flexQueue + 1] = msg
    PumpFlex()
end)

----------------------------------------------------------------------
-- Engine callbacks: screenshots, nudges, local first-marks
----------------------------------------------------------------------
local nudged = {}   -- [achID] = true (session)

ns.Engine:RegisterCallback("COMPLETED", function(id, def)
    -- Keepsake screenshot for the big ones, timed so the toast is on screen.
    if def.rarity >= ns.RARITY.EPIC and not ns._suppressNotify
       and ns.DB:Settings().screenshot then
        C_Timer.After(1.0, function() pcall(Screenshot) end)
    end
end)

ns.Engine:RegisterCallback("PROGRESS", function(id, def, value, target)
    if nudged[id] or not target or target < 5 then return end
    if not ns.DB:IsTracked(id) then return end
    if value / target < 0.9 or value >= target then return end
    nudged[id] = true
    Util.Print(string.format(L["NUDGE"], def.name, Util.FormatFraction(value, target)))
    pcall(PlaySound, ns.SOUND.PING, "Master")
end)
