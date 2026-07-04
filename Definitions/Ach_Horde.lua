--[[--------------------------------------------------------------------------
    Inri's Achievements! - Horde Starting Side

    Balances the (Alliance-heavy) low-level content with the iconic named mobs
    and zone Sagas of the Horde leveling path: Durotar, Mulgore, the Barrens,
    and the Forsaken lands (Tirisfal / Silverpine).

    NOTE: creature names below are matched by name. A few (marked "VERIFY") are
    from memory and should be confirmed in-game before the Release build - if a
    name is slightly off the achievement simply never fires (never a false
    unlock). Ghost Howl, Sarkoth, Kreenig Snarlsnout, Aean Swiftriver, Fellicent's
    Shade are the classics.

    Leaf kills use category "LEGENDS" (folded into the "Hunts" tab) so they sit
    alongside the Alliance legends under their own zone sub-headers.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

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
-- Durotar
----------------------------------------------------------------------
Legend("leg_sarkoth",  "Sarkoth",            "Sarkoth",          R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Scorpid", "Durotar")
Legend("leg_gazzuz",   "Burning Blade",      "Gazz'uz",          R.COMMON, "Interface\\Icons\\Spell_Fire_Fireball",         "Durotar")   -- VERIFY
Legend("leg_zalazane", "Free the Isles!",    "Zalazane",         R.RARE,   "Interface\\Icons\\Spell_Shadow_Hex",            "Durotar")

----------------------------------------------------------------------
-- Mulgore
----------------------------------------------------------------------
Legend("leg_ghosthowl","Ghost Howl",         "Ghost Howl",       R.RARE,   "Interface\\Icons\\Ability_Mount_WhiteDireWolf", "Mulgore")
Legend("leg_arrachea", "Battle of Mulgore",  "Arra'chea",        R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Boar",     "Mulgore")   -- VERIFY
Legend("leg_sharptusk","Palemane's Bane",    "Chief Sharptusk Thornmantle", R.COMMON, "Interface\\Icons\\INV_Misc_Bone_01",  "Mulgore")  -- VERIFY

----------------------------------------------------------------------
-- The Barrens
----------------------------------------------------------------------
Legend("leg_kreenig",  "Kreenig Snarlsnout", "Kreenig Snarlsnout", R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Boar",   "The Barrens")
Legend("leg_aean",     "Aean Swiftriver",    "Aean Swiftriver",    R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk", "The Barrens")
Legend("leg_razorsnout","Elder Razorsnout",  "Elder Mystic Razorsnout", R.RARE, "Interface\\Icons\\Ability_Hunter_Pet_Boar", "The Barrens")  -- VERIFY
Legend("leg_verog",    "Kolkar Warlord",     "Verog the Dervish",  R.COMMON, "Interface\\Icons\\Ability_Warrior_Cleave",    "The Barrens")   -- VERIFY
Legend("leg_hezrul",   "Blood of the Kolkar","Hezrul Bloodmark",   R.COMMON, "Interface\\Icons\\INV_Sword_04",              "The Barrens")   -- VERIFY

----------------------------------------------------------------------
-- Forsaken lands (Tirisfal & Silverpine)
----------------------------------------------------------------------
Legend("leg_fellicent","Restless Spirit",    "Fellicent's Shade",  R.RARE,   "Interface\\Icons\\Spell_Shadow_ShadowWordPain", "Forsaken Lands")
Legend("leg_maggoteye","Gnoll Punter",       "Maggot Eye",         R.COMMON, "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", "Forsaken Lands")
-- Mangeclaw is actually the Dun Morogh bear (dwarf/gnome quest target); it was
-- misfiled under Forsaken Lands originally. Lives here file-wise, but grouped
-- and saga'd with Khaz Modan.
Legend("leg_mangeclaw","Mangeclaw",          "Mangeclaw",          R.COMMON, "Interface\\Icons\\Ability_Druid_Bash",        "Khaz Modan")

----------------------------------------------------------------------
-- Zone Sagas (grant titles), mirroring the Alliance ones
----------------------------------------------------------------------
A{
    id = "saga_barrens", name = "Warden of the Barrens",
    description = "Tame the orc and troll heartland: Sarkoth, Gazz'uz, Zalazane, Kreenig Snarlsnout, Aean Swiftriver, and clear the Wailing Caverns.",
    category = "SERIES", subcategory = "Zone Sagas",
    rarity = R.RARE, trigger = "META",
    icon = "Interface\\Icons\\INV_Misc_Map02",
    title = { text = "Warden of the Barrens", rarity = R.RARE },
    requires = { "leg_sarkoth", "leg_gazzuz", "leg_zalazane", "leg_kreenig", "leg_aean", "dn_wc" },
}

A{
    id = "saga_mulgore", name = "Protector of Mulgore",
    description = "Defend the Tauren homeland: hunt Ghost Howl, The Rake, Arra'chea, and Chief Sharptusk Thornmantle.",
    category = "SERIES", subcategory = "Zone Sagas",
    rarity = R.RARE, trigger = "META",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Tallstrider",
    title = { text = "Protector of Mulgore", rarity = R.RARE },
    requires = { "leg_ghosthowl", "the_rake", "leg_arrachea", "leg_sharptusk" },
}

A{
    id = "saga_forsaken", name = "Scourge of Lordaeron",
    description = "Reclaim the Forsaken lands: Fellicent's Shade, Maggot Eye, Snarler, the Son of Arugal, and clear Shadowfang Keep.",
    category = "SERIES", subcategory = "Zone Sagas",
    rarity = R.RARE, trigger = "META",
    icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
    title = { text = "Scourge of Lordaeron", rarity = R.RARE },
    requires = { "leg_fellicent", "leg_maggoteye", "rare_snarler", "leg_arugalson", "dn_sfk" },
}
