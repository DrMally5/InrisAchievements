--[[--------------------------------------------------------------------------
    Inri's Achievements! - Reputation

    The long grinds. Modeled as PROGRESS where the bar climbs through the
    standings (Neutral -> Exalted == 4 -> 8) via the REP trigger.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R, P = ns.RegisterAchievement, ns.RARITY, ns.PROGRESS
local EXALTED = ns.STANDING.EXALTED

-- Helper: an "Exalted with <faction>" achievement.
local function Exalted(id, title, faction, rarity, icon)
    A{
        id = id, name = title,
        description = "Reach Exalted with " .. faction .. ".",
        category = "REPUTATION", subcategory = "Exalted",
        rarity = rarity, trigger = "REP",
        progressType = P.PROGRESS, target = EXALTED,
        icon = icon,
        conditions = { faction = faction, standing = EXALTED },
    }
end

Exalted("rep_timbermaw",   "Friend of the Furbolgs",  "Timbermaw Hold",       R.EPIC, "Interface\\Icons\\Ability_Hunter_Pet_Bear")
Exalted("rep_argentdawn",  "Champion of the Dawn",    "Argent Dawn",          R.EPIC, "Interface\\Icons\\Spell_Holy_MindVision")
Exalted("rep_thorium",     "Thorium Brother",         "Thorium Brotherhood",  R.RARE, "Interface\\Icons\\INV_Ingot_06")
Exalted("rep_hydraxian",   "Servant of the Tides",    "Hydraxian Waterlords", R.RARE, "Interface\\Icons\\Spell_Frost_SummonWaterElemental")
Exalted("rep_cenarion",    "Guardian of Cenarius",    "Cenarion Circle",      R.EPIC, "Interface\\Icons\\Ability_Druid_TreeofLife")
Exalted("rep_zandalar",    "Friend of Zandalar",      "Zandalar Tribe",       R.EPIC, "Interface\\Icons\\INV_Misc_Coin_07")
Exalted("rep_wintersaber", "Saber Rider",             "Wintersaber Trainers", R.EPIC, "Interface\\Icons\\Ability_Mount_WhiteTiger")
Exalted("rep_shendralar",  "Knowledge Seeker",        "Shen'dralar",          R.RARE, "Interface\\Icons\\INV_Misc_Book_07")

----------------------------------------------------------------------
-- The legendary grind
----------------------------------------------------------------------
Exalted("rep_nozdormu",    "Master of Time",          "Brood of Nozdormu",    R.LEGENDARY, "Interface\\Icons\\INV_Misc_QirajiCrystal_05")
