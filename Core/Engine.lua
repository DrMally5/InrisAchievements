--[[--------------------------------------------------------------------------
    Inri's Achievements! - Engine

    The data-driven core. Definitions register themselves here; game events are
    funnelled in as "triggers"; the engine evaluates which achievements the
    event affects and updates persisted progress, awarding completion exactly
    once.

    Design goals:
      * Adding an achievement only requires a definition file - never a change
        here. New BEHAVIOUR (a brand-new way to track progress) means adding a
        trigger evaluator in Triggers.lua; the engine itself stays untouched.
      * Events are routed via a trigger index so a kill only wakes the handful
        of kill achievements, not all ~400.
----------------------------------------------------------------------------]]

local _, ns = ...
local Util = ns.Util

local Engine = {}
ns.Engine = Engine

----------------------------------------------------------------------
-- Registries
----------------------------------------------------------------------
ns.Achievements   = {}          -- array, registration order
ns.AchievementByID = {}         -- [id] = def
ns.Categories     = {}          -- array of category defs
ns.CategoryByKey  = {}          -- [key] = category def

local triggerIndex = {}         -- [triggerType] = { def, def, ... }
local evaluators   = {}         -- [triggerType] = function(def, payload) -> result
local callbacks    = {}         -- [event] = { fn, fn, ... }

----------------------------------------------------------------------
-- Public lookups
----------------------------------------------------------------------
function ns.GetAchievement(id)
    return ns.AchievementByID[id]
end

function ns.GetCategory(key)
    return ns.CategoryByKey[key]
end

----------------------------------------------------------------------
-- Category registration (called from Definitions\Categories.lua)
----------------------------------------------------------------------
function ns.RegisterCategory(def)
    assert(def and def.key, "category needs a key")
    if ns.CategoryByKey[def.key] then return end
    def.order = def.order or (#ns.Categories + 1)
    ns.Categories[#ns.Categories + 1] = def
    ns.CategoryByKey[def.key] = def
end

----------------------------------------------------------------------
-- Achievement registration (called from every Definitions\Ach_*.lua)
--
-- Required fields: id, name, category, rarity, trigger
-- Optional: description, subcategory, icon, progressType, target, stages,
--           requires (deps), hidden, conditions (per-trigger criteria)
----------------------------------------------------------------------
-- Consolidated category map: definitions keep their original (granular)
-- category, but the UI groups them into fewer tabs. The original value is
-- preserved as the subcategory so nothing loses its grouping.
local CATEGORY_MERGE = {
    LEGENDS      = "NAMED",     -- iconic kills join the "Hunts" tab
    RARES        = "NAMED",
    ELITE_QUESTS = "NAMED",
    SPEEDRUN     = "DUNGEONS",  -- speed runs become a Dungeons sub-section
}
local SUBCAT_OVERRIDE = {
    SPEEDRUN = "Speed Runs",    -- group all speed clears together
}

function ns.RegisterAchievement(def)
    assert(def.id, "achievement missing id")
    assert(not ns.AchievementByID[def.id], "duplicate achievement id: " .. tostring(def.id))
    assert(def.trigger, "achievement " .. def.id .. " missing trigger")

    -- Fold merged categories into their consolidated tab.
    local orig = def.category
    if CATEGORY_MERGE[orig] then
        def.category = CATEGORY_MERGE[orig]
        def.subcategory = SUBCAT_OVERRIDE[orig] or def.subcategory
    end

    -- Sensible defaults so definitions stay terse.
    def.rarity       = def.rarity or ns.RARITY.COMMON
    def.icon         = def.icon or ns.DEFAULT_ICON

    -- Guard against icon paths that don't exist in this client (they would
    -- render as blank squares): fall back to the question mark and remember
    -- the bad path so /ia icons can report it.
    if GetFileIDFromPath and def.icon ~= ns.DEFAULT_ICON
       and not GetFileIDFromPath(def.icon) then
        def.iconMissing = def.icon
        def.icon = ns.DEFAULT_ICON
    end
    def.points       = Util.RarityPoints(def.rarity)
    def.progressType = def.progressType or ns.PROGRESS.BOOLEAN
    def.conditions   = def.conditions or {}

    -- Infer a target for bar-style achievements when not given explicitly.
    if def.progressType == ns.PROGRESS.STAGED and def.stages then
        def.target = #def.stages
    elseif def.progressType ~= ns.PROGRESS.BOOLEAN then
        def.target = def.target or 1
    end

    ns.Achievements[#ns.Achievements + 1] = def
    ns.AchievementByID[def.id] = def

    local list = triggerIndex[def.trigger]
    if not list then list = {}; triggerIndex[def.trigger] = list end
    list[#list + 1] = def
end

----------------------------------------------------------------------
-- Trigger evaluators (registered in Triggers.lua)
----------------------------------------------------------------------
function Engine:RegisterTrigger(triggerType, fn)
    evaluators[triggerType] = fn
end

----------------------------------------------------------------------
-- Lifecycle callbacks for the UI / toast / network layers.
-- Events: "COMPLETED" (id, def), "PROGRESS" (id, def, value, target)
----------------------------------------------------------------------
function Engine:RegisterCallback(event, fn)
    local list = callbacks[event]
    if not list then list = {}; callbacks[event] = list end
    list[#list + 1] = fn
end

local function Fire(event, ...)
    local list = callbacks[event]
    if not list then return end
    for _, fn in ipairs(list) do
        -- Guard each callback so one bad listener can't break the chain.
        local ok, err = pcall(fn, ...)
        if not ok then
            Util.Print("|cffff4444callback error:|r", err)
        end
    end
end

----------------------------------------------------------------------
-- Dependency check
----------------------------------------------------------------------
local function DependenciesMet(def)
    if not def.requires then return true end
    for _, reqID in ipairs(def.requires) do
        if not ns.DB:IsCompleted(reqID) then return false end
    end
    return true
end

----------------------------------------------------------------------
-- Completion
----------------------------------------------------------------------
function Engine:CompleteAchievement(id)
    local def = ns.GetAchievement(id)
    if not def then return end

    if ns.DB:Complete(id) then
        -- Hidden achievements: record ourselves as the (earliest known) finder.
        if def.hidden then
            ns.DB:RecordDiscovery(id, (Util.PlayerKey()), time())
        end
        Fire("COMPLETED", id, def)
        -- A freshly-earned achievement may satisfy a meta achievement, so
        -- re-run the dependency-based trigger. Guarded against recursion by
        -- the "already completed" check inside Complete().
        self:Dispatch("META", { id = id })
        -- It may also push the player past a points threshold.
        self:Dispatch("POINTS", { points = ns.DB:GetPoints() })
    end
end

----------------------------------------------------------------------
-- Apply an evaluator result according to the achievement's progress type.
----------------------------------------------------------------------
local function ApplyResult(def, result)
    if result == nil or result == false then return end
    local pt = def.progressType

    if pt == ns.PROGRESS.BOOLEAN then
        if result then Engine:CompleteAchievement(def.id) end

    elseif pt == ns.PROGRESS.COUNTER then
        local inc = (type(result) == "number") and result or 1
        if inc <= 0 then return end
        local cur = ns.DB:GetValue(def.id)
        local changed, done = ns.DB:SetValue(def.id, cur + inc)
        if changed then Fire("PROGRESS", def.id, def, ns.DB:GetValue(def.id), def.target) end
        if done then Engine:CompleteAchievement(def.id) end

    elseif pt == ns.PROGRESS.PROGRESS then
        if type(result) ~= "number" then return end
        local changed, done = ns.DB:SetValue(def.id, result)
        if changed then Fire("PROGRESS", def.id, def, ns.DB:GetValue(def.id), def.target) end
        if done then Engine:CompleteAchievement(def.id) end

    elseif pt == ns.PROGRESS.STAGED then
        if type(result) ~= "string" then return end
        local changed, allDone = ns.DB:SetStage(def.id, result)
        if changed then Fire("PROGRESS", def.id, def, ns.DB:CountStages(def.id), def.target) end
        if allDone then Engine:CompleteAchievement(def.id) end
    end
end

----------------------------------------------------------------------
-- Dispatch a game event to every achievement watching this trigger type.
-- Called by Core\Events.lua (and recursively for META).
----------------------------------------------------------------------
function Engine:Dispatch(triggerType, payload)
    local list = triggerIndex[triggerType]
    if not list then return end

    local eval = evaluators[triggerType]
    if not eval then return end

    local meta = ns.DB:GetMeta()
    local myClass, myRace = meta.classToken, meta.raceToken

    for _, def in ipairs(list) do
        -- Class/race-restricted achievements only progress for that class/race.
        local classOK = (not def.class) or (def.class == myClass)
        local raceOK  = (not def.race) or (def.race == myRace)
        if classOK and raceOK and not ns.DB:IsCompleted(def.id) and DependenciesMet(def) then
            local ok, result = pcall(eval, def, payload)
            if ok then
                ApplyResult(def, result)
            else
                Util.Print("|cffff4444eval error|r [" .. tostring(def.id) .. "]:", result)
            end
        end
    end
end

----------------------------------------------------------------------
-- Statistics helpers (used by the UI summary panes)
----------------------------------------------------------------------
function Engine:GetStats()
    local total      = #ns.Achievements
    local completed  = ns.DB:GetCount()
    local maxPoints  = 0
    for _, def in ipairs(ns.Achievements) do
        maxPoints = maxPoints + def.points
    end
    return {
        total      = total,
        completed  = completed,
        points     = ns.DB:GetPoints(),
        maxPoints  = maxPoints,
        percent    = total > 0 and (completed / total * 100) or 0,
    }
end
