--[[--------------------------------------------------------------------------
    Inri's Achievements! - Dwarf, Gnome & Night Elf Starting Side

    Completes the race balance: Humans had Elwynn/Westfall/Duskwood and the
    Horde races got their packs, but Dun Morogh / Loch Modan (dwarves, gnomes)
    and Teldrassil / Darkshore (night elves) had nothing. Mirrors Ach_Horde.lua.

    Names marked VERIFY are from memory - confirm in-game before Release. A
    wrong name simply never fires (never a false unlock).

    Leaf kills use category "LEGENDS" (folded into the "Hunts" tab).
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
-- Dun Morogh & Loch Modan
----------------------------------------------------------------------
Legend("leg_bjarn",     "Bjarn",             "Bjarn",             R.COMMON, "Interface\\Icons\\Ability_Druid_Bash",          "Khaz Modan")
Legend("leg_timber",    "Timber",            "Timber",            R.COMMON, "Interface\\Icons\\Ability_Mount_WhiteDireWolf", "Khaz Modan")
Legend("leg_edan",      "Edan the Howler",   "Edan the Howler",   R.RARE,   "Interface\\Icons\\Spell_Frost_FrostShock",      "Khaz Modan")
Legend("leg_icebeard",  "Old Icebeard",      "Old Icebeard",      R.COMMON, "Interface\\Icons\\Spell_Frost_ChillingBlast",   "Khaz Modan")
Legend("leg_olsooty",   "Ol' Sooty",         "Ol' Sooty",         R.COMMON, "Interface\\Icons\\INV_Misc_Pelt_Bear_01",       "Khaz Modan")  -- VERIFY

----------------------------------------------------------------------
-- Teldrassil & Darkshore
----------------------------------------------------------------------
Legend("leg_melenas",   "Fall of the Satyr", "Lord Melenas",      R.COMMON, "Interface\\Icons\\Spell_Shadow_SoulLeech_3",    "Kalimdor Shores")
Legend("leg_ursal",     "Ursal the Mauler",  "Ursal the Mauler",  R.COMMON, "Interface\\Icons\\Ability_Druid_Maul",          "Kalimdor Shores")
Legend("leg_sathrah",   "Lady Sathrah",      "Lady Sathrah",      R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Spider",   "Kalimdor Shores")
Legend("leg_blackmoss", "Blackmoss the Fetid","Blackmoss the Fetid", R.RARE, "Interface\\Icons\\Spell_Nature_NullifyDisease", "Kalimdor Shores")  -- VERIFY

----------------------------------------------------------------------
-- Zone Sagas (grant titles), mirroring the other races' Sagas
----------------------------------------------------------------------
A{
    id = "saga_khazmodan", name = "Guardian of Khaz Modan",
    description = "Defend the dwarven homeland: Bjarn, Timber, Edan the Howler, Vagash, Mangeclaw, Old Icebeard, and Ol' Sooty - then reclaim Gnomeregan.",
    category = "SERIES", subcategory = "Zone Sagas",
    rarity = R.RARE, trigger = "META",
    icon = "Interface\\Icons\\INV_Hammer_05",
    title = { text = "Guardian of Khaz Modan", rarity = R.RARE },
    requires = { "leg_bjarn", "leg_timber", "leg_edan", "rare_vagash", "leg_mangeclaw",
                 "leg_icebeard", "leg_olsooty", "dn_gnomer" },
}

A{
    id = "saga_teldrassil", name = "Sentinel of the Shores",
    description = "Protect the kal'dorei lands: Lord Melenas, Ursal the Mauler, Lady Sathrah, Blackmoss the Fetid, and Murkdeep - stand at the Master's Glaive and cleanse Blackfathom Deeps.",
    category = "SERIES", subcategory = "Zone Sagas",
    rarity = R.RARE, trigger = "META",
    icon = "Interface\\Icons\\Spell_Nature_Starfall",
    title = { text = "Sentinel of the Shores", rarity = R.RARE },
    requires = { "leg_melenas", "leg_ursal", "leg_sathrah", "leg_blackmoss",
                 "eq_murkdeep", "explore_glaive", "dn_bfd" },
}
