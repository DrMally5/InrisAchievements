--[[--------------------------------------------------------------------------
    Inri's Achievements! - Boss Feats ("The Hard Way")

    Dungeon end-bosses defeated the hard way: alone. SOLO kills run through the
    same fairness gate as every other kill (an outside player's damage or heals
    void the attempt), so these are honest one-versus-boss trophies - whether
    earned on-level as a daring lowbie or as a level-60 flexing on old content.

    Names are matched exactly; npcIDs are a bonus matcher (marked VERIFY where
    recalled from memory - a wrong ID never causes a false unlock, the name
    still carries it).

    Filed under the Dungeons tab.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

local function Solo(id, name, boss, npcID, rarity, icon)
    A{
        id = id, name = name,
        description = "Defeat " .. boss .. " with no one at your side.",
        category = "DUNGEONS", subcategory = "The Hard Way",
        rarity = rarity, trigger = "KILL", icon = icon,
        conditions = { mobNames = { boss }, npcIDs = { npcID }, solo = true },
    }
end

Solo("solo_vancleef",   "One-Man Wrecking Crew", "Edwin VanCleef",           644,  R.RARE,
    "Interface\\Icons\\INV_Sword_27")
Solo("solo_herod",      "Champion No More",      "Herod",                    3975, R.RARE,
    "Interface\\Icons\\Ability_Warrior_Cleave")           -- VERIFY npc
Solo("solo_arugal",     "The Wolf's Master",     "Archmage Arugal",          4275, R.RARE,
    "Interface\\Icons\\Spell_Shadow_ShadowWordDominate")  -- VERIFY npc
Solo("solo_mutanus",    "Alone in the Deep",     "Mutanus the Devourer",     3654, R.RARE,
    "Interface\\Icons\\Ability_Racial_Cannibalize")       -- VERIFY npc
Solo("solo_thermaplugg","One-Gnome Army",        "Mekgineer Thermaplugg",    7800, R.EPIC,
    "Interface\\Icons\\INV_Gizmo_02")                     -- VERIFY npc
Solo("solo_emperor",    "Regicide, Party of One","Emperor Dagran Thaurissan",9019, R.EPIC,
    "Interface\\Icons\\INV_Crown_01")                     -- VERIFY npc
