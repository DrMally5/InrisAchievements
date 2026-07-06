--[[--------------------------------------------------------------------------
    Inri's Achievements! - Game Event Wiring

    Translates raw WoW events into engine triggers. This is the only file that
    knows about Blizzard event names; everything downstream speaks in triggers.

    Kill handling is the subtle part:
      * PARTY_KILL  - a confirmed kill by the player or group. Drives counters,
                      classification, level-diff, solo and kill-streak feats.
      * UNIT_DIED   - any nearby creature death. Used ONLY to credit specific
                      named/boss achievements (so raid kills where someone else
                      lands the blow still count). Broad/counter achievements
                      ignore UNIT_DIED to avoid inflation - see KillQualifies.
----------------------------------------------------------------------------]]

local _, ns = ...
local Util   = ns.Util
local Engine = ns.Engine

local Events = {}
ns.Events = Events

----------------------------------------------------------------------
-- Unit info cache: remember level/classification of units we've seen so the
-- combat log (which lacks them) can be enriched at time of death.
----------------------------------------------------------------------
local unitCache = {}        -- [guid] = { level, classification, name, t }
local CACHE_TTL = 300       -- seconds

local function CacheUnit(unit)
    if not UnitExists(unit) or UnitIsPlayer(unit) then return end
    local guid = UnitGUID(unit)
    if not guid then return end
    unitCache[guid] = {
        level          = UnitLevel(unit),
        classification = UnitClassification(unit),
        name           = UnitName(unit),
        -- Tap state: true if this mob is tapped by someone else (we'd get no
        -- loot/XP). Sampled whenever we see the unit; used to reject kill
        -- credit for mobs we merely witnessed dying. Missing API -> treat as
        -- ours (falls back to the damage check below).
        tapDenied      = UnitIsTapDenied and UnitIsTapDenied(unit) or false,
        t              = GetTime(),
    }
end

----------------------------------------------------------------------
-- Kill-credit fairness ledger: which creatures WE (player, pet, or a group
-- member) actually dealt damage to. UNIT_DIED fires for every nearby death,
-- so without this a mob someone else killed - that we merely poked or stood
-- near - would grant its achievement.
----------------------------------------------------------------------
local damagedByUs = {}      -- [guid] = GetTime()
local DAMAGE_TTL  = 60

local groupGUIDs = {}       -- GUIDs of group members and their pets
local function RefreshGroupGUIDs()
    wipe(groupGUIDs)
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, (GetNumGroupMembers() or 0) do
        local g  = UnitGUID(prefix .. i);          if g  then groupGUIDs[g]  = true end
        local pg = UnitGUID(prefix .. i .. "pet"); if pg then groupGUIDs[pg] = true end
    end
end

local function WeDamaged(srcGUID)
    if not srcGUID then return false end
    return srcGUID == UnitGUID("player")
        or srcGUID == UnitGUID("pet")
        or groupGUIDs[srcGUID] == true
end

local DAMAGE_SUB = {
    SWING_DAMAGE = true, RANGE_DAMAGE = true, SPELL_DAMAGE = true,
    SPELL_PERIODIC_DAMAGE = true, SPELL_BUILDING_DAMAGE = true,
    DAMAGE_SHIELD = true, DAMAGE_SPLIT = true,
}

local HEAL_SUB = { SPELL_HEAL = true, SPELL_PERIODIC_HEAL = true }

----------------------------------------------------------------------
-- Outside-help ledger: "solo" and David-and-Goliath feats are only honest if
-- no OTHER player helped - including ungrouped ones (an out-of-group friend
-- healing you through "solo Hogger" is not solo). The combat log flags every
-- source, so we notice when an outside player (or their pet) damages our
-- target or heals us mid-fight.
----------------------------------------------------------------------
local outsideDamaged = {}    -- [mobGUID] = GetTime() of last outsider damage
local outsideHealT   = 0     -- last time an outsider healed us in combat
local OUTSIDE_TTL    = 60    -- how long outsider damage taints a mob
local HEAL_TAINT     = 20    -- how long an outside heal taints our kills

local AFFIL_OUTSIDER = COMBATLOG_OBJECT_AFFILIATION_OUTSIDER or 0x00000008
local CONTROL_PLAYER = COMBATLOG_OBJECT_CONTROL_PLAYER or 0x00000100

local function OutsiderControlled(flags)
    return flags
        and bit.band(flags, AFFIL_OUTSIDER) ~= 0
        and bit.band(flags, CONTROL_PLAYER) ~= 0
end

local function OutsideHelp(mobGUID)
    local now = GetTime()
    if mobGUID and outsideDamaged[mobGUID] and (now - outsideDamaged[mobGUID]) <= OUTSIDE_TTL then
        return true
    end
    return (now - outsideHealT) <= HEAL_TAINT
end

-- Occasional prune so the caches can't grow without bound.
local function PruneCache()
    local now = GetTime()
    for guid, info in pairs(unitCache) do
        if now - info.t > CACHE_TTL then unitCache[guid] = nil end
    end
    for guid, t in pairs(damagedByUs) do
        if now - t > DAMAGE_TTL then damagedByUs[guid] = nil end
    end
    for guid, t in pairs(outsideDamaged) do
        if now - t > OUTSIDE_TTL then outsideDamaged[guid] = nil end
    end
end

----------------------------------------------------------------------
-- Recent-kill ledger (for "without killing the adds" conditions) and the
-- kill-streak window (for Leeroy-style feats).
----------------------------------------------------------------------
local recentKills = {}      -- [key] = GetTime()
local RECENT_TTL  = 12

function ns.RecentKill(key)
    local t = recentKills[key]
    return t ~= nil and (GetTime() - t) <= RECENT_TTL
end

local function RecordKill(npcID, name)
    local now = GetTime()
    if npcID then recentKills[npcID] = now end
    if name  then recentKills["n:" .. name] = now end
end

local killTimes = {}        -- timestamps of recent kills
local STREAK_WINDOW = 10

local function PushKillStreak()
    local now = GetTime()
    killTimes[#killTimes + 1] = now
    -- Drop anything outside the window from the front.
    local cutoff = now - STREAK_WINDOW
    local i = 1
    while killTimes[i] and killTimes[i] < cutoff do i = i + 1 end
    if i > 1 then
        for j = 1, #killTimes - i + 1 do killTimes[j] = killTimes[j + i - 1] end
        for j = #killTimes - i + 2, #killTimes do killTimes[j] = nil end
    end
    return #killTimes
end

----------------------------------------------------------------------
-- Group helpers
----------------------------------------------------------------------
local function GroupSizeAndMaxLevel()
    local size = GetNumGroupMembers() or 0
    local maxLevel = UnitLevel("player")
    if IsInRaid() then
        for i = 1, size do
            local lvl = UnitLevel("raid" .. i)
            if lvl and lvl > maxLevel then maxLevel = lvl end
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local lvl = UnitLevel(unit)
                if lvl and lvl > maxLevel then maxLevel = lvl end
            end
        end
    end
    return size, maxLevel
end

----------------------------------------------------------------------
-- Instance run timer (for speed-clear achievements). Starts when you enter a
-- dungeon/raid and is read as "seconds since entry" at the time of a kill.
----------------------------------------------------------------------
local instanceStart, inInstanceNow = nil, false

local function UpdateInstance()
    local inInstance, instanceType = IsInInstance()
    inInstance = inInstance and (instanceType == "party" or instanceType == "raid")
    if inInstance and not inInstanceNow then
        instanceStart = GetTime()   -- just zoned in: start the clock
    elseif not inInstance then
        instanceStart = nil
    end
    inInstanceNow = inInstance
end

local function InstanceRunTime()
    return instanceStart and (GetTime() - instanceStart) or nil
end

----------------------------------------------------------------------
-- Kill handling
----------------------------------------------------------------------
local function BuildKillPayload(destGUID, destName, source)
    local npcID = Util.NpcIDFromGUID(destGUID)
    local cached = unitCache[destGUID]
    local size, groupMax = GroupSizeAndMaxLevel()
    local zone = GetRealZoneText() or GetZoneText()
    return {
        source        = source,
        npcID         = npcID,
        mobName       = destName,
        mobLevel      = cached and cached.level,
        classification= cached and cached.classification,
        playerLevel   = UnitLevel("player"),
        groupSize     = size,
        groupMaxLevel = groupMax,
        zone          = zone,
        subZone       = GetSubZoneText(),
        runTime       = InstanceRunTime(),
        outsideHelp   = OutsideHelp(destGUID),
    }
end

local function OnPartyKill(destGUID, destName)
    local payload = BuildKillPayload(destGUID, destName, "PARTY_KILL")
    RecordKill(payload.npcID, destName)
    Engine:Dispatch("KILL", payload)

    local streak = PushKillStreak()
    Engine:Dispatch("KILLSTREAK", { count = streak })
end

local function OnUnitDied(destGUID, destName)
    -- Only meaningful for specific-target achievements; KillQualifies rejects
    -- broad ones when source == "UNIT_DIED".
    if not Util.NpcIDFromGUID(destGUID) then return end

    -- Fairness gate: UNIT_DIED fires for ANY nearby death. Credit it only if it
    -- was genuinely our kill - we (or our group) damaged it AND it wasn't
    -- tapped by someone else. A clean solo/group kill also arrives via
    -- PARTY_KILL (unconditional), so this path only rescues the cases where no
    -- killing blow reached us (contested world bosses, odd pet last-hits).
    local dmgT = damagedByUs[destGUID]
    if not dmgT or (GetTime() - dmgT) > DAMAGE_TTL then return end
    local cached = unitCache[destGUID]
    if not cached or cached.tapDenied then return end

    Engine:Dispatch("KILL", BuildKillPayload(destGUID, destName, "UNIT_DIED"))
end

local function OnCombatLog()
    local _, sub, _, srcGUID, _, srcFlags, _, destGUID, destName = CombatLogGetCurrentEventInfo()

    -- Record our own damage so UNIT_DIED can tell a real kill from a witnessed
    -- one, and outsider damage so solo feats stay honest. (Damage events far
    -- outnumber deaths, so this returns early.)
    if DAMAGE_SUB[sub] then
        if destGUID then
            if WeDamaged(srcGUID) then
                damagedByUs[destGUID] = GetTime()
            elseif OutsiderControlled(srcFlags) then
                outsideDamaged[destGUID] = GetTime()
            end
        end
        return
    end

    -- An outside player healing us (or our pet) mid-combat taints solo feats.
    if HEAL_SUB[sub] then
        if OutsiderControlled(srcFlags) and UnitAffectingCombat("player")
           and (destGUID == UnitGUID("player") or destGUID == UnitGUID("pet")) then
            outsideHealT = GetTime()
        end
        return
    end

    if sub == "PARTY_KILL" then
        -- Enemy players route to the PvP trigger, not the creature-kill path.
        if destGUID and destGUID:find("^Player%-") then
            Engine:Dispatch("PVPKILL", { victimName = destName })
            Engine:Dispatch("KILLSTREAK", { count = PushKillStreak() })
            return
        end
        OnPartyKill(destGUID, destName)
    elseif sub == "UNIT_DIED" then
        OnUnitDied(destGUID, destName)
    end
end

----------------------------------------------------------------------
-- Exploration
----------------------------------------------------------------------
local function OnZoneChanged()
    UpdateInstance()
    Engine:Dispatch("EXPLORE", {
        zone        = GetRealZoneText() or GetZoneText(),
        subZone     = GetSubZoneText(),
        minimapZone = GetMinimapZoneText(),
    })
end

----------------------------------------------------------------------
-- Reputation (scan all factions; cheap enough and robust)
----------------------------------------------------------------------
local function ScanFactions()
    local n = GetNumFactions()
    for i = 1, n do
        local name, _, standingID, _, _, _, _, _, isHeader, _, hasRep, _, _, factionID = GetFactionInfo(i)
        if name and (hasRep or not isHeader) and standingID then
            Engine:Dispatch("REP", {
                factionName = name,
                factionID   = factionID,
                standingID  = standingID,
            })
        end
    end
end

----------------------------------------------------------------------
-- Professions / skills
----------------------------------------------------------------------
local function ScanSkills()
    local n = GetNumSkillLines and GetNumSkillLines() or 0
    for i = 1, n do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if skillName and not isHeader and skillRank then
            Engine:Dispatch("SKILL", { skillName = skillName, skillRank = skillRank })
        end
    end
end

----------------------------------------------------------------------
-- Quests
----------------------------------------------------------------------
local function OnQuestTurnedIn(questID)
    if not questID then return end
    Engine:Dispatch("QUEST", { questID = questID, playerLevel = UnitLevel("player") })
end

----------------------------------------------------------------------
-- Items (legendary-weapon feats). Cheap: only ITEM-trigger achievements are
-- visited, and there are a handful.
----------------------------------------------------------------------
local function ScanItems()
    Engine:Dispatch("ITEM", {})
end

----------------------------------------------------------------------
-- /played speed-leveling. On a ding we ask the server for total played time
-- and feed it into TIMED_LEVEL. RequestTimePlayed() normally spams two yellow
-- chat lines, so we briefly suppress those.
----------------------------------------------------------------------
local pendingTimedLevel, suppressPlayed = false, false

local function PlayedFilter(_, _, msg)
    if suppressPlayed and msg and msg:find("[Tt]ime played") then
        return true   -- swallow the "time played" lines
    end
    return false
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", PlayedFilter)

local function OnTimePlayed(total)
    if pendingTimedLevel then
        Engine:Dispatch("TIMED_LEVEL", { level = UnitLevel("player"), played = total })
        pendingTimedLevel = false
    end
    C_Timer.After(0.2, function() suppressPlayed = false end)
end

----------------------------------------------------------------------
-- Level / death
----------------------------------------------------------------------
local function OnLevelUp(level)
    ns.DB:RefreshMeta()
    Engine:Dispatch("LEVEL", { level = level or UnitLevel("player") })
    if ns.Comm then ns.Comm:BroadcastSummary() end

    -- Kick off the /played lookup for speed-leveling achievements.
    pendingTimedLevel = true
    suppressPlayed = true
    RequestTimePlayed()
end

----------------------------------------------------------------------
-- One-time scan so conditions already met at install time complete, and so
-- progress bars start populated.
----------------------------------------------------------------------
function Events:InitialScan()
    -- Suppress toasts/announces for the catch-up scan so installing the addon
    -- (which retro-completes everything already true) doesn't flood chat.
    ns._suppressNotify = true
    Engine:Dispatch("LEVEL", { level = UnitLevel("player"), initial = true })
    OnZoneChanged()
    ScanFactions()
    ScanSkills()
    ScanItems()
    ns._suppressNotify = false

    -- Creator-account hygiene: delayed because Battle.net info isn't always
    -- available immediately at login. The author's account sheds any hidden
    -- completions/credits so the community discovery race stays pure; the
    -- "the Creator" title is offered separately via the title picker.
    C_Timer.After(5, function()
        if BNGetInfo then
            local _, tag = BNGetInfo()
            if tag and ns.CREATOR_HASHES[Util.HashString(tag)] then
                ns.DB:CreatorHiddenScrub()
                if ns.TitlesUI then ns.TitlesUI:Refresh() end
            end
        end
    end)
end

----------------------------------------------------------------------
-- Frame + registration
----------------------------------------------------------------------
local frame = CreateFrame("Frame")

-- Cache the unit for kill enrichment AND feed the Rare Radar.
local function SeeUnit(unit)
    CacheUnit(unit)
    if ns.Extras then ns.Extras:OnUnitSeen(unit) end
end

local handlers = {
    COMBAT_LOG_EVENT_UNFILTERED = OnCombatLog,
    PLAYER_TARGET_CHANGED       = function() SeeUnit("target") end,
    UPDATE_MOUSEOVER_UNIT       = function() SeeUnit("mouseover") end,
    NAME_PLATE_UNIT_ADDED       = function(unit) SeeUnit(unit) end,
    ZONE_CHANGED                = OnZoneChanged,
    ZONE_CHANGED_INDOORS        = OnZoneChanged,
    ZONE_CHANGED_NEW_AREA       = OnZoneChanged,
    PLAYER_ENTERING_WORLD       = function() UpdateInstance(); RefreshGroupGUIDs() end,
    GROUP_ROSTER_UPDATE         = function()
        RefreshGroupGUIDs()
        -- Introduce ourselves to a new group (throttled): this is how
        -- summaries and hidden-achievement discoveries hop between guilds.
        if IsInGroup() and ns.Comm then
            local now = GetTime()
            if (now - (ns.Comm._lastGroupHello or 0)) > 60 then
                ns.Comm._lastGroupHello = now
                C_Timer.After(2, function() ns.Comm:Hello() end)
            end
        end
    end,
    TIME_PLAYED_MSG             = function(total) OnTimePlayed(total) end,
    UPDATE_FACTION              = ScanFactions,
    SKILL_LINES_CHANGED         = ScanSkills,
    CHAT_MSG_SKILL              = ScanSkills,
    QUEST_TURNED_IN             = function(questID) OnQuestTurnedIn(questID) end,
    PLAYER_EQUIPMENT_CHANGED    = ScanItems,
    BAG_UPDATE_DELAYED          = ScanItems,
    PLAYER_LEVEL_UP             = function(level) OnLevelUp(level) end,
    -- Extras owns death handling (deathless knell fires BEFORE the death is
    -- recorded); falls back to plain bookkeeping if Extras is absent.
    PLAYER_DEAD                 = function()
        if ns.Extras then ns.Extras:OnPlayerDead() else ns.DB:AddDeath() end
    end,
}

function Events:Enable()
    for event in pairs(handlers) do
        pcall(function() frame:RegisterEvent(event) end)
    end
    frame:SetScript("OnEvent", function(_, event, ...)
        local h = handlers[event]
        if h then
            local ok, err = pcall(h, ...)
            if not ok then Util.Print("|cffff4444event error|r [" .. event .. "]:", err) end
        end
    end)

    RefreshGroupGUIDs()

    -- Light periodic cache prune.
    C_Timer.NewTicker(CACHE_TTL, PruneCache)
end
