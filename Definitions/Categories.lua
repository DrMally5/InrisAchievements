--[[--------------------------------------------------------------------------
    Inri's Achievements! - Categories

    The left-hand category list of the main window. Keys here are referenced by
    every achievement's `category` field. Order controls display order.
----------------------------------------------------------------------------]]

local _, ns = ...
local L = ns.L

local function C(key, locKey, icon)
    ns.RegisterCategory({ key = key, name = L[locKey], icon = icon })
end

-- Consolidated tab list. (Definitions still use granular categories like
-- LEGENDS/RARES/SPEEDRUN; Engine.lua folds them into these tabs.)
C("LEVELING",     "CAT_LEVELING",     "Interface\\Icons\\Spell_Holy_AuraMastery")
C("NAMED",        "CAT_NAMED",        "Interface\\Icons\\INV_Misc_Head_Dragon_Black")
C("DUNGEONS",     "CAT_DUNGEONS",     "Interface\\Icons\\INV_Misc_Key_11")
C("LEGENDARY",    "CAT_LEGENDARY",    "Interface\\Icons\\INV_Sword_39")
C("EXPLORATION",  "CAT_EXPLORATION",  "Interface\\Icons\\INV_Misc_Map_01")
C("REPUTATION",   "CAT_REPUTATION",   "Interface\\Icons\\INV_BannerPVP_02")
C("PROFESSIONS",  "CAT_PROFESSIONS",  "Interface\\Icons\\Trade_BlackSmithing")
C("CLASS",        "CAT_CLASS",        "Interface\\Icons\\Spell_Nature_Polymorph")
C("PVP",          "CAT_PVP",          "Interface\\Icons\\INV_BannerPVP_02")
C("HARDCORE",     "CAT_HARDCORE",     "Interface\\Icons\\Ability_Rogue_FeignDeath")
C("SERIES",       "CAT_SERIES",       "Interface\\Icons\\INV_Scroll_05")
C("HIDDEN",       "CAT_HIDDEN",       "Interface\\Icons\\INV_Misc_QuestionMark")
