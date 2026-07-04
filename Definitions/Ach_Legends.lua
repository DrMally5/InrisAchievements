--[[--------------------------------------------------------------------------
    Inri's Achievements! - Legends of Azeroth

    The iconic named enemies of Classic. Each is a standalone trophy, but their
    real purpose is to feed the Saga chains in Ach_Series.lua. Matched by name
    so they're robust across client builds.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

-- Helper for a simple "defeat this legend" kill.
local function Legend(id, name, mob, rarity, icon, sub)
    A{
        id = id, name = name,
        description = "Defeat " .. mob .. ".",
        category = "LEGENDS", subcategory = sub,
        rarity = rarity, trigger = "KILL", icon = icon,
        conditions = { mobNames = { mob } },
    }
end

----------------------------------------------------------------------
-- Elwynn & Westfall
----------------------------------------------------------------------
Legend("leg_bellygrub", "Bellygrub",          "Bellygrub",        R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Boar",     "Elwynn & Westfall")
Legend("leg_gruff",     "Gruff Swiftbite",     "Gruff Swiftbite",  R.COMMON, "Interface\\Icons\\Ability_Mount_WhiteDireWolf", "Elwynn & Westfall")
Legend("leg_garrick",   "Garrick Padfoot",     "Garrick Padfoot",  R.COMMON, "Interface\\Icons\\INV_Sword_04",                "Elwynn & Westfall")
Legend("leg_goldtooth", "Goldtooth",           "Goldtooth",        R.COMMON, "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", "Elwynn & Westfall")
Legend("leg_collector",  "The Collector",      "The Collector",    R.RARE,   "Interface\\Icons\\INV_Misc_Cape_01",            "Elwynn & Westfall")
Legend("leg_murkeye",   "Old Murk-Eye",        "Old Murk-Eye",     R.RARE,   "Interface\\Icons\\INV_Misc_Fish_02",            "Elwynn & Westfall")

----------------------------------------------------------------------
-- Scarlet Monastery
----------------------------------------------------------------------
Legend("leg_herod",     "Herod, Scarlet Champion", "Herod",                    R.RARE, "Interface\\Icons\\Ability_Warrior_Cleave",  "Scarlet Crusade")
Legend("leg_mograine",  "Scarlet Commander Mograine", "Scarlet Commander Mograine", R.RARE, "Interface\\Icons\\Spell_Holy_HolySmite", "Scarlet Crusade")

----------------------------------------------------------------------
-- The great beasts
----------------------------------------------------------------------
Legend("leg_bangalash", "King Bangalash",      "King Bangalash",   R.RARE, "Interface\\Icons\\Ability_Hunter_Pet_Cat",     "Great Beasts")
Legend("leg_mukla",     "King Mukla",          "King Mukla",       R.RARE, "Interface\\Icons\\Ability_Hunter_Pet_Gorilla", "Great Beasts")
Legend("leg_kingmosh",  "King Mosh",           "King Mosh",        R.EPIC, "Interface\\Icons\\Ability_Hunter_Pet_Devilsaur","Great Beasts")
Legend("leg_arugalson", "Son of Arugal",       "Son of Arugal",    R.RARE, "Interface\\Icons\\Spell_Shadow_ShadowWordDominate", "Great Beasts")

----------------------------------------------------------------------
-- Elementals
----------------------------------------------------------------------
Legend("leg_cyclonian", "Cyclonian",           "Cyclonian",        R.EPIC, "Interface\\Icons\\Spell_Nature_Cyclone",       "Elementals")
