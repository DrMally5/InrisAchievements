--[[--------------------------------------------------------------------------
    Inri's Achievements! - Professions

    Reaching Artisan (300) in a Classic profession is a real time investment.
    Progress bars track live skill rank via the SKILL trigger.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R, P = ns.RegisterAchievement, ns.RARITY, ns.PROGRESS

-- Helper for an "Artisan" profession achievement.
local function Artisan(id, title, skill, rarity, icon)
    A{
        id = id, name = title,
        description = "Reach 300 skill in " .. skill .. ".",
        category = "PROFESSIONS", subcategory = "Artisan",
        rarity = rarity, trigger = "SKILL",
        progressType = P.PROGRESS, target = 300,
        icon = icon,
        conditions = { skill = skill, rank = 300 },
    }
end

Artisan("prof_mining",       "Veins of Azeroth",   "Mining",        R.RARE, "Interface\\Icons\\Trade_Mining")
Artisan("prof_herbalism",    "Green Thumb",        "Herbalism",     R.RARE, "Interface\\Icons\\Trade_Herbalism")
Artisan("prof_skinning",     "Master Skinner",     "Skinning",      R.RARE, "Interface\\Icons\\INV_Misc_Pelt_Wolf_01")
Artisan("prof_blacksmithing","Master Blacksmith",  "Blacksmithing", R.EPIC, "Interface\\Icons\\Trade_BlackSmithing")
Artisan("prof_leatherworking","Master Leatherworker","Leatherworking", R.EPIC, "Interface\\Icons\\Trade_LeatherWorking")
Artisan("prof_tailoring",    "Master Tailor",      "Tailoring",     R.EPIC, "Interface\\Icons\\Trade_Tailoring")
Artisan("prof_engineering",  "Master Engineer",    "Engineering",   R.EPIC, "Interface\\Icons\\Trade_Engineering")
Artisan("prof_alchemy",      "Master Alchemist",   "Alchemy",       R.EPIC, "Interface\\Icons\\Trade_Alchemy")
Artisan("prof_enchanting",   "Master Enchanter",   "Enchanting",    R.EPIC, "Interface\\Icons\\Trade_Engraving")

----------------------------------------------------------------------
-- Secondary skills
----------------------------------------------------------------------
Artisan("prof_cooking",  "Iron Chef",    "Cooking",  R.RARE, "Interface\\Icons\\INV_Misc_Food_15")
Artisan("prof_firstaid", "Field Medic",  "First Aid", R.RARE, "Interface\\Icons\\Spell_Holy_SealOfSacrifice")
Artisan("prof_fishing",  "Master Angler","Fishing",  R.RARE, "Interface\\Icons\\Trade_Fishing")
