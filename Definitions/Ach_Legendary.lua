--[[--------------------------------------------------------------------------
    Inri's Achievements! - Legendary

    The summit of Classic: raid end-bosses and world dragons. These are meant
    to be genuinely hard and worth the most points in the game.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

local function Slayer(id, name, desc, boss, npcID, rarity, icon)
    A{
        id = id, name = name, description = desc,
        category = "LEGENDARY", subcategory = "Raid & World",
        rarity = rarity, trigger = "KILL", icon = icon,
        conditions = { mobNames = { boss }, npcIDs = { npcID } },
    }
end

----------------------------------------------------------------------
-- World dragons & raid bosses
----------------------------------------------------------------------
Slayer("leg_onyxia",   "Dragonslayer",
    "Slay Onyxia, broodmother of the black dragonflight.",
    "Onyxia", 10184, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Black")

Slayer("leg_azuregos", "The Blue Menace",
    "Bring down Azuregos in Azshara.",
    "Azuregos", 6109, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Blue")

Slayer("leg_kazzak",   "Highlord's Bane",
    "Defeat Lord Kazzak in the Blasted Lands.",
    "Lord Kazzak", 12397, R.EPIC, "Interface\\Icons\\Spell_Shadow_SummonInfernal")

Slayer("leg_ragnaros", "The Firelord Falls",
    "Extinguish Ragnaros in the heart of the Molten Core.",
    "Ragnaros", 11502, R.LEGENDARY, "Interface\\Icons\\Spell_Fire_Volcano")

Slayer("leg_nefarian", "Blackwing Descent",
    "End the schemes of Nefarian atop Blackwing Lair.",
    "Nefarian", 11583, R.LEGENDARY, "Interface\\Icons\\INV_Misc_Head_Dragon_01")

Slayer("leg_cthun",    "Eye of the Old God",
    "Defeat C'Thun within the Temple of Ahn'Qiraj.",
    "C'Thun", 15727, R.LEGENDARY, "Interface\\Icons\\INV_Misc_AhnQirajTrinket_06")

Slayer("leg_kelthuzad","End of the Scourge",
    "Destroy Kel'Thuzad in the necropolis of Naxxramas.",
    "Kel'Thuzad", 15990, R.LEGENDARY, "Interface\\Icons\\Spell_Frost_Frost")

----------------------------------------------------------------------
-- The Emerald Dragons (roaming world bosses)
----------------------------------------------------------------------
Slayer("leg_ysondre", "The Dreamer's Bane",
    "Defeat the green dragon Ysondre.",
    "Ysondre", 14887, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Green")

Slayer("leg_lethon", "Shadow of the Dream",
    "Defeat the green dragon Lethon.",
    "Lethon", 14888, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Green")

Slayer("leg_emeriss", "Rot and Wither",
    "Defeat the green dragon Emeriss.",
    "Emeriss", 14889, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Green")

Slayer("leg_taerar", "The Broken One",
    "Defeat the green dragon Taerar.",
    "Taerar", 14890, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Green")

----------------------------------------------------------------------
-- Zul'Gurub (the 20-man troll raid)
----------------------------------------------------------------------
Slayer("leg_hakkar", "The Soulflayer",
    "Banish Hakkar, the Blood God of the Gurubashi, in Zul'Gurub.",
    "Hakkar", 14834, R.EPIC, "Interface\\Icons\\INV_Misc_MonsterFang_01")

Slayer("leg_mandokir", "Ohgan's Revenge",
    "Defeat Bloodlord Mandokir - and his raptor - in Zul'Gurub.",
    "Bloodlord Mandokir", 11382, R.RARE, "Interface\\Icons\\Ability_Hunter_Pet_Raptor")

Slayer("leg_jindo", "The Hexxer Hexed",
    "Defeat Jin'do the Hexxer in Zul'Gurub.",
    "Jin'do the Hexxer", 11380, R.RARE, "Interface\\Icons\\Spell_Shadow_Hex")

Slayer("leg_thekal", "Tiger King",
    "Defeat High Priest Thekal in Zul'Gurub.",
    "High Priest Thekal", 14509, R.RARE, "Interface\\Icons\\Ability_Hunter_Pet_Cat")

----------------------------------------------------------------------
-- Ruins of Ahn'Qiraj (AQ20)
----------------------------------------------------------------------
Slayer("leg_ossirian", "The Unscarred, Scarred",
    "Defeat Ossirian the Unscarred in the Ruins of Ahn'Qiraj.",
    "Ossirian the Unscarred", 15339, R.EPIC, "Interface\\Icons\\INV_Misc_AhnQirajTrinket_04")

Slayer("leg_buru", "Pop the Gorger",
    "Defeat Buru the Gorger in the Ruins of Ahn'Qiraj.",
    "Buru the Gorger", 15370, R.RARE, "Interface\\Icons\\INV_Misc_MonsterScales_07")

----------------------------------------------------------------------
-- The raid wings' most iconic mid-bosses
----------------------------------------------------------------------
Slayer("leg_vael", "Too Hot to Handle",
    "Defeat Vaelastrasz the Corrupt in Blackwing Lair.",
    "Vaelastrasz the Corrupt", 13020, R.EPIC, "Interface\\Icons\\INV_Misc_Head_Dragon_Red")

Slayer("leg_patchwerk", "Patchwerk Wants to Play",
    "Defeat Patchwerk in Naxxramas.",
    "Patchwerk", 16028, R.EPIC, "Interface\\Icons\\Spell_Shadow_AbominationExplosion")

Slayer("leg_loatheb", "Spore Loser",
    "Defeat Loatheb in Naxxramas.",
    "Loatheb", 16011, R.EPIC, "Interface\\Icons\\Spell_Nature_NullifyDisease")

Slayer("leg_sapphiron", "Frozen in Time",
    "Defeat Sapphiron, guardian of Kel'Thuzad, in Naxxramas.",
    "Sapphiron", 15989, R.EPIC, "Interface\\Icons\\Spell_Frost_FrostShock")

----------------------------------------------------------------------
-- The grandest meta in the game
----------------------------------------------------------------------
A{
    id = "leg_grandslam", name = "Champion of Azeroth",
    description = "Defeat Onyxia, Ragnaros, Nefarian, C'Thun, and Kel'Thuzad.",
    category = "LEGENDARY", subcategory = "Mastery",
    rarity = R.LEGENDARY, trigger = "META",
    icon = "Interface\\Icons\\INV_Sword_39",
    title = { text = "Champion of Azeroth", rarity = R.LEGENDARY },
    requires = { "leg_onyxia", "leg_ragnaros", "leg_nefarian", "leg_cthun", "leg_kelthuzad" },
}
