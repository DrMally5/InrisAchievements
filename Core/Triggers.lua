--[[--------------------------------------------------------------------------
    Inri's Achievements! - Trigger Evaluators

    Each trigger type owns one evaluator: given an achievement definition and an
    event payload, it returns a "result" the engine applies (see Engine.lua):
        false/nil  -> nothing happened
        true       -> a hit (completes BOOLEAN, increments COUNTER)
        number     -> set value (PROGRESS / COUNTER absolute)
        string     -> a stage key (STAGED)

    Adding a new *kind* of achievement behaviour means adding one evaluator
    here. Existing achievements never need changing.
----------------------------------------------------------------------------]]

local _, ns = ...
local Engine = ns.Engine

----------------------------------------------------------------------
-- Small helpers: build lookup sets lazily and cache them on the def so the
-- conversion happens once per achievement, not once per event.
----------------------------------------------------------------------
local function NumberSet(list)
    local set = {}
    for _, v in ipairs(list) do set[v] = true end
    return set
end

local function StringSet(list)
    local set = {}
    for _, v in ipairs(list) do set[tostring(v)] = true end
    return set
end

----------------------------------------------------------------------
-- KILL: a creature died to the player/group.
-- payload: { npcID, mobLevel, classification, playerLevel, groupSize,
--            groupMaxLevel, zone, subZone }
----------------------------------------------------------------------
local function KillQualifies(def, p)
    local c = def.conditions
    local sealKey   -- unwrapped seal key for a sealed secret; the reveal is
                    -- deferred until the WHOLE kill qualifies, so the wrong
                    -- same-named mob (e.g. the RFK Princess) never spoils it.

    -- UNIT_DIED is a noisy source (every nearby death). Only let it credit
    -- achievements that name a specific target; broad/counter achievements
    -- require a confirmed PARTY_KILL.
    local specific = c.npcIDs or c.mobNames or c.matchers
    if p.source == "UNIT_DIED" and not specific then
        return false
    end

    -- Sealed name matching (hidden secrets): the target ships only as a hash;
    -- a real match unwraps the def's master key and reveals its true text.
    if c.matchers then
        if not p.mobName then return false end
        local hash, ok = ns.Util.HashString(p.mobName), false
        for _, m in ipairs(c.matchers) do
            if m.h == hash then
                sealKey = ns.Util.SealXor(m.w, p.mobName)  -- defer the reveal
                ok = true
                break
            end
        end
        if not ok then return false end
    end

    -- Specific creatures, matched by NPC ID and/or name. Name matching makes
    -- world-mob achievements robust even if an exact ID drifts between
    -- client versions; bosses tend to use IDs. If either matcher is present,
    -- the kill must satisfy at least one of them.
    if c.npcIDs or c.mobNames then
        local ok = false
        if c.npcIDs and p.npcID then
            def._npcSet = def._npcSet or NumberSet(c.npcIDs)
            if def._npcSet[p.npcID] then ok = true end
        end
        if not ok and c.mobNames and p.mobName then
            def._nameSet = def._nameSet or (function()
                local s = {}; for _, n in ipairs(c.mobNames) do s[n] = true end; return s
            end)()
            if def._nameSet[p.mobName] then ok = true end
        end
        if not ok then return false end
    end

    -- Mob classification (rare / rareelite / elite / worldboss).
    if c.classification then
        if not p.classification or not c.classification[p.classification] then
            return false
        end
    end

    -- Player must be at or below this level when the blow lands.
    if c.maxPlayerLevel and (p.playerLevel or 0) > c.maxPlayerLevel then
        return false
    end

    -- Solo only (self counts as group size 1; 0 also means ungrouped).
    if c.solo and (p.groupSize or 1) > 1 then
        return false
    end

    -- Mob must out-level the player by at least N. A "??" (skull) mob reports
    -- level -1, which by definition is far above us, so it qualifies.
    if c.minLevelAbove then
        local ml = p.mobLevel
        if ml == nil then return false end
        if ml ~= -1 and (ml - (p.playerLevel or 0)) < c.minLevelAbove then
            return false
        end
    end

    -- No group member may exceed this level (dungeon level-cap runs).
    if c.maxGroupLevel and (p.groupMaxLevel or 0) > c.maxGroupLevel then
        return false
    end

    -- Speed-clear: the kill must land within N seconds of entering the instance.
    if c.maxSeconds then
        if not p.runTime or p.runTime > c.maxSeconds then return false end
    end

    -- Sealed variant of inZone: the zone list ships as hashes.
    if c.inZoneH then
        def._inZoneHSet = def._inZoneHSet or (function()
            local s = {}; for _, z in ipairs(c.inZoneH) do s[z] = true end; return s
        end)()
        local okZone = (p.zone and def._inZoneHSet[ns.Util.HashString(p.zone)])
                    or (p.subZone and def._inZoneHSet[ns.Util.HashString(p.subZone)])
        if not okZone then return false end
    end

    -- The kill must happen in one of these zones (zone or subzone text).
    -- Needed when different creatures share a name (e.g. Princess the RFK boss
    -- vs. Princess the Elwynn pig).
    if c.inZone then
        def._inZoneSet = def._inZoneSet or (function()
            local s = {}; for _, z in ipairs(c.inZone) do s[z] = true end; return s
        end)()
        local okZone = (p.zone and def._inZoneSet[p.zone])
                    or (p.subZone and def._inZoneSet[p.subZone])
        if not okZone then return false end
    end

    -- The kill is only valid if certain adds were NOT recently slain
    -- (e.g. Princess without her bodyguards). Adds may be listed by NPC ID
    -- (withoutKilling) or by name (withoutKillingNames).
    if c.withoutKilling then
        for _, addID in ipairs(c.withoutKilling) do
            if ns.RecentKill and ns.RecentKill(addID) then return false end
        end
    end
    if c.withoutKillingNames then
        for _, addName in ipairs(c.withoutKillingNames) do
            if ns.RecentKill and ns.RecentKill("n:" .. addName) then return false end
        end
    end

    -- Fully qualified: NOW it's safe to unseal (the COMPLETED callback then
    -- records def._sealK for the discovery broadcast).
    if sealKey then ns.RevealHidden(def, sealKey) end
    return true
end

Engine:RegisterTrigger("KILL", function(def, p)
    return KillQualifies(def, p)
end)

----------------------------------------------------------------------
-- LEVEL: the player reached a level.
-- payload: { level }
----------------------------------------------------------------------
Engine:RegisterTrigger("LEVEL", function(def, p)
    local c = def.conditions
    if (p.level or 0) < (c.level or 60) then return false end
    -- Hardcore "deathless" gate. Two failsafes so this can never falsely fire:
    --   * never on the login/initial scan (p.initial) - only on a real ding,
    --   * only if the addon has watched since level 1 and no death has occurred.
    if c.noDeaths then
        if p.initial then return false end
        if not ns.DB:DeathlessEligible() then return false end
    end
    return true
end)

----------------------------------------------------------------------
-- TIMED_LEVEL: reach a level within a /played time budget (speed-leveling).
-- payload: { level, played }  where `played` is total seconds /played.
-- Uses real /played time, so it's honest regardless of when the addon was
-- installed - and it simply can't fire for levels you dinged before install
-- (no ding = no check), which is the correct behaviour.
----------------------------------------------------------------------
Engine:RegisterTrigger("TIMED_LEVEL", function(def, p)
    local c = def.conditions
    if (p.level or 0) < (c.level or 60) then return false end
    if not p.played then return false end
    return p.played <= (c.maxMinutes or 0) * 60
end)

----------------------------------------------------------------------
-- EXPLORE: a zone/subzone became current.
-- payload: { zone, subZone, minimapZone }
----------------------------------------------------------------------
Engine:RegisterTrigger("EXPLORE", function(def, p)
    -- Sealed zone matching (hidden secrets): candidates ship only as hashes;
    -- the matching zone name itself unwraps the master key and reveals the def.
    if def.conditions.matchers then
        for _, name in ipairs({ p.subZone, p.zone, p.minimapZone }) do
            if name and name ~= "" then
                local hash = ns.Util.HashString(name)
                for _, m in ipairs(def.conditions.matchers) do
                    if m.h == hash then
                        ns.RevealHidden(def, ns.Util.SealXor(m.w, name))
                        return true
                    end
                end
            end
        end
        return false
    end

    local zones = def.conditions.zones
    if not zones then return false end
    def._zoneSet = def._zoneSet or NumberSet(zones)  -- string keys work fine

    local matched
    for _, name in ipairs({ p.subZone, p.zone, p.minimapZone }) do
        if name and name ~= "" and def._zoneSet[name] then
            matched = name
            break
        end
    end
    if not matched then return false end

    if def.progressType == ns.PROGRESS.STAGED then
        return matched      -- stage key == zone name
    end
    return true
end)

----------------------------------------------------------------------
-- REP: a reputation standing changed.
-- payload: { factionName, factionID, standingID }
-- Modeled as PROGRESS: value = current standing id, target = required id.
----------------------------------------------------------------------
Engine:RegisterTrigger("REP", function(def, p)
    local c = def.conditions
    local match = (c.faction and p.factionName == c.faction)
               or (c.factionID and p.factionID == c.factionID)
    if not match then return false end
    return p.standingID     -- numeric -> PROGRESS
end)

----------------------------------------------------------------------
-- QUEST: a quest was turned in.
-- payload: { questID, playerLevel }
----------------------------------------------------------------------
local function QuestMatches(c, questID)
    if c.questID then return questID == c.questID end
    if c.questIDs then
        c._set = c._set or NumberSet(c.questIDs)
        return c._set[questID] == true
    end
    return false
end

Engine:RegisterTrigger("QUEST", function(def, p)
    local c = def.conditions

    if def.progressType == ns.PROGRESS.STAGED then
        def._questSet = def._questSet or (function()
            local keys = {}
            for _, s in ipairs(def.stages) do keys[#keys + 1] = s.key end
            return StringSet(keys)
        end)()
        local key = tostring(p.questID)
        if def._questSet[key] then return key end
        return false
    end

    if not QuestMatches(c, p.questID) then return false end
    if c.maxPlayerLevel and (p.playerLevel or 0) > c.maxPlayerLevel then return false end
    return true
end)

----------------------------------------------------------------------
-- SKILL: a profession/secondary skill rank changed.
-- payload: { skillName, skillRank }
-- PROGRESS: value = current rank, target = required rank.
----------------------------------------------------------------------
Engine:RegisterTrigger("SKILL", function(def, p)
    if p.skillName ~= def.conditions.skill then return false end
    return p.skillRank
end)

----------------------------------------------------------------------
-- KILLSTREAK: many kills inside a short window (Leeroy-style feats).
-- payload: { count } = kills in the rolling window maintained by Events.
----------------------------------------------------------------------
Engine:RegisterTrigger("KILLSTREAK", function(def, p)
    return (p.count or 0) >= (def.conditions.count or 5)
end)

----------------------------------------------------------------------
-- POINTS: total achievement points crossed a threshold. Dispatched by the
-- engine after every completion.
-- payload: { points }
----------------------------------------------------------------------
Engine:RegisterTrigger("POINTS", function(def, p)
    return (p.points or 0) >= (def.conditions.points or 0)
end)

----------------------------------------------------------------------
-- PVPKILL: the player/group landed a killing blow on an enemy player.
-- payload: { victimName }
----------------------------------------------------------------------
Engine:RegisterTrigger("PVPKILL", function(def, p)
    return true   -- boolean completes, counters increment
end)

----------------------------------------------------------------------
-- CREATOR: matches the addon author's Battle.net account (hash of the
-- battletag, so the tag itself never ships in code). Covers every character
-- on that account automatically.
----------------------------------------------------------------------
Engine:RegisterTrigger("CREATOR", function(def, p)
    if not BNGetInfo then return false end
    local _, battleTag = BNGetInfo()
    if not battleTag then return false end
    return ns.Util.HashString(battleTag) == ns.CREATOR_HASH
end)

----------------------------------------------------------------------
-- META: completed when all of def.requires are complete. The engine only
-- dispatches META for a def once DependenciesMet() is already true, so we
-- simply confirm the hit.
----------------------------------------------------------------------
Engine:RegisterTrigger("META", function(def, p)
    return true
end)

----------------------------------------------------------------------
-- Hidden-secret bookkeeping. Registered HERE (before the UI modules load)
-- so a sealed achievement is revealed before the toast renders it, and the
-- earner is recorded as a candidate first-discoverer.
----------------------------------------------------------------------
Engine:RegisterCallback("COMPLETED", function(id, def)
    if not def.hidden then return end
    if def.sealed then ns.TryRevealHidden(def, def._sealK) end
    ns.DB:RecordDiscovery(id, ns.Util.PlayerKey(), time(), def._sealK)
end)
