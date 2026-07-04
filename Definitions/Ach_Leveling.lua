--[[--------------------------------------------------------------------------
    Inri's Achievements! - Leveling & Combat Milestones

    Classic leveling is a grind, so the milestones that remain (40 for a mount,
    60 at the cap) are genuine accomplishments. The rest are "punch above your
    weight" combat feats, not participation dings.

    Definition schema reference (only `id`, `name`, `category`, `trigger` are
    strictly required; everything else has a sensible default):
        id           unique string
        name         display name
        description  flavour / how to earn
        category     category key (see Categories.lua)
        subcategory  optional grouping inside a category
        rarity       ns.RARITY.*  (drives points + colour)
        icon         texture path
        trigger      which evaluator handles it (KILL/LEVEL/...)
        progressType ns.PROGRESS.*  (BOOLEAN default)
        target       goal for COUNTER/PROGRESS
        stages       { {key=, name=}, ... } for STAGED
        requires     { otherId, ... } prerequisites
        hidden       true to hide details until earned
        conditions   per-trigger criteria table
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R, P = ns.RegisterAchievement, ns.RARITY, ns.PROGRESS

----------------------------------------------------------------------
-- Level milestones. Deliberately only TWO: level 40 (the mount, Classic's
-- great gold wall) and 60. Intermediate dings are participation, not
-- accomplishment - see the core philosophy at the top of this file.
----------------------------------------------------------------------
A{
    id = "level_40", name = "Need for Steed",
    description = "Reach level 40 and earn your first mount.",
    category = "LEVELING", subcategory = "Milestones",
    rarity = R.RARE, trigger = "LEVEL",
    icon = "Interface\\Icons\\Ability_Mount_RidingHorse",
    conditions = { level = 40 },
}

A{
    id = "level_60", name = "The Long Road",
    description = "Reach level 60, the pinnacle of Azeroth.",
    category = "LEVELING", subcategory = "Milestones",
    rarity = R.EPIC, trigger = "LEVEL",
    icon = "Interface\\Icons\\Spell_Holy_AuraMastery",
    conditions = { level = 60 },
}

----------------------------------------------------------------------
-- Punching above your weight
----------------------------------------------------------------------
A{
    id = "punching_up", name = "Punching Up",
    description = "Defeat an enemy at least 5 levels higher than you.",
    category = "LEVELING", subcategory = "Combat Feats",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Warrior_Challange",
    conditions = { minLevelAbove = 5 },
}

A{
    id = "giant_slayer", name = "Giant Slayer",
    description = "Defeat an enemy at least 10 levels higher than you. Skull-rated foes count.",
    category = "LEVELING", subcategory = "Combat Feats",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Warrior_DecisiveStrike",
    conditions = { minLevelAbove = 10 },
}

A{
    id = "elite_solo_overlevel", name = "No Help Needed",
    description = "Solo a Rare or Elite creature that out-levels you.",
    category = "LEVELING", subcategory = "Combat Feats",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Rogue_Ambush",
    conditions = {
        solo = true, minLevelAbove = 3,
        classification = { elite = true, rareelite = true, rare = true },
    },
}

-- NOTE: raw kill-count achievements (100/1000 kills) were removed on purpose:
-- every character passes them automatically while leveling, which violates the
-- "I actually earned this" rule. Counters belong on RARE kills, not any kills.
