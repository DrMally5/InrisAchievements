--[[--------------------------------------------------------------------------
    Inri's Achievements! - Localization (enUS / default)

    All user-facing strings funnel through ns.L. Missing keys fall back to the
    key itself, so the addon never shows a nil string even before a locale is
    finished. To add a locale, copy this table under a locale guard.
----------------------------------------------------------------------------]]

local _, ns = ...

-- A metatable means any unset key returns the key text instead of nil.
local L = setmetatable({}, { __index = function(_, k) return k end })
ns.L = L

----------------------------------------------------------------------
-- General
----------------------------------------------------------------------
L["ADDON_TITLE"]          = "Inri's Achievements!"
L["ADDON_LOADED"]         = "|cff00ff96Inri's Achievements!|r loaded. Type |cffffd100/ia|r to open."
L["SLASH_HELP_HEADER"]    = "Inri's Achievements! commands:"
L["SLASH_OPEN"]           = "/ia            - Open the achievement window"
L["SLASH_SEARCH"]         = "/ia search <text> - Open and search"
L["SLASH_STATS"]          = "/ia stats      - Print your points to chat"
L["SLASH_SYNC"]           = "/ia sync       - Force a roster sync"
L["SLASH_RESET"]          = "/ia reset      - Wipe this character's progress (asks first)"
L["SLASH_CONFIG"]         = "/ia config     - Toggle sounds / toasts"

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------
L["WINDOW_TITLE"]         = "Inri's Achievements!"
L["TOTAL_POINTS"]         = "Achievement Points"
L["COMPLETION"]           = "Completion"
L["RECENTLY_EARNED"]      = "Recently Earned"
L["ALL"]                  = "All"
L["FILTER_RARITY"]        = "Rarity"
L["FILTER_EARNED"]        = "Earned"
L["FILTER_UNEARNED"]      = "Unearned"
L["NO_RESULTS"]           = "No achievements match your filters."
L["LEADERBOARD"]          = "Leaderboard"
L["STATISTICS"]           = "Statistics"
L["YOU_SUFFIX"]           = " (you)"
L["ALT_SUFFIX"]           = " (alt)"
L["TRACK_ADDED"]          = "Now tracking: %s"
L["TRACK_REMOVED"]        = "No longer tracking: %s"
L["TRACK_FULL"]           = "You can track at most 5 achievements."
L["TRACK_HINT"]           = "Right-click: track on screen"
L["TRACKER_TITLE"]        = "Achievements"
L["EARNED_ON"]            = "Earned %s"
L["PROGRESS"]             = "Progress"
L["HIDDEN_NAME"]          = "Hidden Achievement"
L["HIDDEN_DESC"]          = "The details of this achievement are revealed once someone discovers it."
L["FIRST_DISCOVERED"]     = "First discovered by %s"
L["TITLE_REWARD"]         = "Title Reward: %s"
L["POINTS_SUFFIX"]        = "pts"
L["REQUIRES"]             = "Requires:"

----------------------------------------------------------------------
-- Rarities
----------------------------------------------------------------------
L["RARITY_COMMON"]        = "Common"
L["RARITY_RARE"]          = "Rare"
L["RARITY_EPIC"]          = "Epic"
L["RARITY_LEGENDARY"]     = "Legendary"

----------------------------------------------------------------------
-- Toast
----------------------------------------------------------------------
L["TOAST_EARNED"]         = "Achievement Earned!"
L["TOAST_DISCOVERED"]     = "Hidden Achievement Discovered!"

----------------------------------------------------------------------
-- Fun extras (radar, guild first, nudges, duels, knell)
----------------------------------------------------------------------
L["RADAR_NEARBY"]         = "|cffff8000Rare nearby:|r %s - needed for %s!"
L["NUDGE"]                = "Almost there: %s - %s"
L["KNELL"]                = "Your deathless run ends at level %d. It was a good one."
L["FLEX_LINE"]            = "%s - %d achievement points (%d/%d), rarest deed: %s"

----------------------------------------------------------------------
-- Bug reports
----------------------------------------------------------------------
L["BUG_TITLE"]            = "Report a Bug"
L["BUG_BUTTON"]           = "Report Bug"
L["BUG_INSTR"]            = "Describe what happened - what you did, what you expected, and what actually occurred:"
L["BUG_GENERATE"]         = "Generate Report"
L["BUG_COPY"]             = "Press Ctrl+C to copy, then paste the report at:"
L["SLASH_BUG"]            = "/ia bug        - Open the bug report window"

----------------------------------------------------------------------
-- Titles
----------------------------------------------------------------------
L["TITLES"]               = "Titles"
L["NO_TITLE"]             = "No Title"
L["TITLE_PICKER"]         = "Select a Title"
L["TITLE_NONE_UNLOCKED"]  = "You haven't unlocked any titles yet. Titles come from Sagas and other great deeds."
L["TITLE_SET"]            = "Title set to %s"
L["TITLE_CLEARED"]        = "Title cleared."
L["TITLE_LOCKED"]         = "You have not unlocked that title."
L["SLASH_TITLE"]          = "/ia titles - Pick your displayed title"

----------------------------------------------------------------------
-- Inspect
----------------------------------------------------------------------
L["INSPECT_MENU"]         = "View Achievements"
L["INSPECT_NO_ADDON"]     = "%s does not have Inri's Achievements! installed."
L["INSPECT_REQUESTING"]   = "Requesting achievements from %s..."
L["INSPECT_HIGHEST"]      = "Achievements"

----------------------------------------------------------------------
-- Categories (mirrors keys in Definitions\Categories.lua)
----------------------------------------------------------------------
L["CAT_LEVELING"]         = "Leveling"
L["CAT_NAMED"]            = "Hunts"
L["CAT_LEGENDS"]          = "Legends of Azeroth"
L["CAT_SERIES"]           = "Sagas"
L["CAT_RARES"]            = "Rare Mobs"
L["CAT_ELITE_QUESTS"]     = "Elite Quests"
L["CAT_DUNGEONS"]         = "Dungeons"
L["CAT_SPEEDRUN"]         = "Speed Runs"
L["CAT_EXPLORATION"]      = "Exploration"
L["CAT_CLASS"]            = "Class"
L["CAT_PROFESSIONS"]      = "Professions"
L["CAT_REPUTATION"]       = "Reputation"
L["CAT_PVP"]              = "Player vs Player"
L["CAT_HARDCORE"]         = "Feats of Survival"
L["CAT_HIDDEN"]           = "Hidden"
L["CAT_LEGENDARY"]        = "Legendary"
