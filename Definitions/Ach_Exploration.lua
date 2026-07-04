--[[--------------------------------------------------------------------------
    Inri's Achievements! - Exploration

    Not "discover Westfall". These reward reaching the remote, dangerous, and
    hidden corners of Azeroth - and crossing faction lines to do it.

    EXPLORE matches the current zone / subzone / minimap-zone text against the
    `zones` list. STAGED variants use each zone string as a stage key.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R, P = ns.RegisterAchievement, ns.RARITY, ns.PROGRESS

----------------------------------------------------------------------
-- See the sights - visit every capital, both factions
----------------------------------------------------------------------
A{
    id = "explore_capitals", name = "Stranger in Every Land",
    description = "Set foot in all six capital cities of the Alliance and the Horde.",
    category = "EXPLORATION", subcategory = "Cities",
    rarity = R.EPIC, trigger = "EXPLORE", progressType = P.STAGED,
    icon = "Interface\\Icons\\INV_Misc_Map_01",
    conditions = {
        zones = {
            "Stormwind City", "Ironforge", "Darnassus",
            "Orgrimmar", "Thunder Bluff", "Undercity",
        },
    },
    stages = {
        { key = "Stormwind City", name = "Stormwind City" },
        { key = "Ironforge",      name = "Ironforge" },
        { key = "Darnassus",      name = "Darnassus" },
        { key = "Orgrimmar",      name = "Orgrimmar" },
        { key = "Thunder Bluff",  name = "Thunder Bluff" },
        { key = "Undercity",      name = "Undercity" },
    },
}

----------------------------------------------------------------------
-- Wonders of the world - the dangerous high zones
----------------------------------------------------------------------
A{
    id = "explore_wonders", name = "Wonders of Azeroth",
    description = "Travel to each of Azeroth's most remote and dangerous regions.",
    category = "EXPLORATION", subcategory = "The Wilds",
    rarity = R.RARE, trigger = "EXPLORE", progressType = P.STAGED,
    icon = "Interface\\Icons\\INV_Misc_Map02",
    conditions = {
        zones = {
            "Un'Goro Crater", "Winterspring", "Silithus",
            "Eastern Plaguelands", "Burning Steppes", "Blasted Lands", "Moonglade",
        },
    },
    stages = {
        { key = "Un'Goro Crater",      name = "Un'Goro Crater" },
        { key = "Winterspring",        name = "Winterspring" },
        { key = "Silithus",            name = "Silithus" },
        { key = "Eastern Plaguelands", name = "Eastern Plaguelands" },
        { key = "Burning Steppes",     name = "Burning Steppes" },
        { key = "Blasted Lands",       name = "Blasted Lands" },
        { key = "Moonglade",           name = "Moonglade" },
    },
}

----------------------------------------------------------------------
-- Hidden corners
----------------------------------------------------------------------
A{
    id = "explore_landsend", name = "Land's End",
    description = "Reach the lonely southern shore of Land's End Beach in Tanaris.",
    category = "EXPLORATION", subcategory = "Hidden",
    rarity = R.COMMON, trigger = "EXPLORE",
    icon = "Interface\\Icons\\INV_Misc_Shell_04",
    conditions = { zones = { "Land's End Beach" } },
}

A{
    id = "explore_uldum", name = "Forbidden Sands",
    description = "Discover the sealed gate of Uldum in southern Tanaris.",
    category = "EXPLORATION", subcategory = "Hidden",
    rarity = R.RARE, trigger = "EXPLORE",
    icon = "Interface\\Icons\\INV_Misc_Idol_03",
    conditions = { zones = { "Uldum", "Gates of Uldum" } },
}

A{
    id = "explore_glaive", name = "The Master's Glaive",
    description = "Stand beneath the fallen blade of the Master's Glaive in Darkshore.",
    category = "EXPLORATION", subcategory = "Hidden",
    rarity = R.COMMON, trigger = "EXPLORE",
    icon = "Interface\\Icons\\INV_Sword_18",
    conditions = { zones = { "The Master's Glaive" } },
}

A{
    id = "explore_aq_gates", name = "At the Gates",
    description = "Stand before the Gates of Ahn'Qiraj in Silithus.",
    category = "EXPLORATION", subcategory = "Hidden",
    rarity = R.EPIC, trigger = "EXPLORE",
    icon = "Interface\\Icons\\INV_Misc_AhnQirajTrinket_05",
    conditions = { zones = { "The Scarab Wall", "Ahn'Qiraj" } },
}

-- NOTE: "enter Blackrock Mountain" was removed - every endgame character walks
-- through it on the way to BRD/MC, making it automatic rather than earned.
