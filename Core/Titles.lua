--[[--------------------------------------------------------------------------
    Inri's Achievements! - Titles

    Classic Era addons cannot grant real Blizzard titles, but we can grant
    *addon* titles that anyone else running Inri's Achievements! sees on your
    tooltip and inspect profile - which is arguably better, since we aren't
    limited to Blizzard's list.

    A title is declared on the achievement that grants it:
        title = { text = "The Defias Nemesis", rarity = R.EPIC }
    Unlocking is implicit: complete the achievement, unlock the title. The
    player chooses which unlocked title to display (stored as the granting
    achievement's id). Title rarity drives its colour, exactly like an
    achievement's rarity, so an orange title signals something extraordinary.
----------------------------------------------------------------------------]]

local _, ns = ...

local Titles = {}
ns.Titles = Titles

----------------------------------------------------------------------
-- Index of every title-granting achievement (built once, lazily).
----------------------------------------------------------------------
function Titles:Index()
    if self._index then return self._index end
    local t = {}
    for _, def in ipairs(ns.Achievements) do
        if def.title and def.title.text then t[#t + 1] = def end
    end
    self._index = t
    return t
end

-- Resolve a title's rarity (falls back to the achievement's own rarity).
local function TitleRarity(def)
    return def.title.rarity or def.rarity
end

----------------------------------------------------------------------
-- How a title attaches after a character's name:
--   "the ..." and single-word titles join with a space
--       -> "Inrii the Archmage", "Inrii Leeroy"
--   formal appellations join with a comma (Blizzard's own convention)
--       -> "Inrii, Hero of Westfall"
----------------------------------------------------------------------
function Titles.SuffixText(text)
    if text:find("^the ") or not text:find(" ") then
        return " " .. text
    end
    return ", " .. text
end

----------------------------------------------------------------------
-- Queries
----------------------------------------------------------------------
-- The creator-only title, if this account is the author's; else nil.
local function CreatorEntry()
    if ns.IsCreator and ns.IsCreator() then
        local c = ns.CREATOR_TITLE
        return { id = c.id, text = c.text, rarity = c.rarity }
    end
    return nil
end

function Titles:GetUnlocked()
    local out = {}
    local creator = CreatorEntry()
    if creator then out[#out + 1] = creator end
    for _, def in ipairs(self:Index()) do
        if ns.DB:IsCompleted(def.id) then
            out[#out + 1] = { id = def.id, text = def.title.text, rarity = TitleRarity(def) }
        end
    end
    table.sort(out, function(a, b)
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.text < b.text
    end)
    return out
end

function Titles:GetActive()
    local id = ns.DB:GetActiveTitleID()
    if not id then return nil end
    if id == ns.CREATOR_TITLE.id then
        return CreatorEntry()   -- nil if this isn't the creator's account
    end
    local def = ns.GetAchievement(id)
    if not def or not def.title or not ns.DB:IsCompleted(id) then return nil end
    return { id = id, text = def.title.text, rarity = TitleRarity(def) }
end

----------------------------------------------------------------------
-- Mutation
----------------------------------------------------------------------
function Titles:SetActive(id)
    if id == nil then
        ns.DB:SetActiveTitleID(nil)
    elseif id == ns.CREATOR_TITLE.id then
        if not (ns.IsCreator and ns.IsCreator()) then return false end
        ns.DB:SetActiveTitleID(id)
    else
        local def = ns.GetAchievement(id)
        if def and def.title and ns.DB:IsCompleted(id) then
            ns.DB:SetActiveTitleID(id)
        else
            return false
        end
    end
    -- Tell peers our title changed so their tooltips update.
    if ns.Comm then ns.Comm:BroadcastSummary(true) end
    if ns.TitlesUI then ns.TitlesUI:Refresh() end
    return true
end

-- Equip by display text (used by the slash command). Returns the text or nil.
function Titles:SetActiveByText(text)
    if not text or text == "" then return nil end
    local low = text:lower()
    for _, def in ipairs(self:Index()) do
        if ns.DB:IsCompleted(def.id) and def.title.text:lower() == low then
            self:SetActive(def.id)
            return def.title.text
        end
    end
    return nil
end

----------------------------------------------------------------------
-- Auto-equip the first title a player ever unlocks, so the feature is
-- visible without them having to hunt for the picker.
----------------------------------------------------------------------
ns.Engine:RegisterCallback("COMPLETED", function(id, def)
    if def.title and def.title.text and not ns.Titles:GetActive() then
        ns.Titles:SetActive(id)
    end
end)
