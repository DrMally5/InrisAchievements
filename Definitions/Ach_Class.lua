--[[--------------------------------------------------------------------------
    Inri's Achievements! - Class

    Capstone achievements that only the matching class can earn (the engine
    gates progress on def.class). Reaching 60 on a given class in Classic is a
    real, class-specific badge of honour.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

-- { token, display name, achievement name, wearable title, icon }
-- Wearable titles carry a lowercase "the" so they read naturally after a
-- character name: "Inrii the Archmage".
local CLASSES = {
    { "WARRIOR", "Warrior", "Unstoppable Force",    "the Unstoppable Force",    "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
    { "PALADIN", "Paladin", "The Light's Champion", "the Light's Champion",     "Interface\\Icons\\Spell_Holy_AuraOfLight" },
    { "HUNTER",  "Hunter",  "Master Marksman",      "the Master Marksman",      "Interface\\Icons\\Ability_Hunter_RunningShot" },
    { "ROGUE",   "Rogue",   "Shadow of Azeroth",    "the Shadow of Azeroth",    "Interface\\Icons\\Ability_Stealth" },
    { "PRIEST",  "Priest",  "Keeper of the Faith",  "the Keeper of the Faith",  "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    { "SHAMAN",  "Shaman",  "Voice of the Elements","the Voice of the Elements","Interface\\Icons\\Spell_Nature_Lightning" },
    { "MAGE",    "Mage",    "Archmage",             "the Archmage",             "Interface\\Icons\\Spell_Frost_FrostBolt02" },
    { "WARLOCK", "Warlock", "Master of Demons",     "the Master of Demons",     "Interface\\Icons\\Spell_Shadow_Metamorphosis" },
    { "DRUID",   "Druid",   "Cycle of Life",        "the Evershifting",         "Interface\\Icons\\Ability_Druid_Maul" },
}

for _, c in ipairs(CLASSES) do
    local token, className, achName, wearable, icon = c[1], c[2], c[3], c[4], c[5]
    A{
        id = "class_60_" .. token:lower(),
        name = achName,
        description = "Reach level 60 as a " .. className .. ".",
        category = "CLASS", subcategory = className,
        rarity = R.RARE, trigger = "LEVEL",
        class = token, icon = icon,
        conditions = { level = 60 },
        -- Each capstone doubles as a wearable class title (balanced: one per class).
        title = { text = wearable, rarity = R.RARE },
    }
end

-- NOTE: deliberately exactly ONE achievement per class so the category stays
-- perfectly balanced. Add new class content in full sets of nine or not at all.
