--[[--------------------------------------------------------------------------
    Inri's Achievements! - Hidden

    Secret achievements. Their name and description stay masked in the UI until
    earned (the `hidden` flag). No hand-holding - players stumble into these.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

A{
    id = "hidden_leeroy", name = "Time's Up, Let's Do This",
    description = "Defeat 8 enemies within 10 seconds. At least you have chicken.",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "KILLSTREAK", hidden = true,
    icon = "Interface\\Icons\\INV_Misc_Food_59",
    title = { text = "Leeroy", rarity = R.EPIC },
    conditions = { count = 8 },
}

A{
    id = "hidden_lowbie_hero", name = "David and Goliath",
    description = "Before level 10, defeat an enemy at least 10 levels higher than you.",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "KILL", hidden = true,
    icon = "Interface\\Icons\\INV_Sword_04",
    conditions = { minLevelAbove = 10, maxPlayerLevel = 9 },
}

A{
    id = "hidden_points_500", name = "Collector",
    description = "Accumulate 500 achievement points.",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.RARE, trigger = "POINTS", hidden = true,
    icon = "Interface\\Icons\\INV_BannerPVP_02",
    conditions = { points = 500 },
}

A{
    id = "hidden_points_1000", name = "Completionist's Creed",
    description = "Accumulate 1,000 achievement points.",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "POINTS", hidden = true,
    icon = "Interface\\Icons\\INV_BannerPVP_01",
    title = { text = "the Dedicated", rarity = R.EPIC },
    conditions = { points = 1000 },
}

A{
    id = "hidden_time_sand", name = "Secrets of Tanaris",
    description = "Uncover both of Tanaris's loneliest secrets.",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.RARE, trigger = "META", hidden = true,
    icon = "Interface\\Icons\\INV_Misc_Idol_03",
    requires = { "explore_landsend", "explore_uldum" },
}

-- Only one account in the world can earn this one.
A{
    id = "hidden_creator", name = "Make This Addon",
    description = "Build Inri's Achievements! from nothing. There is exactly one way to earn this.",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.LEGENDARY, trigger = "CREATOR", hidden = true,
    icon = "Interface\\Icons\\INV_Misc_Gear_01",
    title = { text = "the Creator", rarity = R.LEGENDARY },
}
