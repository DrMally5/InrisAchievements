--[[--------------------------------------------------------------------------
    Inri's Achievements! - Speed Runs

    Dungeon speed-clears, like a Hardcore-addon timer turned into achievements.
    The instance clock (Core\Events.lua) starts when you zone into a dungeon;
    the boss kill must land within `maxSeconds`. Reloading inside an instance
    restarts the clock, so these are honest "fresh entry to kill" times.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

-- Helper: clear <boss> within <minutes> of entering the dungeon.
local function Speed(id, name, dungeon, boss, npcID, minutes, rarity, icon)
    A{
        id = id, name = name,
        description = string.format("Defeat %s within %d minutes of entering %s.",
            boss, minutes, dungeon),
        category = "SPEEDRUN", subcategory = dungeon,
        rarity = rarity, trigger = "KILL", icon = icon,
        conditions = {
            mobNames = { boss }, npcIDs = npcID and { npcID } or nil,
            maxSeconds = minutes * 60,
        },
    }
end

Speed("spd_stockade",  "Jailbreak",        "The Stockade",     "Bazil Thredd",            1716,  12, R.COMMON, "Interface\\Icons\\INV_Misc_PocketWatch_02")
Speed("spd_deadmines", "Express Delivery", "The Deadmines",    "Edwin VanCleef",          644,   20, R.RARE,   "Interface\\Icons\\INV_Sword_24")
Speed("spd_sfk",       "Worgen Rush",      "Shadowfang Keep",  "Archmage Arugal",         4275,  18, R.RARE,   "Interface\\Icons\\Spell_Shadow_ShadowWordPain")
Speed("spd_sm_cath",   "Holy Hurry",       "Scarlet Monastery","High Inquisitor Whitemane", 3977, 18, R.RARE,  "Interface\\Icons\\Spell_Holy_HolySmite")
Speed("spd_zf",        "Pyramid Scheme",   "Zul'Farrak",       "Chief Ukorz Sandscalp",   7267,  25, R.EPIC,   "Interface\\Icons\\INV_Sword_48")
Speed("spd_strat",     "Rivendare's Reckoning", "Stratholme",  "Baron Rivendare",         10440, 40, R.EPIC,   "Interface\\Icons\\Ability_Mount_Dreadsteed")
Speed("spd_scholo",    "Detention Dash",   "Scholomance",      "Darkmaster Gandling",     1853,  40, R.EPIC,   "Interface\\Icons\\Spell_Shadow_DeathCoil")
Speed("spd_brd",       "Smash and Grab",   "Blackrock Depths", "Emperor Dagran Thaurissan", 9019, 50, R.EPIC,  "Interface\\Icons\\Spell_Fire_Incinerate")

----------------------------------------------------------------------
-- Speed leveling (uses real /played time, like the Hardcore addon's timer)
----------------------------------------------------------------------
local function HumanTime(minutes)
    if minutes < 60 then return minutes .. " minutes" end
    local hrs = minutes / 60
    if hrs == math.floor(hrs) then return hrs .. " hours" end
    return string.format("%.1f hours", hrs)
end

local function SpeedLevel(id, name, level, minutes, rarity)
    A{
        id = id, name = name,
        description = string.format("Reach level %d in under %s of /played time.",
            level, HumanTime(minutes)),
        category = "SPEEDRUN", subcategory = "Speed Leveling",
        rarity = rarity, trigger = "TIMED_LEVEL",
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        conditions = { level = level, maxMinutes = minutes },
    }
end

SpeedLevel("spl_10", "Quick Study",    10, 120,  R.RARE)       -- 2h
SpeedLevel("spl_20", "Fast Track",     20, 360,  R.RARE)       -- 6h
SpeedLevel("spl_30", "On the Clock",   30, 720,  R.EPIC)       -- 12h
SpeedLevel("spl_40", "Need for Speed", 40, 1440, R.EPIC)       -- 24h
SpeedLevel("spl_50", "Blink of an Eye",50, 2400, R.EPIC)       -- 40h
SpeedLevel("spl_60", "Realm Pace",     60, 4320, R.LEGENDARY)  -- 72h

----------------------------------------------------------------------
-- Meta
----------------------------------------------------------------------
A{
    id = "spd_master", name = "Speed Demon",
    description = "Earn every low- and mid-level Speed Run achievement.",
    category = "SPEEDRUN", subcategory = "Mastery",
    rarity = R.LEGENDARY, trigger = "META",
    icon = "Interface\\Icons\\Ability_Rogue_Sprint",
    title = { text = "the Swift", rarity = R.LEGENDARY },
    requires = { "spd_stockade", "spd_deadmines", "spd_sfk", "spd_sm_cath", "spd_zf" },
}
