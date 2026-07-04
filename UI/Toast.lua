--[[--------------------------------------------------------------------------
    Inri's Achievements! - Toast Notifications

    A polished, queued toast that pops in when an achievement is earned: dark
    bordered banner, rarity-tinted frame + accent bars, a glowing icon ring, a
    one-shot light "shine" sweep, then a hold and fade-out. One frame, processed
    from a FIFO queue so a burst of completions shows one at a time.
----------------------------------------------------------------------------]]

local _, ns = ...
local L    = ns.L
local Util = ns.Util

local Toast = {}
ns.Toast = Toast

local HOLD_TIME = 4.5
local WIDTH, HEIGHT = 360, 88
local queue = {}
local frame, inAnim, outAnim, shineFrame, shineAnim
local showing = false

----------------------------------------------------------------------
-- Build the toast frame and animations once, on first use.
----------------------------------------------------------------------
local function EnsureFrame()
    if frame then return end

    frame = CreateFrame("Frame", "InriAchievementToast", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    frame:SetFrameStrata("DIALOG")
    frame:SetAlpha(0)
    frame:EnableMouse(true)

    -- Classic dialog dressing: parchment + the thick ornate gold border, the
    -- same combo Blizzard's own Classic popups use.
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    -- The classic curved header ribbon overhanging the top, carrying the
    -- "Achievement Earned!" heading - unmistakably a Blizzard Classic dialog.
    frame.ribbon = frame:CreateTexture(nil, "OVERLAY")
    frame.ribbon:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    frame.ribbon:SetSize(300, 58)
    frame.ribbon:SetPoint("TOP", 0, 26)
    frame.heading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.heading:SetPoint("TOP", frame.ribbon, "TOP", 0, -13)
    frame.heading:SetTextColor(1, 0.82, 0)

    -- Icon + glowing rarity ring + metal frame.
    -- The icon block: icon centered in the metal slot ring, with Blizzard's
    -- soft rounded action-button glow (additive) tinted to the rarity - the
    -- same texture the game uses for equipped-item borders, so it reads as a
    -- glow rather than a flat colored square.
    -- Proportions mirror a real action button (icon 32 : slot 54 : glow 58,
    -- both ring textures carry big transparent margins). Crucially the glow
    -- draws OVER the slot ring with ADD blend - behind it, it's invisible.
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(32, 32)
    frame.icon:SetPoint("LEFT", 26, -2)
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- trim the default icon border

    -- Golden star-burst that flares behind the icon when the toast lands.
    frame.burst = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    frame.burst:SetTexture("Interface\\Cooldown\\star4")
    frame.burst:SetBlendMode("ADD")
    frame.burst:SetSize(84, 84)
    frame.burst:SetPoint("CENTER", frame.icon, "CENTER")
    frame.burst:SetAlpha(0)

    frame.iconFrame = frame:CreateTexture(nil, "OVERLAY", nil, 0)
    frame.iconFrame:SetSize(54, 54)
    frame.iconFrame:SetPoint("CENTER", frame.icon, "CENTER", 0, -1)
    frame.iconFrame:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    frame.iconGlow = frame:CreateTexture(nil, "OVERLAY", nil, 2)
    frame.iconGlow:SetSize(58, 58)
    frame.iconGlow:SetPoint("CENTER", frame.icon, "CENTER")
    frame.iconGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.iconGlow:SetBlendMode("ADD")

    -- Text (the heading lives on the ribbon above).
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 18, 10)
    frame.title:SetWidth(WIDTH - 120)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetWordWrap(true)

    frame.points = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.points:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)

    -- Shine sweep: a soft light bar that crosses the toast once. Lives in a
    -- clipping container so it never draws outside the frame (the ribbon must
    -- NOT be clipped, so the clip lives on this subframe, not the toast).
    local clip = CreateFrame("Frame", nil, frame)
    clip:SetPoint("TOPLEFT", 8, -8)
    clip:SetPoint("BOTTOMRIGHT", -8, 8)
    pcall(clip.SetClipsChildren, clip, true)

    shineFrame = CreateFrame("Frame", nil, clip)
    shineFrame:SetSize(40, HEIGHT)
    shineFrame:SetPoint("LEFT", frame, "LEFT", -50, 0)
    local shineTex = shineFrame:CreateTexture(nil, "OVERLAY")
    shineTex:SetAllPoints()
    shineTex:SetColorTexture(1, 1, 1, 0.18)
    shineTex:SetBlendMode("ADD")
    shineFrame:Hide()

    shineAnim = shineFrame:CreateAnimationGroup()
    local move = shineAnim:CreateAnimation("Translation")
    move:SetOffset(WIDTH + 70, 0)
    move:SetDuration(0.65)
    move:SetStartDelay(0.15)
    shineAnim:SetScript("OnFinished", function() shineFrame:Hide() end)

    -- Star-burst flare: fade in fast, spin slowly, fade out.
    frame.burstAnim = frame.burst:CreateAnimationGroup()
    local bIn = frame.burstAnim:CreateAnimation("Alpha")
    bIn:SetFromAlpha(0); bIn:SetToAlpha(0.9); bIn:SetDuration(0.20); bIn:SetOrder(1)
    pcall(function()
        local spin = frame.burstAnim:CreateAnimation("Rotation")
        spin:SetDegrees(45); spin:SetDuration(0.9); spin:SetOrder(1)
    end)
    local bOut = frame.burstAnim:CreateAnimation("Alpha")
    bOut:SetFromAlpha(0.9); bOut:SetToAlpha(0); bOut:SetDuration(0.6); bOut:SetOrder(2)
    frame.burstAnim:SetScript("OnFinished", function() frame.burst:SetAlpha(0) end)

    -- In / out fades (plus a subtle pop-in scale where the client supports it).
    inAnim = frame:CreateAnimationGroup()
    local fadeIn = inAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.40)
    pcall(function()
        local grow = inAnim:CreateAnimation("Scale")
        if grow.SetScaleFrom then
            grow:SetScaleFrom(0.85, 0.85); grow:SetScaleTo(1, 1)
        else
            grow:SetFromScale(0.85, 0.85); grow:SetToScale(1, 1)
        end
        grow:SetDuration(0.30)
        grow:SetSmoothing("OUT")
    end)
    inAnim:SetScript("OnFinished", function() frame:SetAlpha(1) end)

    outAnim = frame:CreateAnimationGroup()
    local fadeOut = outAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(0.6)
    outAnim:SetScript("OnFinished", function()
        frame:SetAlpha(0); frame:Hide()
        showing = false
        Toast:ProcessNext()
    end)

    frame:SetScript("OnMouseUp", function(self)
        if self.achID and ns.UI then ns.UI:OpenToAchievement(self.achID) end
    end)
end

----------------------------------------------------------------------
-- Sound
----------------------------------------------------------------------
-- NOTE: internal sound PATHS are ignored on the modern (1.15) client, so we
-- use sound-kit IDs via PlaySound. A definition may carry its own `sound`
-- (kit ID number, or a FileDataID/addon file for PlaySoundFile).
local function PlayToastSound(def)
    if not ns.DB:Settings().toastSound then return end

    if def.sound then
        if type(def.sound) == "number" then
            local ok, willPlay = pcall(PlaySound, def.sound, "Master")
            if ok and willPlay then return end
            ok, willPlay = pcall(PlaySoundFile, def.sound, "Master")
            if ok and willPlay then return end
        else
            local ok, willPlay = pcall(PlaySoundFile, def.sound, "Master")
            if ok and willPlay then return end
        end
        -- fall through to the defaults if the custom sound didn't play
    end

    local kit = ns.SOUND.TOAST
    if def.hidden then kit = ns.SOUND.HIDDEN
    elseif (def.rarity or 1) >= ns.RARITY.LEGENDARY then kit = ns.SOUND.LEGENDARY end
    pcall(PlaySound, kit, "Master")
end

----------------------------------------------------------------------
-- Render one achievement.
----------------------------------------------------------------------
local function Render(def)
    EnsureFrame()
    local c = Util.RarityColor(def.rarity)

    frame.achID = def.id
    frame.icon:SetTexture(def.icon)
    frame.iconGlow:SetVertexColor(c[1], c[2], c[3], 0.85)

    frame.heading:SetText(def.hidden and L["TOAST_DISCOVERED"] or L["TOAST_EARNED"])
    frame.title:SetText(def.name)
    frame.title:SetTextColor(c[1], c[2], c[3])
    frame.points:SetText(string.format("|cffffd100+%d %s|r  %s",
        def.points, L["POINTS_SUFFIX"], Util.Colorize(Util.RarityName(def.rarity), c)))

    frame:SetAlpha(0)
    frame:Show()
    inAnim:Play()

    frame.burst:SetVertexColor(c[1], c[2], c[3])
    frame.burstAnim:Stop()
    frame.burstAnim:Play()

    shineFrame:Show()
    shineAnim:Stop()
    shineAnim:Play()

    PlayToastSound(def)

    C_Timer.After(HOLD_TIME, function()
        if frame:IsShown() then outAnim:Play() end
    end)
end

----------------------------------------------------------------------
-- Queue management
----------------------------------------------------------------------
function Toast:ProcessNext()
    if showing then return end
    local def = table.remove(queue, 1)
    if not def then return end
    showing = true
    Render(def)
end

function Toast:Enqueue(def)
    if not ns.DB:Settings().toast then return end
    if ns._suppressNotify then return end   -- silent during the initial catch-up scan
    queue[#queue + 1] = def
    self:ProcessNext()
end

----------------------------------------------------------------------
-- Wire to the engine.
----------------------------------------------------------------------
ns.Engine:RegisterCallback("COMPLETED", function(id, def) Toast:Enqueue(def) end)
