--[[--------------------------------------------------------------------------
    Inri's Achievements! - Hidden

    Secret achievements. Their real name, description, and icon ship SEALED
    (encrypted) so reading this file spoils nothing - see Core/Util.lua for
    the scheme. Mechanic conditions (counts, thresholds) must stay readable
    to be evaluatable; the flavor is what stays secret. Each unseals the
    moment somebody earns it, and the discovery broadcast unmasks it for
    everyone in earshot, with the finder credited forever.

    No hand-holding - players stumble into these.
----------------------------------------------------------------------------]]

local _, ns = ...
local A, R = ns.RegisterAchievement, ns.RARITY

A{
    id = "hidden_leeroy", name = "Hidden Achievement", description = "",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "KILLSTREAK", hidden = true,
    title = { rarity = R.EPIC },
    sealed = "95e411345e9d22e3e331c14a86264a00a6781d56347a9bcf9ffa7fd3ca76a79072aad1d2d2106756c6bea6ee1cad8bec9ab23f37c231e28d200ba78d14e2aa621aa38caf7548b3d5f15d7588b435b3610865c9ed1010423b39c2c2281015ae0f5c7e21981eee76d1aa8a8f22abb0c2a6be8ffa7ee16428262b0180f1717e6eb83c603d",
    conditions = { count = 8 },
}

A{
    id = "hidden_lowbie_hero", name = "Hidden Achievement", description = "",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "KILL", hidden = true,
    sealed = "42b427e9388298cc2993265f9b310e0789fe41841c3797377df325f1b9b6864e40e59778d8533add915dc8d563472d330c340cfd52a1c544cbc5bbc6d1015f7fbce4f1bb042833f0fd23be1d921ae75fc2dc3f2811108dbe6bc5861838fd8b3d5cee438365d3753b591d938e13a32018267d7d9d790d2706",
    conditions = { minLevelAbove = 10, maxPlayerLevel = 9 },
}

A{
    id = "hidden_points_500", name = "Hidden Achievement", description = "",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.RARE, trigger = "POINTS", hidden = true,
    sealed = "113a4a3169595be26588d0b2091d6394c7036485b61c88d29777579b07dbd1b3b6493745720c83b5d0ae54a9cea335ada247f9c6fea7d968a907a991980ec59070e47122be77a82e56d51e40cf9bf529b28a",
    conditions = { points = 500 },
}

A{
    id = "hidden_points_1000", name = "Hidden Achievement", description = "",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.EPIC, trigger = "POINTS", hidden = true,
    title = { rarity = R.EPIC },
    sealed = "0b2d35185db771dbd1e23c277e804f8808e0d8c303c81a849085b7197186a177424a42e326da2fe994601b3e4f5b411b4cc4c15c74f0a47bcb89ac0bc7cd49ce3c29485a0834d199938ab0a74c68f788410d8c4cb177ea778bd8c0c20de4b00036673c0d98de9f85b586729781",
    conditions = { points = 1000 },
}

A{
    id = "hidden_time_sand", name = "Hidden Achievement", description = "",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.RARE, trigger = "META", hidden = true,
    sealed = "f8cce87b7bd16a1fccb97e85d5978964f4731a4ddb30e8728832f199caea63dc71c8fcdf86950d0eaf3fdba977fcd03ea72fd79c9021a41acd71139aa9171063e69300caea86a3cb995358ddc8376d7da925ba8550cf3341f5bdf3ae3e4ce4f289b476c036",
    requires = { "explore_landsend", "explore_uldum" },
}

-- Only one account in the world can earn this one. Not sealed: its existence
-- IS the flavor, and its trigger cannot be replicated.
A{
    id = "hidden_creator", name = "Make This Addon",
    description = "Build Inri's Achievements! from nothing. There is exactly one way to earn this.",
    category = "HIDDEN", subcategory = "Secrets",
    rarity = R.LEGENDARY, trigger = "CREATOR", hidden = true,
    icon = "Interface\\Icons\\INV_Misc_Gear_01",
    title = { text = "the Creator", rarity = R.LEGENDARY },
}
