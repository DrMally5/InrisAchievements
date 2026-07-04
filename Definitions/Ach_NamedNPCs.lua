--[[--------------------------------------------------------------------------
    Inri's Achievements! - Named Foes

    The famous named (yellow/elite) creatures of the old world. Plain kills are
    not enough - most of these gate on doing it early, solo, or the hard way.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

----------------------------------------------------------------------
-- Hogger - the rite of passage
----------------------------------------------------------------------
A{
    id = "hogger_early", name = "Who's Laughing Now?",
    description = "Defeat Hogger before reaching level 11.",
    category = "NAMED", subcategory = "Elwynn & Westfall",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Druid_Bash",
    conditions = { npcIDs = { 448 }, mobNames = { "Hogger" }, maxPlayerLevel = 10 },
}

A{
    id = "hogger_solo_early", name = "Hogger Was the Real Boss",
    description = "Solo Hogger before reaching level 10.",
    category = "NAMED", subcategory = "Elwynn & Westfall",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Druid_Maul",
    conditions = { npcIDs = { 448 }, mobNames = { "Hogger" }, maxPlayerLevel = 9, solo = true },
}

A{
    id = "mother_fang", name = "Spider's Bane",
    description = "Slay Mother Fang in the cellars beneath Elwynn.",
    category = "NAMED", subcategory = "Elwynn & Westfall",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
    conditions = { mobNames = { "Mother Fang" } },
}

A{
    id = "foe_reaper", name = "Scrap Heap",
    description = "Destroy the Foe Reaper 4000 in Westfall.",
    category = "NAMED", subcategory = "Elwynn & Westfall",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Gizmo_02",
    conditions = { npcIDs = { 6585 }, mobNames = { "Foe Reaper 4000" } },
}

----------------------------------------------------------------------
-- Duskwood - the spooky neighbour
----------------------------------------------------------------------
A{
    id = "morladim", name = "Rest, Father",
    description = "Lay Mor'Ladim to rest in Raven Hill Cemetery.",
    category = "NAMED", subcategory = "Duskwood",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    conditions = { npcIDs = { 1796 }, mobNames = { "Mor'Ladim" } },
}

A{
    id = "stitches", name = "He Comes at Night",
    description = "Defeat Stitches before he reaches the gates of Darkshire.",
    category = "NAMED", subcategory = "Duskwood",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Shadow_AnimateDead",
    conditions = { mobNames = { "Stitches" } },
}

A{
    id = "eliza", name = "Til Death Do Us Part",
    description = "Put the spectral bride Eliza back in the ground.",
    category = "NAMED", subcategory = "Duskwood",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    conditions = { mobNames = { "Eliza" } },
}

----------------------------------------------------------------------
-- Barrens & Kalimdor names
----------------------------------------------------------------------
A{
    id = "the_rake", name = "Raked Over",
    description = "Hunt down The Rake stalking the Barrens.",
    category = "NAMED", subcategory = "Kalimdor",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Druid_Rake",
    conditions = { npcIDs = { 3279 }, mobNames = { "The Rake" } },
}

A{
    id = "lord_cobrahn", name = "Snake in the Grass",
    description = "Defeat Lord Cobrahn of the Wailing Caverns.",
    category = "NAMED", subcategory = "Kalimdor",
    rarity = R.COMMON, trigger = "KILL",
    icon = "Interface\\Icons\\Spell_Nature_Polymorph_Cow",
    conditions = { npcIDs = { 3669 }, mobNames = { "Lord Cobrahn" } },
}

----------------------------------------------------------------------
-- The "intended way" challenges
----------------------------------------------------------------------
A{
    id = "princess_no_guards", name = "Lonely at the Top",
    description = "Defeat Princess in Razorfen Kraul without killing her bodyguards first.",
    category = "NAMED", subcategory = "The Hard Way",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
    conditions = {
        mobNames = { "Princess" },
        -- Zone-gated: "Princess" is also the pig in Elwynn's pumpkin patch!
        inZone = { "Razorfen Kraul" },
        withoutKillingNames = { "Death's Head Geomancer", "Death's Head Seer", "Razorfen Battleguard" },
    },
}

A{
    id = "greenskin_quartermaster", name = "Walk the Plank",
    description = "Defeat Captain Greenskin aboard the Defias juggernaut.",
    category = "NAMED", subcategory = "The Hard Way",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Misc_Cape_01",
    conditions = { npcIDs = { 643 }, mobNames = { "Captain Greenskin" } },
}

A{
    id = "mr_smite", name = "Smite Smitten",
    description = "Defeat Mr. Smite and survive all three of his stances.",
    category = "NAMED", subcategory = "The Hard Way",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\Ability_Warrior_Disarm",
    conditions = { npcIDs = { 646 }, mobNames = { "Mr. Smite" } },
}

----------------------------------------------------------------------
-- Meta: defeat every famous named foe in this category
----------------------------------------------------------------------
A{
    id = "named_collector", name = "A Face for Every Name",
    description = "Earn every Named Foes achievement.",
    category = "NAMED", subcategory = "Mastery",
    rarity = R.EPIC, trigger = "META",
    icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
    title = { text = "The Face Collector", rarity = R.EPIC },
    requires = {
        "hogger_early", "hogger_solo_early", "mother_fang", "foe_reaper",
        "morladim", "stitches", "eliza", "the_rake", "lord_cobrahn",
        "princess_no_guards", "greenskin_quartermaster", "mr_smite",
    },
}
