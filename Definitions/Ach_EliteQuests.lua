--[[--------------------------------------------------------------------------
    Inri's Achievements! - Elite Quests

    Famous "wanted" / group quests that send you after an elite target. These
    reward doing them at (or under) the level the quest was designed for, which
    is the real challenge - out-levelling a quest makes it trivial.

    Implemented against the elite target's death (reliable by name) plus a
    level cap, rather than a quest ID, so a definition never silently breaks
    if a quest ID shifts between client builds.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

A{
    id = "eq_murkdeep", name = "Wanted: Murkdeep",
    description = "Defeat the murloc Murkdeep in Darkshore at level 15 or below.",
    category = "ELITE_QUESTS", subcategory = "Kalimdor",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Misc_MonsterScales_14",
    conditions = { mobNames = { "Murkdeep" }, maxPlayerLevel = 15 },
}

A{
    id = "eq_stalvan", name = "The Legend of Stalvan",
    description = "End the curse of Stalvan Mistmantle in Duskwood at level 35 or below.",
    category = "ELITE_QUESTS", subcategory = "Eastern Kingdoms",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Shadow_Possession",
    conditions = { mobNames = { "Stalvan Mistmantle" }, maxPlayerLevel = 35 },
}

A{
    id = "eq_maraudos", name = "Wanted: Maraudos",
    description = "Defeat the centaur Maraudos in Desolace at level 40 or below.",
    category = "ELITE_QUESTS", subcategory = "Kalimdor",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk",
    conditions = { mobNames = { "Maraudos" }, maxPlayerLevel = 40 },
}

A{
    id = "eq_mokk", name = "Big Game Hunter",
    description = "Slay Mokk the Savage in Stranglethorn at level 37 or below.",
    category = "ELITE_QUESTS", subcategory = "Eastern Kingdoms",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Gorilla",
    conditions = { mobNames = { "Mokk the Savage" }, maxPlayerLevel = 37 },
}

A{
    id = "eq_ganzulah", name = "Zanzil's Secret",
    description = "Defeat Gan'zulah in Stranglethorn Vale at level 46 or below.",
    category = "ELITE_QUESTS", subcategory = "Eastern Kingdoms",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Shadow_Skull",
    conditions = { mobNames = { "Gan'zulah" }, maxPlayerLevel = 46 },
}

A{
    id = "eq_antusul", name = "The Spider God",
    description = "Defeat Antu'sul in Zul'Farrak at level 46 or below.",
    category = "ELITE_QUESTS", subcategory = "Kalimdor",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    conditions = { mobNames = { "Antu'sul" }, maxPlayerLevel = 46 },
}

A{
    id = "eq_zumrah", name = "The Prophecy of Mosh'aru",
    description = "Defeat Witch Doctor Zum'rah in Zul'Farrak at level 46 or below.",
    category = "ELITE_QUESTS", subcategory = "Kalimdor",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Shadow_AnimateDead",
    conditions = { mobNames = { "Witch Doctor Zum'rah" }, maxPlayerLevel = 46 },
}

A{
    id = "eq_tethis", name = "Sandfury Reckoning",
    description = "Defeat the elite Tethis in Tanaris at level 48 or below.",
    category = "ELITE_QUESTS", subcategory = "Kalimdor",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Nature_Sleep",
    conditions = { mobNames = { "Tethis" }, maxPlayerLevel = 48 },
}

----------------------------------------------------------------------
-- Meta
----------------------------------------------------------------------
A{
    id = "eq_master", name = "Most Wanted",
    description = "Complete every Elite Quest achievement at-level.",
    category = "ELITE_QUESTS", subcategory = "Mastery",
    rarity = R.EPIC, trigger = "META",
    icon = "Interface\\Icons\\INV_Misc_Note_02",
    title = { text = "Most Wanted", rarity = R.EPIC },
    requires = {
        "eq_murkdeep", "eq_stalvan", "eq_maraudos", "eq_mokk",
        "eq_ganzulah", "eq_antusul", "eq_zumrah", "eq_tethis",
    },
}
