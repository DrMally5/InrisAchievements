--[[--------------------------------------------------------------------------
    Inri's Achievements! - Database / SavedVariables

    Owns the on-disk schema and is the ONLY module that reads or writes the
    saved variables tables. Everything else goes through these accessors so the
    storage layout can change without touching the engine or UI.

    Two saved tables (declared in the .toc):
      InrisAchievementsCharDB  - this character's progress + identity
      InrisAchievementsDB      - account-wide settings + networked roster cache

    Definitions live in code (ns.Achievements); only *progress* is persisted.
    Account-wide achievements can later be layered on by adding an account
    progress table here without disturbing the per-character one.
----------------------------------------------------------------------------]]

local _, ns = ...
local Util = ns.Util

local DB = {}
ns.DB = DB

-- Schema version for future migrations.
local SCHEMA = 1

----------------------------------------------------------------------
-- Defaults
----------------------------------------------------------------------
local function CharDefaults()
    return {
        schema   = SCHEMA,
        meta     = {},
        points   = 0,
        count    = 0,        -- number of completed achievements
        deaths   = 0,        -- deaths observed since the addon was installed
        everDied = false,    -- has this character EVER died while tracked?
        progress = {},       -- [achID] = { c=bool, t=ts, v=number, stages={} }
        recent   = {},       -- array, newest first: { id=, t= }
        tracked  = {},       -- array of achIDs pinned to the objective tracker
        -- meta.firstSeenLevel is stamped on first login (see Init.lua) and gates
        -- the honesty of "deathless" feats.
    }
end

local function AccountDefaults()
    return {
        schema   = SCHEMA,
        settings = {
            toast      = true,
            toastSound = true,
            announce   = true,   -- print a chat line when an achievement is earned
            guildFlex  = true,   -- post Rare+/hidden earns to real guild chat
            muteGuildFlex = false,-- hide OTHERS' raw flex lines? off by default,
                                  -- so addon users also see the guild-chat line
                                  -- (with a clickable name)
            radar      = true,   -- alert when a needed rare/named mob is nearby
            screenshot = true,   -- auto-screenshot on Epic+ earns
            shareGuild = true,
            minimap    = { hide = false, angle = 215 },
        },
        roster   = {},       -- [Name-Realm] = networked summary cache
        alts     = {},       -- [Name-Realm] = your own characters' last snapshot
        discoveries = {},    -- [achID] = { name = "Name-Realm", t = ts }
                             -- earliest KNOWN earner of a hidden achievement
    }
end

-- Fill any missing keys in `t` from `defaults` (one level deep for nested
-- tables we care about). Keeps old saves forward-compatible.
local function ApplyDefaults(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = type(v) == "table" and Util.CopyShallow(v) or v
        elseif type(v) == "table" and type(t[k]) == "table" then
            for k2, v2 in pairs(v) do
                if t[k][k2] == nil then t[k][k2] = v2 end
            end
        end
    end
    return t
end

----------------------------------------------------------------------
-- Initialization (call once, after ADDON_LOADED for this addon)
----------------------------------------------------------------------
function DB:Initialize()
    InrisAchievementsCharDB = ApplyDefaults(InrisAchievementsCharDB or {}, CharDefaults())
    InrisAchievementsDB     = ApplyDefaults(InrisAchievementsDB or {}, AccountDefaults())

    self.char    = InrisAchievementsCharDB
    self.account = InrisAchievementsDB

    self:RefreshMeta()
end

-- Snapshot the player's identity. Cheap to call on login/level up.
function DB:RefreshMeta()
    local key, name, realm = Util.PlayerKey()
    local localizedClass, classToken = UnitClass("player")
    local m = self.char.meta
    m.key        = key
    m.name       = name
    m.realm      = realm
    m.class      = localizedClass
    m.classToken = classToken
    m.faction    = UnitFactionGroup("player")
    local raceLoc, raceToken = UnitRace("player")
    m.race       = raceLoc
    m.raceToken  = raceToken   -- e.g. "Dwarf", "NightElf" - gates def.race
    m.level      = UnitLevel("player")
    m.version    = ns.VERSION
    m.lastUpdate = time()
end

----------------------------------------------------------------------
-- Settings
----------------------------------------------------------------------
function DB:Settings()
    return self.account.settings
end

----------------------------------------------------------------------
-- Progress accessors
----------------------------------------------------------------------
function DB:GetProgress(id)
    local p = self.char.progress[id]
    if not p then
        p = { c = false, v = 0, stages = {} }
        self.char.progress[id] = p
    end
    return p
end

function DB:IsCompleted(id)
    local p = self.char.progress[id]
    return p ~= nil and p.c == true
end

function DB:GetValue(id)
    local p = self.char.progress[id]
    return p and p.v or 0
end

function DB:GetCompletedTime(id)
    local p = self.char.progress[id]
    return p and p.t or nil
end

-- Mark an achievement complete. Returns true only the first time so callers
-- can fire the toast / award points exactly once. Points are recomputed from
-- the definition so the stored total can never drift from reality.
function DB:Complete(id)
    if self:IsCompleted(id) then return false end
    local def = ns.GetAchievement(id)
    if not def then return false end

    local p = self:GetProgress(id)
    p.c = true
    p.t = time()

    self.char.points = (self.char.points or 0) + Util.RarityPoints(def.rarity)
    self.char.count  = (self.char.count or 0) + 1

    -- Push onto the recent list (newest first, capped).
    table.insert(self.char.recent, 1, { id = id, t = p.t })
    while #self.char.recent > ns.MAX_RECENT do
        table.remove(self.char.recent)
    end

    return true
end

-- Reverse a completion (used for re-testing). Refunds points, removes it from
-- recents, and clears it as the active title if applicable. Returns true if a
-- completion was actually undone.
function DB:Uncomplete(id)
    local p = self.char.progress[id]
    if not p or not p.c then return false end
    local def = ns.GetAchievement(id)
    if def then
        self.char.points = math.max(0, (self.char.points or 0) - Util.RarityPoints(def.rarity))
    end
    self.char.count = math.max(0, (self.char.count or 0) - 1)
    for i = #self.char.recent, 1, -1 do
        if self.char.recent[i].id == id then table.remove(self.char.recent, i) end
    end
    self.char.progress[id] = nil
    if self.char.activeTitle == id then self.char.activeTitle = nil end
    return true
end

-- Set the working value of a COUNTER/PROGRESS achievement, clamped to target.
-- Returns (changed, nowComplete).
function DB:SetValue(id, value)
    local def = ns.GetAchievement(id)
    if not def then return false, false end
    local target = def.target or 1
    if value > target then value = target end

    local p = self:GetProgress(id)
    if p.v == value then return false, false end
    p.v = value

    if value >= target and not p.c then
        return true, true
    end
    return true, false
end

-- Mark one stage of a STAGED achievement done. Returns (changed, allDone).
function DB:SetStage(id, stageKey)
    local def = ns.GetAchievement(id)
    if not def or not def.stages then return false, false end

    local p = self:GetProgress(id)
    if p.stages[stageKey] then return false, false end
    p.stages[stageKey] = true

    for _, stage in ipairs(def.stages) do
        if not p.stages[stage.key] then
            return true, false
        end
    end
    return true, true
end

-- Number of completed stages, for progress bars on STAGED achievements.
function DB:CountStages(id)
    local p = self.char.progress[id]
    if not p or not p.stages then return 0 end
    local n = 0
    for _ in pairs(p.stages) do n = n + 1 end
    return n
end

----------------------------------------------------------------------
-- Totals
----------------------------------------------------------------------
function DB:GetDeaths() return self.char.deaths or 0 end
function DB:AddDeath()
    self.char.deaths = (self.char.deaths or 0) + 1
    self.char.everDied = true   -- permanent: a death can never be "un-died"
end

-- Deathless feats are only honest if the addon watched from level 1 and the
-- character has never died while tracked. If installed later, those feats are
-- unverifiable and must never auto-complete.
function DB:DeathlessEligible()
    return (self.char.meta.firstSeenLevel or 99) <= 1 and not self.char.everDied
end

-- Void any deathless feats that were granted before this failsafe existed (or
-- that were falsely granted because the addon was installed past level 1).
function DB:ValidateDeathless()
    if (self.char.meta.firstSeenLevel or 99) <= 1 then return end
    for _, def in ipairs(ns.Achievements) do
        if def.conditions and def.conditions.noDeaths and self:IsCompleted(def.id) then
            self:Uncomplete(def.id)
        end
    end
end

-- Active (displayed) title, stored as the granting achievement's id.
function DB:GetActiveTitleID()  return self.char.activeTitle end
function DB:SetActiveTitleID(id) self.char.activeTitle = id end

function DB:GetPoints()  return self.char.points or 0 end
function DB:GetCount()   return self.char.count or 0 end
function DB:GetRecent()  return self.char.recent end
function DB:GetMeta()    return self.char.meta end

-- Highest rarity the player has actually earned (for profiles / sharing).
function DB:GetHighestRarity()
    local best = 0
    for id, p in pairs(self.char.progress) do
        if p.c then
            local def = ns.GetAchievement(id)
            if def and def.rarity > best then best = def.rarity end
        end
    end
    return best
end

-- Sorted list of completed IDs (used by the network FULL dump).
function DB:GetCompletedIDs()
    local ids = {}
    for id, p in pairs(self.char.progress) do
        if p.c then ids[#ids + 1] = id end
    end
    return ids
end

----------------------------------------------------------------------
-- Maintenance
----------------------------------------------------------------------
function DB:WipeCharacter()
    InrisAchievementsCharDB = CharDefaults()
    self.char = InrisAchievementsCharDB
    self:RefreshMeta()
end

-- Drop progress for achievements that no longer exist (e.g. removed test/dummy
-- achievements) and recompute points/count from what's actually defined, so the
-- saved totals can never drift after a definition is deleted.
function DB:Prune()
    local points, count = 0, 0
    for id, p in pairs(self.char.progress) do
        local def = ns.GetAchievement(id)
        if not def then
            self.char.progress[id] = nil
        elseif p.c then
            points = points + Util.RarityPoints(def.rarity)
            count = count + 1
        end
    end
    self.char.points = points
    self.char.count = count

    for i = #self.char.recent, 1, -1 do
        if not ns.GetAchievement(self.char.recent[i].id) then
            table.remove(self.char.recent, i)
        end
    end

    -- Migrate the old creator achievement's title to the standalone one so a
    -- creator who had it equipped keeps wearing it.
    if self.char.activeTitle == "hidden_creator" then
        self.char.activeTitle = ns.CREATOR_TITLE.id
    end
    -- Clear a stored title whose granting achievement no longer exists (but
    -- never the synthetic creator title, which has no achievement).
    if self.char.activeTitle and self.char.activeTitle ~= ns.CREATOR_TITLE.id
       and not ns.GetAchievement(self.char.activeTitle) then
        self.char.activeTitle = nil
    end

    -- Account-level: drop discovery records for achievements that no longer
    -- exist (e.g. removed test achievements).
    for id in pairs(self.account.discoveries) do
        if not ns.GetAchievement(id) then
            self.account.discoveries[id] = nil
        end
    end

    -- Drop tracked entries for removed achievements or ones already done.
    for i = #self.char.tracked, 1, -1 do
        local id = self.char.tracked[i]
        if not ns.GetAchievement(id) or self:IsCompleted(id) then
            table.remove(self.char.tracked, i)
        end
    end

    -- Scrub saved-variable keys from removed features.
    self.char.duels = nil
    self.account.firstsSeen = nil
end

----------------------------------------------------------------------
-- Alt snapshots (for the account-wide leaderboard) and tracked achievements
----------------------------------------------------------------------
function DB:SnapshotAlt()
    local m = self.char.meta
    if not m.key then return end
    self.account.alts[m.key] = {
        name = m.name, classToken = m.classToken, level = m.level,
        points = self:GetPoints(), count = self:GetCount(), t = time(),
    }
end

function DB:GetAlts() return self.account.alts end

function DB:GetTracked() return self.char.tracked end

function DB:IsTracked(id)
    for _, t in ipairs(self.char.tracked) do
        if t == id then return true end
    end
    return false
end

-- Toggle tracking; capped at 5. Returns "added" | "removed" | "full".
function DB:ToggleTracked(id)
    for i, t in ipairs(self.char.tracked) do
        if t == id then table.remove(self.char.tracked, i); return "removed" end
    end
    if #self.char.tracked >= 5 then return "full" end
    table.insert(self.char.tracked, id)
    return "added"
end

----------------------------------------------------------------------
-- Hidden-achievement discoveries. A hidden achievement stays masked until
-- SOMEONE known has earned it - you, or any addon user whose "earned"
-- broadcast we heard. We keep the earliest discovery we know of. This is
-- gossip-based, not an authoritative server-first record.
----------------------------------------------------------------------
function DB:GetDiscovery(id)
    return self.account.discoveries[id]
end

-- Returns true if this became the new earliest-known discovery. `k` is the
-- seal key that unmasks a sealed hidden achievement; it is kept even when the
-- discoverer credit itself is not new (so late-heard keys still unseal).
function DB:RecordDiscovery(id, name, t, k)
    t = t or time()
    local cur = self.account.discoveries[id]
    if cur and (cur.t or 0) <= t then
        if k and not cur.k then cur.k = k end
        return false
    end
    self.account.discoveries[id] = { name = name, t = t, k = k or (cur and cur.k) }
    if ns.UI then ns.UI:Refresh() end
    return true
end

----------------------------------------------------------------------
-- Creator-account hygiene: the author mass-earned everything before release,
-- which would have "discovered" every hidden achievement at once. To keep the
-- community's discovery race pure, the creator's account sheds ALL hidden
-- completions at login (refunded) and drops any of its own hidden-discovery
-- credits. Runs only when the account's battletag hash matches CREATOR_HASH.
----------------------------------------------------------------------
function DB:CreatorHiddenScrub()
    local own = {}
    if self.char.meta.key then own[self.char.meta.key] = true end
    for key in pairs(self.account.alts or {}) do own[key] = true end

    for _, def in ipairs(ns.Achievements) do
        if def.hidden then
            if self:IsCompleted(def.id) then
                self:Uncomplete(def.id)
            end
            local d = self.account.discoveries[def.id]
            if d and d.name and own[d.name] then
                self.account.discoveries[def.id] = nil
            end
        end
    end
    if ns.UI then ns.UI:Refresh() end
end

----------------------------------------------------------------------
-- Roster cache (populated by Networking\Comm.lua)
----------------------------------------------------------------------
function DB:GetRoster()             return self.account.roster end
function DB:GetRosterEntry(key)     return self.account.roster[key] end

function DB:SetRosterEntry(key, entry)
    self.account.roster[key] = entry
end
