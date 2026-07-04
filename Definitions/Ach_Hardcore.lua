--[[--------------------------------------------------------------------------
    Inri's Achievements! - Feats of Survival (Hardcore)

    Deathless leveling milestones. "Deaths" are counted by the addon from the
    moment it is installed, so these are most meaningful on a fresh character.
    The LEVEL trigger checks the running death count via the `noDeaths` flag.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

local function Deathless(id, level, title, rarity, icon, wearable)
    A{
        id = id, name = title,
        description = "Reach level " .. level .. " without dying once.",
        category = "HARDCORE", subcategory = "Deathless",
        rarity = rarity, trigger = "LEVEL", icon = icon,
        conditions = { level = level, noDeaths = true },
        -- The capstone grants the most prestigious title in the addon.
        title = wearable and { text = wearable, rarity = rarity } or nil,
    }
end

Deathless("hc_deathless_20", 20, "Untouchable",      R.COMMON,    "Interface\\Icons\\Ability_Rogue_FeignDeath")
Deathless("hc_deathless_30", 30, "Still Standing",   R.RARE,      "Interface\\Icons\\Spell_Holy_Restoration")
Deathless("hc_deathless_40", 40, "Charmed Life",     R.EPIC,      "Interface\\Icons\\Spell_Holy_SealOfProtection")
Deathless("hc_deathless_50", 50, "Cheating Death",   R.EPIC,      "Interface\\Icons\\Ability_Rogue_Sprint")
Deathless("hc_deathless_60", 60, "The Immortal",     R.LEGENDARY, "Interface\\Icons\\Spell_Holy_Aspiration", "the Immortal")

----------------------------------------------------------------------
-- Self-sufficiency
----------------------------------------------------------------------
A{
    id = "hc_self_sufficient", name = "Self-Made Hero",
    description = "Reach level 60 with maxed Cooking and First Aid - bandage your own wounds, cook your own meals.",
    category = "HARDCORE", subcategory = "Self-Sufficient",
    rarity = R.EPIC, trigger = "META",
    icon = "Interface\\Icons\\INV_Misc_Food_15",
    requires = { "level_60", "prof_firstaid", "prof_cooking" },
}
