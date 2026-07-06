--[[--------------------------------------------------------------------------
    Inri's Achievements! - Utilities

    Stateless helpers: printing, colour, formatting, GUID parsing, lightweight
    serialization for the network layer. No module should reimplement these.
----------------------------------------------------------------------------]]

local _, ns = ...
local L = ns.L

local Util = {}
ns.Util = Util

local CHAT_PREFIX = "|cff00ff96[Inri]|r "

----------------------------------------------------------------------
-- Output
----------------------------------------------------------------------
function Util.Print(...)
    local msg = ""
    for i = 1, select("#", ...) do
        msg = msg .. tostring((select(i, ...)))
        if i < select("#", ...) then msg = msg .. " " end
    end
    DEFAULT_CHAT_FRAME:AddMessage(CHAT_PREFIX .. msg)
end

-- Wrap text in a colour. Accepts a {r,g,b} table (0-1) or a 6-char hex string.
function Util.Colorize(text, color)
    if type(color) == "table" then
        return string.format("|cff%02x%02x%02x%s|r",
            math.floor((color[1] or 1) * 255 + 0.5),
            math.floor((color[2] or 1) * 255 + 0.5),
            math.floor((color[3] or 1) * 255 + 0.5), text)
    end
    return "|cff" .. (color or "ffffff") .. text .. "|r"
end

----------------------------------------------------------------------
-- Rarity helpers
----------------------------------------------------------------------
function Util.RarityInfo(rarity)
    return ns.RARITY_INFO[rarity] or ns.RARITY_INFO[ns.RARITY.COMMON]
end

function Util.RarityName(rarity)
    return L[Util.RarityInfo(rarity).locKey]
end

function Util.RarityPoints(rarity)
    return Util.RarityInfo(rarity).points
end

function Util.RarityColor(rarity)
    return Util.RarityInfo(rarity).color
end

----------------------------------------------------------------------
-- GUID / unit parsing
----------------------------------------------------------------------
-- Creature/Vehicle/Pet GUIDs look like:  Creature-0-1234-56-78-NPCID-spawnUID
-- Returns the numeric NPC ID or nil for player GUIDs.
function Util.NpcIDFromGUID(guid)
    if not guid then return nil end
    local kind, _, _, _, _, npcID = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" or kind == "Pet" then
        return tonumber(npcID)
    end
    return nil
end

-- "Name-Realm" key for the current player (realm spaces stripped, matching how
-- Blizzard composes cross-realm GUIDs and how we key the roster cache).
function Util.PlayerKey()
    local name = UnitName("player")
    local realm = GetRealmName() or ""
    realm = realm:gsub("%s+", "")
    return name .. "-" .. realm, name, realm
end

-- Normalise an arbitrary "Name" or "Name-Realm" into our roster key form.
function Util.NormalizeName(name, realm)
    if not name then return nil end
    if name:find("-") then
        local n, r = strsplit("-", name)
        return n .. "-" .. (r:gsub("%s+", ""))
    end
    realm = (realm or GetRealmName() or ""):gsub("%s+", "")
    return name .. "-" .. realm
end

----------------------------------------------------------------------
-- Formatting
----------------------------------------------------------------------
function Util.FormatDate(ts)
    if not ts then return "" end
    return date("%b %d, %Y", ts)
end

-- "3 / 10" style fraction for counter/progress bars.
function Util.FormatFraction(cur, max)
    return string.format("%d / %d", cur or 0, max or 0)
end

function Util.ClassColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class:upper()]
    if c then return { c.r, c.g, c.b } end
    return { 1, 1, 1 }
end

----------------------------------------------------------------------
-- Simple string hash (djb2, hex). Lets the addon recognise the creator's
-- Battle.net tag without shipping the tag itself in the public code.
----------------------------------------------------------------------
function Util.HashString(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + s:byte(i)) % 4294967296
    end
    return string.format("%08x", h)
end

----------------------------------------------------------------------
-- Sealed secrets (hidden achievements)
--
-- Hidden achievements ship with their name/description/icon encrypted
-- ("sealed") so reading the source doesn't spoil them. The decode key is the
-- secret itself (the zone or mob name that triggers it) - unwrapped the
-- moment someone actually does the thing - or a static per-id key for
-- mechanic-based secrets whose conditions must stay readable.
-- Mirrored exactly by the build-time sealer (kept outside the repo).
----------------------------------------------------------------------
local function Djb2(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return h
end

-- Park-Miller keystream: stays within 2^53 double precision, so Lua and the
-- Python sealer produce identical bytes.
local function SealStream(key, n)
    local s = (Djb2(key) % 2147483646) + 1
    local out = {}
    for i = 1, n do
        s = (s * 16807) % 2147483647
        out[i] = math.floor(s / 128) % 256
    end
    return out
end

-- XOR a hex blob with the keystream for `key`; returns the raw string.
function Util.SealXor(hex, key)
    if type(hex) ~= "string" or #hex % 2 ~= 0 or type(key) ~= "string" then return nil end
    local n = #hex / 2
    local ks = SealStream(key, n)
    local out = {}
    for i = 1, n do
        local b = tonumber(hex:sub(i * 2 - 1, i * 2), 16)
        if not b then return nil end
        out[i] = string.char(bit.bxor(b, ks[i]))
    end
    return table.concat(out)
end

-- Decode a sealed def with `key`. Fills in the real name/description/icon
-- (and title text) on success. Wrong keys fail the magic-prefix check.
function ns.RevealHidden(def, key)
    if not def or not def.sealed then return false end
    if def.revealed then return true end
    if not key or key == "" then return false end
    local plain = Util.SealXor(def.sealed, key)
    if not plain or plain:sub(1, 4) ~= "IA1\31" then return false end
    local name, desc, icon, titleText = strsplit("\31", plain:sub(5))
    if not name or name == "" then return false end
    def.name, def.description = name, desc or ""
    if icon and icon ~= "" then def.icon = icon end
    if def.title and titleText and titleText ~= "" then def.title.text = titleText end
    def.revealed, def._sealK = true, key
    if ns.UI then ns.UI:Refresh() end
    return true
end

-- Try a carried key first (from a trigger match or a discovery broadcast),
-- then the static per-id key used by mechanic-based secrets.
function ns.TryRevealHidden(def, key)
    if not def or not def.sealed then return false end
    if def.revealed then return true end
    if key and ns.RevealHidden(def, key) then return true end
    return ns.RevealHidden(def, def.id .. "::InriSeal1")
end

----------------------------------------------------------------------
-- Table helpers
----------------------------------------------------------------------
function Util.Count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function Util.CopyShallow(t)
    local r = {}
    for k, v in pairs(t) do r[k] = v end
    return r
end

----------------------------------------------------------------------
-- Lightweight serialization for the comm layer.
-- We never transmit arbitrary tables; payloads are simple delimited strings.
-- These helpers keep delimiter choices in one spot.
----------------------------------------------------------------------
Util.FIELD_SEP = "\31"   -- unit separator: between fields of a message
Util.LIST_SEP  = ","     -- between IDs in a list

function Util.PackFields(...)
    return table.concat({ ... }, Util.FIELD_SEP)
end

function Util.UnpackFields(str)
    return strsplit(Util.FIELD_SEP, str)
end

-- Encode a sorted list of integer IDs as a comma string. Sorted so diffs and
-- chunk boundaries are stable across clients.
function Util.PackIDList(ids)
    table.sort(ids)
    return table.concat(ids, Util.LIST_SEP)
end

function Util.UnpackIDList(str)
    local out = {}
    if not str or str == "" then return out end
    for part in str:gmatch("[^,]+") do
        local n = tonumber(part)
        if n then out[#out + 1] = n end
    end
    return out
end
