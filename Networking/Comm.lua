--[[--------------------------------------------------------------------------
    Inri's Achievements! - Networking

    Lightweight peer-to-peer sync over WoW's addon channels. No external libs.

    Wire format:  <OP><US><field><US><field>...
      where <US> is the unit-separator (Util.FIELD_SEP).

    Opcodes (ns.OP):
      HELLO   - "I'm here", carries a summary; peers reply with their summary
      SUMMARY - points/count/version/class/faction/highest (roster cache)
      REQUEST - "send me your full list" (used by the inspect feature)
      PROFILE - guild + ordered recent IDs (inspect header)
      FULL    - chunked dump of all completed achievement IDs

    Bandwidth discipline: summaries are throttled, full dumps are only sent on
    explicit request (never broadcast), and lists are sorted+comma-packed.
----------------------------------------------------------------------------]]

local _, ns = ...
local Util = ns.Util
local OP   = ns.OP
local L    = ns.L

local Comm = {}
ns.Comm = Comm

local lastBroadcast = 0
local incoming = {}     -- [sender] = { chunks = {}, total = n, profile = {} }

----------------------------------------------------------------------
-- Low-level send
----------------------------------------------------------------------
local function RawSend(message, channel, target)
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end
    C_ChatInfo.SendAddonMessage(ns.COMM_PREFIX, message, channel, target)
end

function Comm:Send(op, fields, channel, target)
    RawSend(op .. Util.FIELD_SEP .. fields, channel, target)
end

-- Best channel for a passive broadcast given current group state.
local function BroadcastChannel()
    if IsInRaid() then return "RAID"
    elseif IsInGroup() then return "PARTY"
    elseif IsInGuild() and ns.DB:Settings().shareGuild then return "GUILD" end
    return nil
end

----------------------------------------------------------------------
-- Payload builders
----------------------------------------------------------------------
function Comm:SummaryPayload()
    local m = ns.DB:GetMeta()
    local title = ns.Titles and ns.Titles:GetActive()
    return Util.PackFields(
        ns.DB:GetPoints(),
        ns.DB:GetCount(),
        ns.VERSION_NUM,
        m.classToken or "",
        m.faction or "",
        ns.DB:GetHighestRarity(),
        title and title.text or "",
        title and title.rarity or 0
    )
end

----------------------------------------------------------------------
-- Public broadcast helpers
----------------------------------------------------------------------
function Comm:BroadcastSummary(force)
    local now = GetTime()
    if not force and (now - lastBroadcast) < ns.SYNC_THROTTLE then return end
    lastBroadcast = now
    local channel = BroadcastChannel()
    if channel then self:Send(OP.SUMMARY, self:SummaryPayload(), channel) end
end

function Comm:Hello()
    local channel = BroadcastChannel()
    if channel then self:Send(OP.HELLO, self:SummaryPayload(), channel) end
end

----------------------------------------------------------------------
-- Roster cache update from an incoming summary
----------------------------------------------------------------------
local function StoreSummary(sender, points, count, versionNum, classToken, faction, highest, titleText, titleRarity)
    local key = Util.NormalizeName(sender)
    local entry = ns.DB:GetRosterEntry(key) or {}
    entry.name         = sender
    entry.points       = tonumber(points) or 0
    entry.count        = tonumber(count) or 0
    entry.version      = tonumber(versionNum) or 0
    entry.classToken   = (classToken and classToken ~= "") and classToken or entry.classToken
    entry.faction      = (faction and faction ~= "") and faction or entry.faction
    entry.highestRarity= tonumber(highest) or 0
    -- Title may be empty (cleared) or absent (older client); store as given.
    entry.titleText    = (titleText and titleText ~= "") and titleText or nil
    entry.titleRarity  = tonumber(titleRarity) or 0
    entry.lastUpdate   = time()
    entry.hasAddon     = true
    ns.DB:SetRosterEntry(key, entry)

    -- One-time heads-up if someone is running a newer build than us.
    if entry.version > ns.VERSION_NUM and not Comm._versionWarned then
        Comm._versionWarned = true
        Util.Print("|cffffd100A newer version of Inri's Achievements! is available.|r")
    end

    return entry
end

----------------------------------------------------------------------
-- Inspect: ask another player for their profile + full list
----------------------------------------------------------------------
function Comm:RequestProfile(name)
    local key = Util.NormalizeName(name)
    incoming[key] = nil  -- reset any partial assembly
    self:Send(OP.REQUEST, "", "WHISPER", name)
end

-- Reply to a profile request: send PROFILE header, then chunked FULL dump.
function Comm:SendProfileTo(target)
    local guild = (GetGuildInfo("player")) or ""
    -- Ordered recent IDs (newest first) for the profile header.
    local recentIDs = {}
    for _, r in ipairs(ns.DB:GetRecent()) do
        recentIDs[#recentIDs + 1] = r.id
        if #recentIDs >= ns.MAX_RECENT_SHARE then break end
    end
    self:Send(OP.PROFILE, Util.PackFields(guild, table.concat(recentIDs, Util.LIST_SEP)),
              "WHISPER", target)

    -- Full completed list, chunked to stay under the addon-message size limit.
    local ids = ns.DB:GetCompletedIDs()
    table.sort(ids)
    local chunks, cur = {}, {}
    for _, id in ipairs(ids) do
        cur[#cur + 1] = id
        if #cur >= ns.COMM_CHUNK then chunks[#chunks + 1] = cur; cur = {} end
    end
    if #cur > 0 then chunks[#chunks + 1] = cur end
    local total = #chunks
    if total == 0 then
        self:Send(OP.FULL, Util.PackFields(1, 1, ""), "WHISPER", target)
        return
    end
    for i, chunk in ipairs(chunks) do
        self:Send(OP.FULL, Util.PackFields(i, total, table.concat(chunk, Util.LIST_SEP)),
                  "WHISPER", target)
    end
end

----------------------------------------------------------------------
-- Incoming message handling
----------------------------------------------------------------------
local function HandleHello(sender, rest)
    local p, c, v, cls, fac, hi, tt, tr = Util.UnpackFields(rest)
    local entry = StoreSummary(sender, p, c, v, cls, fac, hi, tt, tr)
    if ns.Inspect then ns.Inspect:OnSummary(Util.NormalizeName(sender), entry) end
    -- Reply privately with our summary so their roster learns about us too.
    Comm:Send(OP.SUMMARY, Comm:SummaryPayload(), "WHISPER", sender)
end

local function HandleSummary(sender, rest)
    local p, c, v, cls, fac, hi, tt, tr = Util.UnpackFields(rest)
    local entry = StoreSummary(sender, p, c, v, cls, fac, hi, tt, tr)
    if ns.Inspect then ns.Inspect:OnSummary(Util.NormalizeName(sender), entry) end
end

local function HandleRequest(sender)
    Comm:SendProfileTo(sender)
end

local function HandleProfile(sender, rest)
    local key = Util.NormalizeName(sender)
    local guild, recentCSV = Util.UnpackFields(rest)
    incoming[key] = incoming[key] or {}
    incoming[key].profile = {
        guild  = guild,
        recent = Util.UnpackIDList(recentCSV),
    }
end

local function HandleFull(sender, rest)
    local key = Util.NormalizeName(sender)
    local idx, total, csv = Util.UnpackFields(rest)
    idx, total = tonumber(idx), tonumber(total)
    if not idx or not total then return end

    local buf = incoming[key] or {}
    incoming[key] = buf
    buf.chunks = buf.chunks or {}
    buf.total  = total
    buf.chunks[idx] = Util.UnpackIDList(csv)

    -- Complete once every chunk has arrived.
    local have = 0
    for _ in pairs(buf.chunks) do have = have + 1 end
    if have < total then return end

    local completed = {}
    for i = 1, total do
        for _, id in ipairs(buf.chunks[i] or {}) do completed[#completed + 1] = id end
    end

    local entry = ns.DB:GetRosterEntry(key) or {}
    entry.completed = completed
    if buf.profile then
        entry.guild  = buf.profile.guild
        entry.recent = buf.profile.recent
    end
    entry.lastUpdate = time()
    ns.DB:SetRosterEntry(key, entry)
    incoming[key] = nil

    if ns.Inspect then ns.Inspect:OnFullReceived(key, entry) end
end

----------------------------------------------------------------------
-- Earned announcements ("X has earned [Achievement]!")
----------------------------------------------------------------------
function Comm:AnnounceEarned(id)
    if not ns.DB:Settings().announce then return end
    local channel = BroadcastChannel()
    if not channel then return end
    -- Sealed hidden achievements carry their seal key, so hearing about a
    -- discovery is what unmasks the achievement for everyone in earshot.
    local def = ns.GetAchievement(id)
    local k = (def and def.hidden and def._sealK) or ""
    self:Send(OP.EARNED, Util.PackFields(tostring(id), k), channel)
end

local function HandleEarned(sender, rest)
    local id, k = Util.UnpackFields(rest)   -- old clients sent a bare id; k is nil
    local def = ns.GetAchievement(id)
    if not def then return end
    if k == "" then k = nil end

    -- Hidden achievements: whoever we hear earned it first becomes its known
    -- discoverer (recorded even if the local player has announcements off),
    -- and the carried key unmasks a sealed def on the spot.
    if def.hidden then
        if def.sealed then ns.TryRevealHidden(def, k) end
        ns.DB:RecordDiscovery(def.id, Util.NormalizeName(sender), time(), k)
    end

    if not ns.DB:Settings().announce or not ns.AnnounceEarned then return end
    local entry = ns.DB:GetRosterEntry(Util.NormalizeName(sender))
    local cc = entry and Util.ClassColor(entry.classToken) or nil
    ns.AnnounceEarned(sender, def, cc)
end

local dispatch = {
    [OP.HELLO]   = HandleHello,
    [OP.SUMMARY] = HandleSummary,
    [OP.REQUEST] = HandleRequest,
    [OP.PROFILE] = HandleProfile,
    [OP.FULL]    = HandleFull,
    [OP.EARNED]  = HandleEarned,
}

local function OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= ns.COMM_PREFIX then return end
    if sender == Util.PlayerKey() or sender == UnitName("player") then return end -- ignore self
    local op, rest = message:match("^(.-)" .. Util.FIELD_SEP .. "(.*)$")
    if not op then op, rest = message, "" end
    local handler = dispatch[op]
    if handler then
        local ok, err = pcall(handler, sender, rest)
        if not ok then Util.Print("|cffff4444comm error|r:", err) end
    end
end

----------------------------------------------------------------------
-- Enable
----------------------------------------------------------------------
function Comm:Enable()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(ns.COMM_PREFIX)
    end
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:SetScript("OnEvent", function(_, _, ...) OnAddonMessage(...) end)
    self.frame = f
end

-- Convenience used by the inspect UI to decide if a target is known.
function Comm:HasAddon(name)
    local entry = ns.DB:GetRosterEntry(Util.NormalizeName(name))
    return entry ~= nil and entry.hasAddon == true
end
