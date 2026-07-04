--[[--------------------------------------------------------------------------
    Inri's Achievements! - Dungeons

    One achievement per dungeon, earned by defeating its final boss, plus a
    handful of "the hard way" challenge runs (level-capped, solo) and a meta
    that requires clearing them all.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

-- Helper: a standard "clear the dungeon" achievement keyed on the final boss.
local function Clear(id, name, boss, npcID, rarity, icon, sub)
    A{
        id = id, name = name,
        description = "Defeat " .. boss .. " to complete the dungeon.",
        category = "DUNGEONS", subcategory = sub,
        rarity = rarity, trigger = "KILL", icon = icon,
        conditions = { mobNames = { boss }, npcIDs = npcID and { npcID } or nil },
    }
end

----------------------------------------------------------------------
-- Low-level dungeons
----------------------------------------------------------------------
Clear("dn_rfc",       "Ragefire Chasm",   "Taragaman the Hungerer", 11520, R.COMMON, "Interface\\Icons\\Spell_Fire_Fireball02", "Low Level")
Clear("dn_deadmines", "The Deadmines",    "Edwin VanCleef",         644,   R.COMMON, "Interface\\Icons\\INV_Sword_24",          "Low Level")
Clear("dn_wc",        "Wailing Caverns",  "Mutanus the Devourer",   3654,  R.COMMON, "Interface\\Icons\\Spell_Nature_Polymorph", "Low Level")
Clear("dn_sfk",       "Shadowfang Keep",  "Archmage Arugal",        4275,  R.COMMON, "Interface\\Icons\\Spell_Shadow_ShadowWordPain", "Low Level")
Clear("dn_stockade",  "The Stockade",     "Bazil Thredd",           1716,  R.COMMON, "Interface\\Icons\\INV_Misc_Key_11",       "Low Level")
Clear("dn_bfd",       "Blackfathom Deeps","Aku'mai",                4829,  R.COMMON, "Interface\\Icons\\Spell_Frost_SummonWaterElemental", "Low Level")

----------------------------------------------------------------------
-- Mid-level dungeons
----------------------------------------------------------------------
Clear("dn_gnomer",    "Gnomeregan",       "Mekgineer Thermaplugg",  7800,  R.RARE, "Interface\\Icons\\INV_Gizmo_03",          "Mid Level")
Clear("dn_rfk",       "Razorfen Kraul",   "Charlga Razorflank",     4421,  R.RARE, "Interface\\Icons\\Ability_Hunter_Pet_Boar", "Mid Level")
Clear("dn_rfd",       "Razorfen Downs",   "Amnennar the Coldbringer", 7358, R.RARE, "Interface\\Icons\\Spell_Frost_FrostBolt02", "Mid Level")
Clear("dn_sm",        "Scarlet Monastery","High Inquisitor Whitemane", 3977, R.RARE, "Interface\\Icons\\Spell_Holy_HolySmite", "Mid Level")
Clear("dn_uldaman",   "Uldaman",          "Archaedas",              2748,  R.RARE, "Interface\\Icons\\Spell_Nature_EarthQuake", "Mid Level")
Clear("dn_zf",        "Zul'Farrak",       "Chief Ukorz Sandscalp",  7267,  R.RARE, "Interface\\Icons\\INV_Sword_48",          "Mid Level")
Clear("dn_maraudon",  "Maraudon",         "Princess Theradras",     12201, R.RARE, "Interface\\Icons\\INV_Misc_Gem_Emerald_02", "Mid Level")
Clear("dn_st",        "Sunken Temple",    "Shade of Eranikus",      5709,  R.RARE, "Interface\\Icons\\Spell_Nature_WispSplode", "Mid Level")

----------------------------------------------------------------------
-- High-level dungeons
----------------------------------------------------------------------
Clear("dn_brd",       "Blackrock Depths", "Emperor Dagran Thaurissan", 9019, R.EPIC, "Interface\\Icons\\Spell_Fire_Incinerate", "High Level")
Clear("dn_lbrs",      "Lower Blackrock Spire", "Overlord Wyrmthalak", 9568, R.EPIC, "Interface\\Icons\\INV_Misc_MonsterScales_15", "High Level")
Clear("dn_ubrs",      "Upper Blackrock Spire", "General Drakkisath",  10363, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Black", "High Level")
Clear("dn_dm",        "Dire Maul: West",  "Prince Tortheldrin",     11486, R.EPIC, "Interface\\Icons\\Spell_Shadow_SummonImp", "High Level")
Clear("dn_dm_east",   "Dire Maul: East",  "Alzzin the Wildshaper",  11492, R.EPIC, "Interface\\Icons\\Spell_Nature_Regenerate", "High Level")
Clear("dn_dm_north",  "Dire Maul: North", "King Gordok",            11501, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Ogre_01",  "High Level")
Clear("dn_scholo",    "Scholomance",      "Darkmaster Gandling",    1853,  R.EPIC, "Interface\\Icons\\Spell_Shadow_DeathCoil", "High Level")
Clear("dn_strat",     "Stratholme",       "Baron Rivendare",        10440, R.EPIC, "Interface\\Icons\\Ability_Mount_Dreadsteed", "High Level")

----------------------------------------------------------------------
-- The hard way
----------------------------------------------------------------------
A{
    id = "dn_deadmines_lowlevel", name = "Defias Bootcamp",
    description = "Defeat Edwin VanCleef with no group member above level 21.",
    category = "DUNGEONS", subcategory = "The Hard Way",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Misc_Cape_01",
    conditions = { mobNames = { "Edwin VanCleef" }, npcIDs = { 644 }, maxGroupLevel = 21 },
}

A{
    id = "dn_sfk_solo", name = "Who's Afraid of the Big Bad Worgen?",
    description = "Solo Archmage Arugal in Shadowfang Keep.",
    category = "DUNGEONS", subcategory = "The Hard Way",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate",
    conditions = { mobNames = { "Archmage Arugal" }, npcIDs = { 4275 }, solo = true },
}

A{
    id = "dn_gnomer_lowlevel", name = "Underleveled & Overclocked",
    description = "Defeat Mekgineer Thermaplugg with no group member above level 26.",
    category = "DUNGEONS", subcategory = "The Hard Way",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Gizmo_02",
    conditions = { mobNames = { "Mekgineer Thermaplugg" }, npcIDs = { 7800 }, maxGroupLevel = 26 },
}

----------------------------------------------------------------------
-- Metas
----------------------------------------------------------------------
A{
    id = "dn_dm_master", name = "Master of the Maul",
    description = "Clear all three wings of Dire Maul.",
    category = "DUNGEONS", subcategory = "Mastery",
    rarity = R.EPIC, trigger = "META",
    icon = "Interface\\Icons\\INV_Misc_Head_Ogre_01",
    title = { text = "the Gordok", rarity = R.EPIC },
    requires = { "dn_dm", "dn_dm_east", "dn_dm_north" },
}

A{
    id = "dn_master", name = "Dungeon Master",
    description = "Complete every 5-player dungeon in the old world.",
    category = "DUNGEONS", subcategory = "Mastery",
    rarity = R.LEGENDARY, trigger = "META",
    icon = "Interface\\Icons\\INV_Misc_Key_11",
    title = { text = "Dungeon Master", rarity = R.LEGENDARY },
    requires = {
        "dn_rfc", "dn_deadmines", "dn_wc", "dn_sfk", "dn_stockade", "dn_bfd",
        "dn_gnomer", "dn_rfk", "dn_rfd", "dn_sm", "dn_uldaman", "dn_zf",
        "dn_maraudon", "dn_st", "dn_brd", "dn_lbrs", "dn_ubrs",
        "dn_dm", "dn_dm_east", "dn_dm_north",
        "dn_scholo", "dn_strat",
    },
}
