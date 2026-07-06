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
-- Secrets (hidden until someone discovers them). SEALED: name/description/
-- icon are encrypted, and the trigger targets ship only as hashes, so this
-- file spoils nothing. Each unseals the instant the right zone/mob is seen.
-- (See Core/Util.lua.)
----------------------------------------------------------------------
A{
    id = "hidden_princess_pig", name = "Hidden Achievement", description = "",
    category = "LEGENDS", subcategory = "Secrets",
    rarity = R.RARE, trigger = "KILL", hidden = true,
    sealed = "9db22590307520718aa6d234c4c6680db2823f097500723e50d34ed3a08030c445e4438f10a11c7bb920ae1f7df115f4623f751dfce1610930d2653be7359d38ed09e17a6795860f4468674e37bc06f990bc1b7d60c15c304a4d47afcc0d967d58ba3512f79037c199d76995293976f1011cd44df36d7ee7d1839ff0d409841a18ca8791364e",
    conditions = {
        matchers = { { h = "94a1162c", w = "8106a06586571bfed201a7dfcf89bc7b" } },
        inZoneH = { "3bc6bef5" },
    },
}

A{
    id = "hidden_newmans", name = "Hidden Achievement", description = "",
    category = "EXPLORATION", subcategory = "Secrets",
    rarity = R.RARE, trigger = "EXPLORE", hidden = true,
    sealed = "d0a9bdc02953765d7d663ed71b879a56d1ad3c8bd58e1d5e83fdadedb3de1eac38da971dd7261cdc45cc5db7926a340f2092090e0224191005877ca938b48c436b2bef0f1e788e4ae0a7e016de166a9b20657a46ffa766ff39a0d4ad8a79182327f1d8863feb31accd0feb90e1ed22cd49c65bc6",
    conditions = {
        matchers = { { h = "4fd484a2", w = "47c6a50aa755b7db1aaac5ab751baf27" } },
    },
}

A{
    id = "hidden_airfield", name = "Hidden Achievement", description = "",
    category = "EXPLORATION", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "EXPLORE", hidden = true,
    sealed = "ea8743b710680b8dff896c91927f1f2baf49cc11664db4b3de9ffdbe4d5d164ab5fda593e56fd51f8f789f802d4376ae0af8a1c1a2a4fe30fe1ddd834820fb0fbdf1764681126e020fc2338805db25a461160c609dbd4bd09c256760e7b5e5e22509a84f48f284b093a7f470c2d3631549",
    conditions = {
        matchers = {
            { h = "5ea36650", w = "31ce6393ee106a9a4e405510bd0ed320" },
            { h = "7a0055f8", w = "2b1c999f47fd944a43f87dca35387d09" },
        },
    },
}
