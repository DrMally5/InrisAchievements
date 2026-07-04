--[[--------------------------------------------------------------------------
    Inri's Achievements! - Rare Mobs

    The silver-dragon rares that lurk off the beaten path. A mix of named
    trophies and "how many can you find" counters using the live mob
    classification, so they scale to every zone without enumerating each rare.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R, P = ns.RegisterAchievement, ns.RARITY, ns.PROGRESS

local RARE_CLASS = { rare = true, rareelite = true }

----------------------------------------------------------------------
-- The hunt - counters by classification
----------------------------------------------------------------------
A{
    id = "first_rare", name = "Caught One!",
    description = "Slay your first rare creature.",
    category = "RARES", subcategory = "The Hunt",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    conditions = { classification = RARE_CLASS },
}

A{
    id = "rare_hunter_10", name = "Rare Hunter",
    description = "Slay 10 rare creatures.",
    category = "RARES", subcategory = "The Hunt",
    rarity = R.COMMON, trigger = "KILL",
    progressType = P.COUNTER, target = 10,
    icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
    conditions = { classification = RARE_CLASS },
}

A{
    id = "rare_hunter_50", name = "Trophy Wall",
    description = "Slay 50 rare creatures.",
    category = "RARES", subcategory = "The Hunt",
    rarity = R.RARE, trigger = "KILL",
    progressType = P.COUNTER, target = 50,
    icon = "Interface\\Icons\\INV_Misc_Pelt_Bear_Ruin_02",
    conditions = { classification = RARE_CLASS },
}

A{
    id = "rare_hunter_100", name = "Apex Predator",
    description = "Slay 100 rare creatures.",
    category = "RARES", subcategory = "The Hunt",
    rarity = R.EPIC, trigger = "KILL",
    progressType = P.COUNTER, target = 100,
    icon = "Interface\\Icons\\INV_Misc_MonsterClaw_03",
    conditions = { classification = RARE_CLASS },
}

----------------------------------------------------------------------
-- Named rares worth bragging about
----------------------------------------------------------------------
A{
    id = "rare_lupos", name = "Bad Moon Rising",
    description = "Hunt the worg Lupos in Duskwood.",
    category = "RARES", subcategory = "Named Rares",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
    conditions = { mobNames = { "Lupos" } },
}

A{
    id = "rare_gesharahan", name = "Deep Water Terror",
    description = "Dive for the water spirit Gesharahan lurking in the Barrens.",
    category = "RARES", subcategory = "Named Rares",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental",
    conditions = { mobNames = { "Gesharahan" } },
}

A{
    id = "rare_krethis", name = "Web of Lies",
    description = "Cut down Krethis Shadowspinner in Duskwood.",
    category = "RARES", subcategory = "Named Rares",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Shadow_CarrionSwarm",
    conditions = { mobNames = { "Krethis Shadowspinner" } },
}

A{
    id = "rare_snarler", name = "Top Dog",
    description = "Bring down Snarler in Silverpine Forest.",
    category = "RARES", subcategory = "Named Rares",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Druid_Ferociousbite",
    conditions = { mobNames = { "Snarler" } },
}

A{
    id = "rare_mist_howler", name = "Howl No More",
    description = "Silence the Mist Howler in the Alterac Mountains.",
    category = "RARES", subcategory = "Named Rares",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Nature_EarthBind",
    conditions = { mobNames = { "Mist Howler" } },
}
