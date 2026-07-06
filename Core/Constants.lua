--[[--------------------------------------------------------------------------
    Inri's Achievements! - Constants

    Single source of truth for values shared across modules: version, rarities,
    point values, colours, network prefix. Nothing here touches game state.
----------------------------------------------------------------------------]]

local _, ns = ...

ns.ADDON_NAME    = "InrisAchievements"

-- Version is read from the .toc so it can never drift from what's shipped.
local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
ns.VERSION = (meta and meta(ns.ADDON_NAME, "Version")) or "0.0.0"
-- Numeric form for fast comparison in networking ("1.0.1" -> 10001).
local maj, min, pat = ns.VERSION:match("(%d+)%.(%d+)%.?(%d*)")
ns.VERSION_NUM = (tonumber(maj) or 0) * 10000
             + (tonumber(min) or 0) * 100
             + (tonumber(pat) or 0)

ns.COMM_PREFIX   = "INRIACH"   -- max 16 chars for RegisterAddonMessagePrefix

----------------------------------------------------------------------
-- Rarities
-- Order matters: used for sort weight and "highest rarity" comparisons.
----------------------------------------------------------------------
ns.RARITY = {
    COMMON    = 1,
    RARE      = 2,
    EPIC      = 3,
    LEGENDARY = 4,
}

-- Per-rarity metadata. Points are awarded on completion; color drives every
-- bit of UI tinting so a rarity rebalance only happens in one place.
ns.RARITY_INFO = {
    [ns.RARITY.COMMON]    = { key = "COMMON",    points = 5,  locKey = "RARITY_COMMON",    color = { 0.78, 0.78, 0.78 }, hex = "c7c7c7" },
    [ns.RARITY.RARE]      = { key = "RARE",      points = 10, locKey = "RARITY_RARE",      color = { 0.12, 0.60, 1.00 }, hex = "1f99ff" },
    [ns.RARITY.EPIC]      = { key = "EPIC",      points = 25, locKey = "RARITY_EPIC",      color = { 0.64, 0.21, 0.93 }, hex = "a335ee" },
    [ns.RARITY.LEGENDARY] = { key = "LEGENDARY", points = 50, locKey = "RARITY_LEGENDARY", color = { 1.00, 0.50, 0.00 }, hex = "ff8000" },
}

----------------------------------------------------------------------
-- Progress / trigger types
-- Definitions declare one of these; the Engine routes events accordingly.
----------------------------------------------------------------------
ns.PROGRESS = {
    BOOLEAN = "BOOLEAN",   -- one-shot: done or not done
    COUNTER = "COUNTER",   -- accumulate up to a target count
    PROGRESS= "PROGRESS",  -- value vs. target with a bar (rep, skill)
    STAGED  = "STAGED",    -- several named sub-steps, all required
}

----------------------------------------------------------------------
-- Standing IDs used by reputation achievements (Blizzard faction standings)
----------------------------------------------------------------------
ns.STANDING = {
    HATED      = 1,
    HOSTILE    = 2,
    UNFRIENDLY = 3,
    NEUTRAL    = 4,
    FRIENDLY   = 5,
    HONORED    = 6,
    REVERED    = 7,
    EXALTED    = 8,
}

----------------------------------------------------------------------
-- Networking message opcodes (kept short to save bandwidth).
----------------------------------------------------------------------
ns.OP = {
    HELLO    = "H",   -- announce presence + summary
    SUMMARY  = "S",   -- points/count/version summary
    REQUEST  = "R",   -- request a full achievement dump
    FULL     = "F",   -- full dump of completed achievement IDs (chunked)
    PROFILE  = "P",   -- profile header (guild, recent, notable)
    EARNED   = "E",   -- "I just earned achievement <id>" (chat announce)
    DISCO    = "D",   -- known hidden-achievement discoveries (id, name, t, key)
}

----------------------------------------------------------------------
-- Sound kit IDs (paths no longer work for built-in sounds on 1.15+)
----------------------------------------------------------------------
ns.SOUND = {
    TOAST     = 888,    -- LevelUp
    LEGENDARY = 8959,   -- RaidWarning
    HIDDEN    = 8960,   -- ReadyCheck "bwoop"
    PING      = 3175,   -- MapPing (radar, nudges)
}

----------------------------------------------------------------------
-- Misc tunables
----------------------------------------------------------------------
ns.MAX_RECENT       = 25      -- recent achievements kept per character
ns.MAX_RECENT_SHARE = 5       -- recent achievements shared over the network
ns.SYNC_THROTTLE    = 15      -- seconds between automatic summary broadcasts
ns.COMM_CHUNK       = 200     -- max IDs per FULL chunk message

-- The icon shown when a definition omits one.
ns.DEFAULT_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- The addon's own logo (custom art shipped in Assets).
ns.LOGO = "Interface\\AddOns\\InrisAchievements\\Assets\\Logo.tga"

-- Where bug reports should be pasted.
ns.BUGREPORT_URL = "https://github.com/DrMally5/InrisAchievements/issues"

-- djb2 hash of the creator's Battle.net tag (see /ia whoami). Unlocks the
-- standalone "the Creator" title on every character of that account - there
-- is no visible achievement for it (that would be a bit smug).
ns.CREATOR_HASH = "af2930b8"
ns.CREATOR_NAME = "Inrii-Soulseeker"

-- The creator-only title. Not tied to any achievement; offered in the title
-- picker only when the running account matches CREATOR_HASH. Its synthetic id
-- distinguishes it from achievement-granted titles.
ns.CREATOR_TITLE = { id = "__creator", text = "the Creator", rarity = 4 }  -- 4 = LEGENDARY

-- True only on the addon author's Battle.net account. Cached once the tag is
-- available (BNGetInfo can be nil for a moment at login).
function ns.IsCreator()
    if ns._isCreator ~= nil then return ns._isCreator end
    if not BNGetInfo then return false end
    local _, tag = BNGetInfo()
    if not tag then return false end   -- unknown yet; don't cache a false
    ns._isCreator = ns.Util and (ns.Util.HashString(tag) == ns.CREATOR_HASH) or false
    return ns._isCreator
end

-- Inline gold star (the raid-target icon). The Unicode star U+2605 is NOT in
-- WoW's default font and renders as an empty box - use this texture instead.
ns.STAR_ICON = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t "
