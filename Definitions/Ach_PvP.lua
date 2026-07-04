--[[--------------------------------------------------------------------------
    Inri's Achievements! - Player vs Player

    World PvP is half of what made Classic Classic. Kills are counted from
    killing blows the player/group lands on enemy players (combat log
    PARTY_KILL with a Player GUID) - so these are earned in the world and in
    battlegrounds alike.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R, P = ns.RegisterAchievement, ns.RARITY, ns.PROGRESS

A{
    id = "pvp_first", name = "First Blood",
    description = "Land the killing blow on an enemy player.",
    category = "PVP", subcategory = "Killing Blows",
    rarity = R.COMMON, trigger = "PVPKILL",
    icon = "Interface\\Icons\\Ability_Rogue_Eviscerate",
    conditions = {},
}

A{
    id = "pvp_25", name = "Skirmisher",
    description = "Land killing blows on 25 enemy players.",
    category = "PVP", subcategory = "Killing Blows",
    rarity = R.RARE, trigger = "PVPKILL",
    progressType = P.COUNTER, target = 25,
    icon = "Interface\\Icons\\Ability_Warrior_Cleave",
    conditions = {},
}

A{
    id = "pvp_100", name = "Bloodthirsty",
    description = "Land killing blows on 100 enemy players.",
    category = "PVP", subcategory = "Killing Blows",
    rarity = R.EPIC, trigger = "PVPKILL",
    progressType = P.COUNTER, target = 100,
    icon = "Interface\\Icons\\Ability_Warrior_BloodFrenzy",
    conditions = {},
}

A{
    id = "pvp_500", name = "Terror of the Battlefield",
    description = "Land killing blows on 500 enemy players.",
    category = "PVP", subcategory = "Killing Blows",
    rarity = R.LEGENDARY, trigger = "PVPKILL",
    progressType = P.COUNTER, target = 500,
    icon = "Interface\\Icons\\INV_BannerPVP_01",
    title = { text = "the Merciless", rarity = R.LEGENDARY },
    conditions = {},
}
