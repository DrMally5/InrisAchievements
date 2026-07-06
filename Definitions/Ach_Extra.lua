--[[--------------------------------------------------------------------------
    Inri's Achievements! - Extra content

    A second pass of hand-picked, Classic-authentic achievements. Everything
    here reuses existing triggers/conditions and existing categories, so it adds
    depth without any engine or UI changes. Kills match by name (robust); boss
    feats also carry NPC IDs.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R, P = ns.RegisterAchievement, ns.RARITY, ns.PROGRESS
local EXALTED = ns.STANDING.EXALTED

----------------------------------------------------------------------
-- Solo a dungeon end-boss (no group)
----------------------------------------------------------------------
local function Solo(id, name, boss, npcID, icon)
    A{
        id = id, name = name,
        description = "Solo " .. boss .. " with no one else in your party.",
        category = "DUNGEONS", subcategory = "Solo Clears",
        rarity = R.RARE, trigger = "KILL", icon = icon,
        conditions = { mobNames = { boss }, npcIDs = { npcID }, solo = true },
    }
end

Solo("solo_deadmines", "Solo: The Deadmines",   "Edwin VanCleef",            644,   "Interface\\Icons\\INV_Sword_24")
Solo("solo_wc",        "Solo: Wailing Caverns", "Mutanus the Devourer",      3654,  "Interface\\Icons\\Spell_Nature_Polymorph")
Solo("solo_stockade",  "Solo: The Stockade",    "Bazil Thredd",              1716,  "Interface\\Icons\\INV_Misc_Key_11")
Solo("solo_bfd",       "Solo: Blackfathom Deeps","Aku'mai",                  4829,  "Interface\\Icons\\Spell_Frost_SummonWaterElemental")
Solo("solo_rfk",       "Solo: Razorfen Kraul",  "Charlga Razorflank",        4421,  "Interface\\Icons\\Ability_Hunter_Pet_Boar")
Solo("solo_sm",        "Solo: Scarlet Monastery","High Inquisitor Whitemane", 3977, "Interface\\Icons\\Spell_Holy_HolySmite")

----------------------------------------------------------------------
-- Under-level group clears (no party member above the cap)
----------------------------------------------------------------------
local function Underdog(id, name, dungeon, boss, npcID, maxLvl, icon)
    A{
        id = id, name = name,
        description = "Defeat " .. boss .. " in " .. dungeon ..
            " with no group member above level " .. maxLvl .. ".",
        category = "DUNGEONS", subcategory = "Underdog",
        rarity = R.EPIC, trigger = "KILL", icon = icon,
        conditions = { mobNames = { boss }, npcIDs = { npcID }, maxGroupLevel = maxLvl },
    }
end

Underdog("ud_wc",       "Underdog: Wailing Caverns", "Wailing Caverns",  "Mutanus the Devourer",      3654,  21, "Interface\\Icons\\Ability_Warrior_Challange")
Underdog("ud_uldaman",  "Underdog: Uldaman",         "Uldaman",          "Archaedas",                 2748,  37, "Interface\\Icons\\Spell_Nature_EarthQuake")
Underdog("ud_rfd",      "Underdog: Razorfen Downs",  "Razorfen Downs",   "Amnennar the Coldbringer",  7358,  39, "Interface\\Icons\\Spell_Frost_FrostBolt02")
Underdog("ud_sm",       "Underdog: Scarlet Monastery","Scarlet Monastery","High Inquisitor Whitemane", 3977,  40, "Interface\\Icons\\Spell_Holy_HolySmite")
Underdog("ud_zf",       "Underdog: Zul'Farrak",      "Zul'Farrak",       "Chief Ukorz Sandscalp",     7267,  46, "Interface\\Icons\\INV_Sword_48")
Underdog("ud_maraudon", "Underdog: Maraudon",        "Maraudon",         "Princess Theradras",        12201, 48, "Interface\\Icons\\INV_Misc_Gem_Emerald_02")

----------------------------------------------------------------------
-- More speed clears
----------------------------------------------------------------------
local function Speed(id, name, dungeon, boss, npcID, minutes, rarity, icon)
    A{
        id = id, name = name,
        description = string.format("Defeat %s within %d minutes of entering %s.",
            boss, minutes, dungeon),
        category = "SPEEDRUN", subcategory = dungeon,
        rarity = rarity, trigger = "KILL", icon = icon,
        conditions = { mobNames = { boss }, npcIDs = { npcID }, maxSeconds = minutes * 60 },
    }
end

Speed("spd_rfk",      "Boar Down",       "Razorfen Kraul", "Charlga Razorflank",       4421,  18, R.RARE, "Interface\\Icons\\Ability_Hunter_Pet_Boar")
Speed("spd_rfd",      "Cold Snap",       "Razorfen Downs", "Amnennar the Coldbringer", 7358,  22, R.RARE, "Interface\\Icons\\Spell_Frost_FrostBolt02")
Speed("spd_uldaman",  "Dig Site Dash",   "Uldaman",        "Archaedas",                2748,  25, R.RARE, "Interface\\Icons\\Spell_Nature_EarthQuake")
Speed("spd_maraudon", "Crystal Sprint",  "Maraudon",       "Princess Theradras",       12201, 30, R.EPIC, "Interface\\Icons\\INV_Misc_Gem_Emerald_02")
Speed("spd_gnomer",   "Clockwork",       "Gnomeregan",     "Mekgineer Thermaplugg",    7800,  30, R.EPIC, "Interface\\Icons\\INV_Gizmo_03")
Speed("spd_st",       "Temple Run",      "Sunken Temple",  "Shade of Eranikus",        5709,  35, R.EPIC, "Interface\\Icons\\Spell_Nature_WispSplode")

----------------------------------------------------------------------
-- More named rares (matched by name)
----------------------------------------------------------------------
local function Rare(id, name, mob, rarity, icon)
    A{
        id = id, name = name,
        description = "Hunt down the rare creature " .. mob .. ".",
        category = "RARES", subcategory = "Named Rares",
        rarity = rarity, trigger = "KILL", icon = icon,
        conditions = { mobNames = { mob } },
    }
end

Rare("rare_gnarl",      "Timber!",         "Gnarl Leafbrother",        R.COMMON, "Interface\\Icons\\Spell_Nature_Thorns")
Rare("rare_cliffjumper","Old Cliff Jumper","Old Cliff Jumper",         R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Cat")
Rare("rare_mithrethis", "Arcane Anomaly",  "Mith'rethis the Enchanter",R.RARE,   "Interface\\Icons\\Spell_Holy_MagicalSentry")
Rare("rare_reak",       "The Reak",        "The Reak",                 R.COMMON, "Interface\\Icons\\Ability_Hunter_Pet_Raptor")
Rare("rare_vagash",     "Beast of Dun Morogh", "Vagash",               R.COMMON, "Interface\\Icons\\Ability_Druid_Bash")
Rare("rare_deathflayer","Death Flayer",    "Death Flayer",             R.RARE,   "Interface\\Icons\\Ability_Gouge")

----------------------------------------------------------------------
-- More reputations
----------------------------------------------------------------------
local function Exalted(id, title, faction, rarity, icon)
    A{
        id = id, name = title,
        description = "Reach Exalted with " .. faction .. ".",
        category = "REPUTATION", subcategory = "Exalted",
        rarity = rarity, trigger = "REP",
        progressType = P.PROGRESS, target = EXALTED,
        icon = icon,
        conditions = { faction = faction, standing = EXALTED },
    }
end

Exalted("rep_stormpike", "Defender of the Vale", "Stormpike Guard", R.EPIC,      "Interface\\Icons\\INV_BannerPVP_02")
Exalted("rep_frostwolf", "For the Frostwolf",    "Frostwolf Clan",  R.EPIC,      "Interface\\Icons\\INV_BannerPVP_01")
Exalted("rep_ravenholdt","Master Assassin",      "Ravenholdt",      R.LEGENDARY, "Interface\\Icons\\Ability_Rogue_Eviscerate")

----------------------------------------------------------------------
-- More exploration
----------------------------------------------------------------------
-- SEALED secret - see Core/Util.lua; the plaintext lives outside the repo.
A{
    id = "explore_oldironforge", name = "Hidden Achievement", description = "",
    teaser = "Beneath the Mountain",
    teaserDesc = "The king sits above. History sleeps below.",
    category = "EXPLORATION", subcategory = "Hidden",
    rarity = R.RARE, trigger = "EXPLORE", hidden = true,
    sealed = "95ef85e04fbfccce616fcce6237a0642ee9e139ceef440bca503d19cc886b949f515a691624199068c80f358b45f7a2c71c806e5f9f7776121e377255e788db56e12b878cb0dad6ce37abd32d9d24b16bda31b3a90e42c38dd3e4ce9f3624a38ade2",
    conditions = {
        matchers = { { h = "00dd00cf", w = "86deee479e7adf2e6b174fad0bf32597" } },
    },
}

A{
    id = "explore_fireplume", name = "Into the Crater",
    description = "Stand atop Fire Plume Ridge in the heart of Un'Goro Crater.",
    category = "EXPLORATION", subcategory = "Hidden",
    rarity = R.COMMON, trigger = "EXPLORE",
    icon = "Interface\\Icons\\Spell_Fire_Volcano",
    conditions = { zones = { "Fire Plume Ridge" } },
}

----------------------------------------------------------------------
-- New Sagas (meta titles), reusing existing achievement IDs
----------------------------------------------------------------------
A{
    id = "saga_kalimdor", name = "Warden of Kalimdor",
    description = "Complete the Barrens, Mulgore, and Kalimdor Shores Sagas, hunt down Maraudos, and clear Zul'Farrak.",
    category = "SERIES", subcategory = "Continental",
    rarity = R.EPIC, trigger = "META",
    icon = "Interface\\Icons\\INV_Misc_Map02",
    title = { text = "Warden of Kalimdor", rarity = R.EPIC },
    requires = { "saga_barrens", "saga_mulgore", "saga_teldrassil", "eq_maraudos", "dn_zf" },
}

A{
    id = "series_diplomat", name = "Friend to All",
    description = "Reach Exalted with the Timbermaw, Argent Dawn, Thorium Brotherhood, Hydraxian Waterlords, and Cenarion Circle.",
    category = "SERIES", subcategory = "Mastery",
    rarity = R.EPIC, trigger = "META",
    icon = "Interface\\Icons\\INV_Jewelry_Necklace_07",
    title = { text = "the Diplomat", rarity = R.EPIC },
    requires = { "rep_timbermaw", "rep_argentdawn", "rep_thorium", "rep_hydraxian", "rep_cenarion" },
}
