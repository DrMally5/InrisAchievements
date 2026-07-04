--[[--------------------------------------------------------------------------
    Inri's Achievements! - Sagas (Meta Chains)

    The real endgame. Each Saga is a META achievement that completes only when
    every step in the chain is done, and each grants an addon TITLE coloured by
    its rarity. Sagas reuse achievement IDs from across the database, so the
    chains stay DRY - a leaf kill counts toward its zone Saga, the continental
    Saga, and the grand finale all at once.

    Structure:
        Zone Sagas      -> Defender of Elwynn, Hero of Westfall, ...
        Named Sagas     -> The Defias Nemesis, Master Hunter, Dragonslayer, ...
        Continental     -> Champion of the Eastern Kingdoms
        Grand finale    -> Legend of Azeroth
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

-- Helper: a Saga is a META achievement that grants a same-coloured title.
local function Saga(id, name, titleText, rarity, requires, icon, sub, desc)
    A{
        id = id, name = name,
        description = desc,
        category = "SERIES", subcategory = sub,
        rarity = rarity, trigger = "META", icon = icon,
        requires = requires,
        title = { text = titleText, rarity = rarity },
    }
end

----------------------------------------------------------------------
-- Zone Sagas
----------------------------------------------------------------------
Saga("saga_elwynn", "Defender of Elwynn", "Defender of Elwynn", R.RARE,
    { "hogger_early", "mother_fang", "leg_bellygrub", "leg_gruff", "leg_garrick" },
    "Interface\\Icons\\Spell_Holy_AuraMastery", "Zone Sagas",
    "Protect Elwynn Forest: defeat Hogger, Mother Fang, Bellygrub, Gruff Swiftbite, and Garrick Padfoot.")

Saga("saga_westfall", "Hero of Westfall", "Hero of Westfall", R.RARE,
    { "foe_reaper", "leg_collector", "leg_murkeye", "leg_goldtooth", "dn_deadmines" },
    "Interface\\Icons\\INV_Misc_Cape_01", "Zone Sagas",
    "Save Westfall: destroy the Foe Reaper, The Collector, Old Murk-Eye, Goldtooth, and clear the Deadmines.")

Saga("saga_duskwood", "The Dusk Stalker", "The Dusk Stalker", R.RARE,
    { "morladim", "stitches", "eliza", "rare_lupos", "rare_krethis" },
    "Interface\\Icons\\Spell_Shadow_Possession", "Zone Sagas",
    "Cleanse Duskwood: lay Mor'Ladim, Stitches, Eliza, Lupos, and Krethis Shadowspinner to rest.")

Saga("saga_stranglethorn", "The Jungle King", "The Jungle King", R.RARE,
    { "leg_bangalash", "leg_mukla", "eq_mokk", "eq_ganzulah" },
    "Interface\\Icons\\Ability_Hunter_Pet_Cat", "Zone Sagas",
    "Conquer Stranglethorn: slay King Bangalash, King Mukla, Mokk the Savage, and Gan'zulah.")

----------------------------------------------------------------------
-- Named Sagas
----------------------------------------------------------------------
Saga("series_defias", "The Defias Nemesis", "The Defias Nemesis", R.EPIC,
    { "leg_goldtooth", "leg_garrick", "hogger_early", "leg_collector", "dn_deadmines" },
    "Interface\\Icons\\INV_Misc_Bandana_03", "Named Sagas",
    "Dismantle the Defias Brotherhood from Goldtooth and Garrick Padfoot all the way to Edwin VanCleef.")

Saga("series_scarlet", "The Scarlet Executioner", "The Scarlet Executioner", R.EPIC,
    { "leg_loksey", "leg_doan", "leg_herod", "leg_mograine", "dn_sm" },
    "Interface\\Icons\\Spell_Holy_HolySmite", "Named Sagas",
    "Sweep every wing of the Scarlet Monastery: Houndmaster Loksey, Arcanist Doan, Herod, Commander Mograine, and High Inquisitor Whitemane.")

Saga("series_hunter", "Master Hunter", "Master Hunter", R.EPIC,
    { "leg_bangalash", "leg_mukla", "leg_kingmosh", "leg_murkeye", "leg_bellygrub", "leg_arugalson" },
    "Interface\\Icons\\Ability_Hunter_RunningShot", "Named Sagas",
    "Hunt the great beasts of Azeroth: Bangalash, Mukla, King Mosh, Old Murk-Eye, Bellygrub, and the Son of Arugal.")

Saga("series_dragons", "Dragonslayer", "The Dragonslayer", R.LEGENDARY,
    { "leg_onyxia", "leg_azuregos", "leg_nefarian", "leg_ysondre", "leg_lethon", "leg_emeriss", "leg_taerar" },
    "Interface\\Icons\\INV_Misc_Head_Dragon_Black", "Named Sagas",
    "Slay every great dragon: Onyxia, Azuregos, Nefarian, and the four Emerald Dreamers.")

----------------------------------------------------------------------
-- Continental
----------------------------------------------------------------------
Saga("series_ek_champion", "Champion of the Eastern Kingdoms", "Champion of the Eastern Kingdoms", R.EPIC,
    { "saga_elwynn", "saga_westfall", "saga_duskwood", "saga_stranglethorn",
      "saga_forsaken", "saga_khazmodan" },
    "Interface\\Icons\\INV_Misc_Map_01", "Continental",
    "Complete every Eastern Kingdoms zone Saga, from Elwynn to Khaz Modan to the Forsaken lands.")

----------------------------------------------------------------------
-- Grand finale - only a handful on a server will ever wear this title.
----------------------------------------------------------------------
Saga("series_legends", "Legends Never Die", "Legend of Azeroth", R.LEGENDARY,
    {
        "series_hunter", "series_dragons",
        "leg_ragnaros", "leg_kazzak", "leg_cthun", "leg_kelthuzad",
        "dn_strat", "dn_ubrs", "dn_maraudon",
    },
    "Interface\\Icons\\INV_Sword_39", "Grand Finale",
    "Defeat the Hunter and Dragon Sagas, the great raid lords, and Azeroth's most fearsome dungeon masters. A living legend.")
