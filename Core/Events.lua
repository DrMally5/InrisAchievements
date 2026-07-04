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
        t              = GetTime(),
    }
end

-- Occasional prune so the cache can't grow without bound.
local function PruneCache()
    local now = GetTime()
    for guid, info in pairs(unitCache) do
        if now - info.t > CACHE_TTL then unitCache[guid] = nil end
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
    Engine:Dispatch("KILL", BuildKillPayload(destGUID, destName, "UNIT_DIED"))
end

local function OnCombatLog()
    local _, sub, _, _, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
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
    ns._suppressNotify = false

    -- Creator check: delayed because Battle.net info isn't always available
    -- immediately at login; deliberately after the suppress window so the
    -- toast shows the first time it's earned.
    C_Timer.After(5, function()
        Engine:Dispatch("CREATOR", {})
        -- Creator-account hygiene: shed all hidden completions/credits except
        -- "Make This Addon" so the discovery race stays pure.
        if BNGetInfo then
            local _, tag = BNGetInfo()
            if tag and Util.HashString(tag) == ns.CREATOR_HASH then
                ns.DB:CreatorHiddenScrub()
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
    PLAYER_ENTERING_WORLD       = function() UpdateInstance() end,
    TIME_PLAYED_MSG             = function(total) OnTimePlayed(total) end,
    UPDATE_FACTION              = ScanFactions,
    SKILL_LINES_CHANGED         = ScanSkills,
    CHAT_MSG_SKILL              = ScanSkills,
    QUEST_TURNED_IN             = function(questID) OnQuestTurnedIn(questID) end,
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

    -- Light periodic cache prune.
    C_Timer.NewTicker(CACHE_TTL, PruneCache)
end
