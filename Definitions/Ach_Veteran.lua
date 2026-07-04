--[[--------------------------------------------------------------------------
    Inri's Achievements! - Veteran's Picks

    The kills and secrets a long-time Classic player actually brags about:
    Stratholme's nightmares, UBRS's Beast, the roaming doomguard of the Blasted
    Lands, the OTHER Princess, and two of the old world's worst-kept secret
    places. Names marked VERIFY should be confirmed in-game before Release.
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
-- Stratholme's rogues gallery
----------------------------------------------------------------------
Legend("leg_timmy",     "Little Timmy",       "Timmy the Cruel",     R.RARE, "Interface\\Icons\\Spell_Shadow_DeathScream",  "Stratholme")
Legend("leg_unforgiven","The Unforgiven",     "The Unforgiven",      R.RARE, "Interface\\Icons\\Spell_Shadow_Haunting",     "Stratholme")

A{
    id = "leg_malown", name = "Return to Sender",
    description = "Defeat Postmaster Malown. The mail always gets delivered.",
    category = "LEGENDS", subcategory = "Stratholme",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Letter_15",
    conditions = { mobNames = { "Postmaster Malown" } },
}

----------------------------------------------------------------------
-- The mountain and the wastes
----------------------------------------------------------------------
Legend("leg_thebeast",  "Beauty Is a Beast",  "The Beast",           R.EPIC, "Interface\\Icons\\INV_Misc_MonsterHead_02",   "Blackrock")
Legend("leg_teremus",   "Devourer Devoured",  "Teremus the Devourer",R.EPIC, "Interface\\Icons\\Spell_Shadow_SummonFelHunter", "The Wastes")

----------------------------------------------------------------------
-- Scarlet Monastery, completed (feeds The Scarlet Executioner saga)
----------------------------------------------------------------------
Legend("leg_doan",      "Arcanist Doan",      "Arcanist Doan",       R.COMMON, "Interface\\Icons\\Spell_Nature_WispSplode",      "Scarlet Crusade")
Legend("leg_loksey",    "Houndmaster",        "Houndmaster Loksey",  R.COMMON, "Interface\\Icons\\Ability_Hunter_BeastCall", "Scarlet Crusade")

----------------------------------------------------------------------
-- Seasonal (these bosses only exist during their world events, so the
-- events themselves are the date gate - no extra logic needed)
----------------------------------------------------------------------
A{
    id = "season_omen", name = "Bane of the Dog",
    description = "During the Lunar Festival, defeat Omen in Moonglade.",
    category = "LEGENDS", subcategory = "Seasonal",
    rarity = R.EPIC, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Misc_Bomb_07",
    conditions = { mobNames = { "Omen" } },
}

A{
    id = "season_greench", name = "You're a Mean One",
    description = "During the Feast of Winter Veil, defeat The Abominable Greench.",
    category = "LEGENDS", subcategory = "Seasonal",
    rarity = R.RARE, trigger = "KILL",
    icon = "Interface\\Icons\\INV_Holiday_Christmas_Present_01",
    conditions = { mobNames = { "The Abominable Greench" } },
}

----------------------------------------------------------------------
-- Secrets (hidden until someone discovers them)
----------------------------------------------------------------------
A{
    id = "hidden_princess_pig", name = "The Other Princess",
    description = "Slay Princess, the prize pig of the Brackwell Pumpkin Patch in Elwynn Forest.",
    category = "LEGENDS", subcategory = "Secrets",
    rarity = R.RARE, trigger = "KILL", hidden = true,
    icon = "Interface\\Icons\\INV_Misc_Food_49",
    conditions = { mobNames = { "Princess" }, inZone = { "Elwynn Forest" } },
}

A{
    id = "hidden_newmans", name = "Smuggler's Cove",
    description = "Find Newman's Landing, the forgotten dock on the Dun Morogh coast.",
    category = "EXPLORATION", subcategory = "Secrets",
    rarity = R.RARE, trigger = "EXPLORE", hidden = true,
    icon = "Interface\\Icons\\INV_Crate_01",
    conditions = { zones = { "Newman's Landing" } },   -- VERIFY
}

A{
    id = "hidden_airfield", name = "Top of the World",
    description = "Set foot on the Ironforge Airfield, high above Dun Morogh.",
    category = "EXPLORATION", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "EXPLORE", hidden = true,
    icon = "Interface\\Icons\\INV_Misc_Bomb_04",
    conditions = { zones = { "Ironforge Airfield", "Dun Morogh Airfield" } },   -- VERIFY
}
