-- ============================================================================
-- NoHatersBullyElitists - Enterprise 6-Tab Security & Blizzard Ticket Suite v1.0.0
-- Universal WoW Forever (16001), Classic Era, Classic Progression & Retail Edition
-- Author: iintellectualgamer (iintellectualgamer@gmail.com)
-- Twitch: https://www.twitch.tv/iintellectualgamer
-- YouTube: https://www.youtube.com/iintellectualgamer
-- Characters: Wissegmini-Kil'jaeden & Wwiisseegemi-Tichondrius
-- Policy: 100% Free & Open Source per Blizzard UI Add-On Development Policy
-- ============================================================================

local FOLDER_NAME = ...
local ADDON_NAME = FOLDER_NAME or "NoHatersBullyElitists"
local VERSION = "1.0.0"

NoHatersBullyElitistsDB = NoHatersBullyElitistsDB or {}
NoHatersBullyElitistsCharDB = NoHatersBullyElitistsCharDB or {}

local function TrimStr(s)
    if type(s) ~= "string" then return "" end
    return string.match(s, "^%s*(.-)%s*$") or ""
end

local function CreateStyledFrame(frameType, name, parent)
    local template = (BackdropTemplateMixin and "BackdropTemplate") or nil
    local ok, f = pcall(CreateFrame, frameType, name, parent, template)
    if not ok or not f then
        f = CreateFrame(frameType, name, parent)
    end
    if BackdropTemplateMixin and not f.SetBackdrop then
        pcall(Mixin, f, BackdropTemplateMixin)
    end
    return f
end

local function ApplyBoxStyle(f, bgR, bgG, bgB, bgA, edgeR, edgeG, edgeB, edgeA)
    if f.SetBackdrop then
        pcall(f.SetBackdrop, f, {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        pcall(f.SetBackdropColor, f, bgR or 0.04, bgG or 0.05, bgB or 0.08, bgA or 0.95)
        pcall(f.SetBackdropBorderColor, f, edgeR or 0.75, edgeG or 0.55, edgeB or 0.20, edgeA or 1)
    else
        if not f._fallbackBg then
            local bg = f:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(f)
            f._fallbackBg = bg
        end
        f._fallbackBg:SetColorTexture(bgR or 0.04, bgG or 0.05, bgB or 0.08, bgA or 0.95)
    end
end

-- Helper to set active vs inactive visual highlight on any button
local function SetButtonHighlightState(btn, isActive, baseLabel, countSuffix)
    if not btn or not btn.lbl then return end
    local suffix = countSuffix or ""
    if isActive then
        ApplyBoxStyle(btn, 0.10, 0.36, 0.14, 0.98, 0.25, 1.00, 0.35, 1)
        btn.lbl:SetText("|cff00ff00> " .. baseLabel .. suffix .. " <|r")
    else
        ApplyBoxStyle(btn, 0.38, 0.10, 0.06, 0.95, 0.75, 0.55, 0.20, 1)
        btn.lbl:SetText("|cffffd100" .. baseLabel .. suffix .. "|r")
    end
end

local DEFAULT_HARASS_WORDS = {
    "loser", "uninstall", "kill yourself", "kys", "trash player",
    "worthless", "garbage player", "delete your account", "harass"
}
local DEFAULT_PHISH_WORDS = {
    "http", "https", "www.", ".com/", ".gg/", "bit.ly",
    "blizz-admin", "gm-ticket", "free-mount", "account-verify"
}
local DEFAULT_THEFT_WORDS = {
    "ninja", "stole the pot", "gdkp scam", "kept the gold",
    "unreturned loan", "scammed my mats", "loot theft"
}

local BLIZZARD_URLS = {
    {
        id = 1,
        btnLabel = "1. Submit Blizzard Support Ticket (US Main Portal)",
        category = "General Harassment, Bullying, Griefing & Code of Conduct Tickets",
        url = "https://us.battle.net/support/en/ticket/submit",
        guide = "Use this primary Battle.net Support portal to attach your Tab 2 Evidence Dossier for ongoing harassment, whisper stalking, or griefing."
    },
    {
        id = 2,
        btnLabel = "2. Official Report a Player / Abuse Policy Guide",
        category = "Official Blizzard Instructions for Reporting Abuse & Chat Violations",
        url = "https://us.battle.net/support/en/article/99516",
        guide = "Official Blizzard support article detailing how Game Masters investigate harassment, chat abuse, disruptive gameplay, and offensive names."
    },
    {
        id = 3,
        btnLabel = "3. Report Hacks, Bots & Exploits Webform",
        category = "Direct Webform for Cheating, Botting, Fly-Hacking & Economy Exploits",
        url = "https://us.blizzard.com/en-us/submit/hacks.html",
        guide = "Dedicated Blizzard Hacks webform for reporting automated bots, terrain exploits, speed hacks, or RMT boosting rings."
    },
    {
        id = 4,
        btnLabel = "4. Blizzard Hacks & Cheating Investigation Email",
        category = "Direct One-Way Evidence Email for Video Links & Timestamped Dossiers",
        url = "hacks@blizzard.com",
        guide = "Official Blizzard investigation inbox. Paste your Tab 2 Dossier and any unlisted YouTube/Twitch video evidence links directly into an email."
    },
    {
        id = 5,
        btnLabel = "5. Scamming, Ninja Looting & Gold Theft Policy",
        category = "Official Policy on Item/Gold Scamming, GDKP Fraud & Chat Agreements",
        url = "https://us.battle.net/support/en/article/2563",
        guide = "Explains how Blizzard enforces explicit in-game chat agreements for loot rules, crafting materials, and gold loans."
    },
    {
        id = 6,
        btnLabel = "6. Account Compromise & Phishing Recovery Portal",
        category = "Emergency Account Recovery & Fake GM Phishing Link Protection",
        url = "https://us.battle.net/support/en/help/product/wow/181/187/solution",
        guide = "Immediate recovery workflow if a player clicked a fake GM whisper link or Discord verification scam."
    },
    {
        id = 7,
        btnLabel = "7. Blizzard In-Game Code of Conduct (Article 42673)",
        category = "Official Behavioral Standards & Protected Gameplay Interaction Rules",
        url = "https://us.battle.net/support/en/article/42673",
        guide = "Reference the exact Code of Conduct clauses when submitting your structured evidence dossier to Blizzard Game Masters."
    },
    {
        id = 8,
        btnLabel = "8. Submit Blizzard Support Ticket (EU Portal)",
        category = "European Battle.net Support Ticket Submission Portal",
        url = "https://eu.battle.net/support/en/ticket/submit",
        guide = "Direct support ticket submission portal for European region World of Warcraft accounts."
    }
}

local DEFAULT_MANUAL_TEXT = table.concat({
    "======================================================================",
    "COMPLETE IN-GAME VISUAL ENCYCLOPEDIA, SLASH COMMANDS & AUTHOR CREDITS",
    "======================================================================",
    "HOW TO RESTORE ACCIDENTALLY CLEARED OR DELETED TEXT:",
    "• If you ever accidentally delete or overwrite text inside any box, click the",
    "  [Restore Default Text] button at the top-right of the window (or type /nhbe restore",
    "  or /reload in chat) to immediately restore all original default text!",
    "",
    "SLASH COMMANDS REFERENCE:",
    "• /nhbe or /nhbeclassic or /nohaters : Toggles the 6-Tab Security Suite window.",
    "• /nhbe restore : Restores all default text across every tab immediately.",
    "• /nhbe mini : Collapses the window into the compact Floating Minimize Bar.",
    "• /nhbe urls : Opens Tab 3 (8 Official Blizzard Complaint & Support URLs).",
    "• /nhbe scope : Switches between Account-Wide and Per-Character chat isolation.",
    "• /nhbe soundtest : Plays a Master-channel audio test chime.",
    "• /nhbe test : Fires the Simulate Test Alert generator.",
    "• /nhbe clear : Clears session and saved chat logs for the active scope.",
    "",
    "HOW TO USE THE UPPER-RIGHT MINIMAP ICON (45 DEGREES):",
    "• Look at the Upper-Right rim of your circular Minimap (just below the Zone Name).",
    "• Left-Click       : Opens or closes the Main 6-Tab Security Suite Window.",
    "• Shift+Left-Click : Collapses or expands the Floating Minimize Bar.",
    "• Right-Click      : Opens Tab 3 (8 Official Blizzard Complaint URLs).",
    "• Left-Click+Drag  : Drag the Shield icon anywhere around the circular Minimap rim.",
    "• On Tab 5, click [Snap Minimap Icon to Upper-Right (45 deg)] to return it to the",
    "  default 45-degree upper-right corner and flash a golden ring around it!",
    "",
    "OFFICIAL AUTHOR CREDITS (Select any link and press Ctrl+C to copy):",
    "• Author: iintellectualgamer",
    "• Email: iintellectualgamer@gmail.com",
    "• Twitch: https://www.twitch.tv/iintellectualgamer",
    "• YouTube: https://www.youtube.com/iintellectualgamer",
    "• Characters: Wissegmini-Kil'jaeden & Wwiisseegemi-Tichondrius",
    "• Version: v1.0.0 (100% Free & Open Source per Blizzard UI Add-On Development Policy)"
}, "\n")

local SOUND_PHISH  = 8959  -- RAID_WARNING
local SOUND_THEFT  = 8960  -- READY_CHECK
local SOUND_HARASS = 12867 -- AlarmClockWarning2
local SOUND_CLICK  = 856   -- IG_MAINMENU_OPTION_CHECKBOX_ON

local function InitDatabases()
    NoHatersBullyElitistsDB = NoHatersBullyElitistsDB or {}
    NoHatersBullyElitistsCharDB = NoHatersBullyElitistsCharDB or {}

    NoHatersBullyElitistsDB.logs = NoHatersBullyElitistsDB.logs or {}
    NoHatersBullyElitistsDB.blacklist = NoHatersBullyElitistsDB.blacklist or {}
    NoHatersBullyElitistsDB.offenseCounts = NoHatersBullyElitistsDB.offenseCounts or {}
    NoHatersBullyElitistsDB.customWords = NoHatersBullyElitistsDB.customWords or {}
    if NoHatersBullyElitistsDB.soundAlerts == nil then NoHatersBullyElitistsDB.soundAlerts = true end
    if NoHatersBullyElitistsDB.chatWarnings == nil then NoHatersBullyElitistsDB.chatWarnings = true end
    if NoHatersBullyElitistsDB.separateByChar == nil then NoHatersBullyElitistsDB.separateByChar = false end
    if NoHatersBullyElitistsDB.minimapAngle == nil then NoHatersBullyElitistsDB.minimapAngle = 45 end
    if NoHatersBullyElitistsDB.hideMinimap == nil then NoHatersBullyElitistsDB.hideMinimap = false end
    if NoHatersBullyElitistsDB.isMinimized == nil then NoHatersBullyElitistsDB.isMinimized = false end

    NoHatersBullyElitistsCharDB.logs = NoHatersBullyElitistsCharDB.logs or {}
    NoHatersBullyElitistsCharDB.offenseCounts = NoHatersBullyElitistsCharDB.offenseCounts or {}
end

local function PlayNHBESound(soundID, forcePlay)
    InitDatabases()
    if forcePlay or NoHatersBullyElitistsDB.soundAlerts then
        if PlaySound then
            local ok = pcall(PlaySound, soundID or SOUND_CLICK, "Master")
            if not ok then pcall(PlaySound, soundID or SOUND_CLICK) end
        end
    end
end

local function GetPlayerFullName()
    local name, realm = UnitName("player")
    realm = (realm and realm ~= "" and realm) or (GetRealmName and GetRealmName()) or "Realm"
    name = name or "Player"
    return tostring(name) .. "-" .. tostring(realm)
end

local function GetActiveLogs()
    InitDatabases()
    if NoHatersBullyElitistsDB.separateByChar then
        return NoHatersBullyElitistsCharDB.logs
    end
    return NoHatersBullyElitistsDB.logs
end

local function GetActiveOffenses()
    InitDatabases()
    if NoHatersBullyElitistsDB.separateByChar then
        return NoHatersBullyElitistsCharDB.offenseCounts
    end
    return NoHatersBullyElitistsDB.offenseCounts
end

-- ============================================================================
-- UI FRAMES: MAIN WINDOW, MINIMIZE BAR, URL COPY POPUP & MINIMAP BUTTON
-- ============================================================================
local MainFrame, MiniBar, URLPopupFrame, MinimapBtn
local currentTab = 1
local currentFilter = "ALL"
local currentDossierMode = "HARASS"
local searchQuery = ""
local RefreshAllUI
local RestoreAllDefaultText

local function CreateStyledButton(parent, label, width, height, onClick)
    local b = CreateStyledFrame("Button", nil, parent)
    b:SetSize(width, height)
    ApplyBoxStyle(b, 0.38, 0.10, 0.06, 0.95, 0.75, 0.55, 0.20, 1)
    b.baseLabel = label
    b.lbl = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.lbl:SetPoint("CENTER", 0, 0)
    b.lbl:SetText("|cffffd100" .. label .. "|r")
    b:SetScript("OnClick", function(self, btn)
        PlayNHBESound(SOUND_CLICK, true)
        if onClick then onClick(self, btn) end
    end)
    return b
end

local function CreateURLPopup()
    if URLPopupFrame then return URLPopupFrame end
    local f = CreateStyledFrame("Frame", "NHBE_URLCopyPopup", UIParent)
    f:SetSize(560, 150)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    ApplyBoxStyle(f, 0.03, 0.04, 0.07, 0.98, 0.9, 0.7, 0.2, 1)
    f:Hide()

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -14)
    f.title:SetText("|cff00ccffOfficial Blizzard Support & Complaint URL|r")

    f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.sub:SetPoint("TOP", f.title, "BOTTOM", 0, -6)
    f.sub:SetText("Press |cff00ff00Ctrl + C|r now to copy this link, then paste it into your web browser:")

    local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    eb:SetSize(490, 28)
    eb:SetPoint("TOP", f.sub, "BOTTOM", 0, -10)
    eb:SetAutoFocus(true)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    f.editBox = eb

    f.note = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.note:SetPoint("TOP", eb, "BOTTOM", 0, -6)
    f.note:SetWidth(510)
    f.note:SetText("")

    local closeBtn = CreateStyledButton(f, "Done / Close", 120, 24, function() f:Hide() end)
    closeBtn:SetPoint("BOTTOM", 0, 12)

    URLPopupFrame = f
    return f
end

local function ShowURLCopyPopup(label, url, guideText)
    local popup = CreateURLPopup()
    popup.title:SetText("|cff00ccff" .. tostring(label) .. "|r")
    popup.editBox:SetText(tostring(url))
    popup.note:SetText("|cffffd100" .. tostring(guideText or "") .. "|r")
    popup:Show()
    popup.editBox:SetFocus()
    popup.editBox:HighlightText()
    PlayNHBESound(SOUND_CLICK, true)
end

local function CreateMinimizeBar()
    if MiniBar then return MiniBar end
    local bar = CreateStyledFrame("Frame", "NHBE_MinimizeBar", UIParent)
    bar:SetSize(470, 34)
    bar:SetPoint("TOP", UIParent, "TOP", 0, -28)
    bar:SetFrameStrata("HIGH")
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", bar.StopMovingOrSizing)
    ApplyBoxStyle(bar, 0.05, 0.07, 0.12, 0.95, 0.85, 0.65, 0.15, 1)
    bar:Hide()

    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.text:SetPoint("LEFT", 10, 0)
    bar.text:SetText("|cff00ccffNHBE v1.0.0|r | Live: 0 | Flagged: 0")

    bar.expandBtn = CreateStyledButton(bar, "Expand [+]", 74, 22, function()
        NoHatersBullyElitistsDB.isMinimized = false
        bar:Hide()
        if MainFrame then MainFrame:Show() end
        if RefreshAllUI then RefreshAllUI() end
    end)
    bar.expandBtn:SetPoint("RIGHT", -6, 0)

    bar.urlsBtn = CreateStyledButton(bar, "Blizz URLs", 70, 22, function()
        NoHatersBullyElitistsDB.isMinimized = false
        bar:Hide()
        currentTab = 3
        if MainFrame then MainFrame:Show() end
        if RefreshAllUI then RefreshAllUI() end
    end)
    bar.urlsBtn:SetPoint("RIGHT", -84, 0)

    bar.ticketBtn = CreateStyledButton(bar, "Tickets", 58, 22, function()
        NoHatersBullyElitistsDB.isMinimized = false
        bar:Hide()
        currentTab = 2
        if MainFrame then MainFrame:Show() end
        if RefreshAllUI then RefreshAllUI() end
    end)
    bar.ticketBtn:SetPoint("RIGHT", -158, 0)

    MiniBar = bar
    return bar
end

local function FlashMinimapButton()
    if not MinimapBtn then return end
    if not MinimapBtn.flashRing then
        local ring = MinimapBtn:CreateTexture(nil, "OVERLAY")
        ring:SetSize(56, 56)
        ring:SetPoint("CENTER", MinimapBtn, "CENTER", 0, 0)
        ring:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        ring:SetBlendMode("ADD")
        MinimapBtn.flashRing = ring
    end
    MinimapBtn.flashRing:Show()
    local elapsedTotal = 0
    MinimapBtn:SetScript("OnUpdate", function(self, elapsed)
        elapsedTotal = elapsedTotal + (elapsed or 0.016)
        local alpha = math.abs(math.sin(elapsedTotal * 8))
        self.flashRing:SetAlpha(alpha)
        if elapsedTotal >= 3.0 then
            self.flashRing:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end)
end

local function UpdateMinimapButtonPosition()
    if not MinimapBtn or not Minimap then return end
    local deg = NoHatersBullyElitistsDB.minimapAngle or 45
    local angle = math.rad(deg)
    local w = Minimap:GetWidth() or 140
    local radius = (w / 2) + 8
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    MinimapBtn:ClearAllPoints()
    MinimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateMinimapButton()
    if MinimapBtn or not Minimap then return end
    local btn = CreateFrame("Button", "NHBE_MinimapButton", Minimap)
    btn:SetSize(32, 32)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(15)
    btn:RegisterForClicks("AnyUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Shield_06")
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            NoHatersBullyElitistsDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
            UpdateMinimapButtonPosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function(self, button)
        PlayNHBESound(SOUND_CLICK, true)
        if button == "RightButton" then
            NoHatersBullyElitistsDB.isMinimized = false
            if MiniBar then MiniBar:Hide() end
            currentTab = 3
            if MainFrame then MainFrame:Show() end
            if RefreshAllUI then RefreshAllUI() end
        elseif IsShiftKeyDown() or button == "MiddleButton" then
            NoHatersBullyElitistsDB.isMinimized = not NoHatersBullyElitistsDB.isMinimized
            if NoHatersBullyElitistsDB.isMinimized then
                if MainFrame then MainFrame:Hide() end
                CreateMinimizeBar():Show()
            else
                if MiniBar then MiniBar:Hide() end
                if MainFrame then MainFrame:Show() end
            end
            if RefreshAllUI then RefreshAllUI() end
        else
            if MainFrame and MainFrame:IsShown() then
                MainFrame:Hide()
            elseif MiniBar and MiniBar:IsShown() then
                MiniBar:Hide()
                NoHatersBullyElitistsDB.isMinimized = false
                if MainFrame then MainFrame:Show() end
            else
                NoHatersBullyElitistsDB.isMinimized = false
                if MainFrame then MainFrame:Show() end
            end
            if RefreshAllUI then RefreshAllUI() end
        end
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00ccffNoHatersBullyElitists v" .. VERSION .. "|r")
        local logs = GetActiveLogs()
        local scopeTxt = NoHatersBullyElitistsDB.separateByChar and "This Character Only" or "Account-Wide (Shared)"
        GameTooltip:AddLine("Chat Storage Scope: |cff00ff00" .. scopeTxt .. "|r", 1, 1, 1)
        GameTooltip:AddLine("Logged Messages: |cffffd100" .. tostring(#logs) .. "|r", 1, 1, 1)
        GameTooltip:AddLine(string.format("Minimap Rim Angle: |cffffd100%d deg|r", math.floor(NoHatersBullyElitistsDB.minimapAngle or 45)), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff00ff00Left-Click:|r Toggle Main Security Suite Window", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cff00ff00Shift+Left-Click:|r Toggle Floating Minimize Bar", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cff00ff00Right-Click:|r Open Blizzard Complaint URLs (Tab 3)", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("|cff00ff00Drag:|r Move Icon Around Minimap (Default: Upper-Right 45°)", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    MinimapBtn = btn
    UpdateMinimapButtonPosition()
    if NoHatersBullyElitistsDB.hideMinimap then btn:Hide() else btn:Show() end
end

-- ============================================================================
-- LOGGING, CLASSIFICATION & SIMULATOR ENGINE
-- ============================================================================
local function ClassifyMessage(msg)
    local lower = string.lower(msg or "")
    if string.find(lower, "core professional belief", 1, true) or string.find(lower, "personal opinion", 1, true) then
        return nil, nil
    end
    for _, w in ipairs(DEFAULT_PHISH_WORDS) do
        if string.find(lower, w, 1, true) then
            return "SCAM", w
        end
    end
    for _, w in ipairs(DEFAULT_THEFT_WORDS) do
        if string.find(lower, w, 1, true) then
            return "THEFT", w
        end
    end
    for _, w in ipairs(DEFAULT_HARASS_WORDS) do
        if string.find(lower, w, 1, true) then
            return "HARASS", w
        end
    end
    for _, w in ipairs(NoHatersBullyElitistsDB.customWords or {}) do
        if w ~= "" and string.find(lower, string.lower(w), 1, true) then
            return "HARASS", w
        end
    end
    return nil, nil
end

local function RecordChatEvent(msg, sender, channelCat, channelDisplay)
    InitDatabases()
    if not msg or msg == "" then return end
    sender = sender or "Unknown"
    local ts = date("%Y-%m-%d %H:%M:%S")
    local zone = (GetZoneText and GetZoneText()) or "Azeroth"
    if zone == "" then zone = "Azeroth" end
    local violationType, triggerWord = ClassifyMessage(msg)

    local entry = {
        time = ts,
        sender = sender,
        channelCat = channelCat,
        channelDisplay = channelDisplay or channelCat,
        zone = zone,
        msg = msg,
        violation = violationType,
        trigger = triggerWord
    }

    table.insert(NoHatersBullyElitistsDB.logs, entry)
    if #NoHatersBullyElitistsDB.logs > 1000 then table.remove(NoHatersBullyElitistsDB.logs, 1) end

    table.insert(NoHatersBullyElitistsCharDB.logs, entry)
    if #NoHatersBullyElitistsCharDB.logs > 1000 then table.remove(NoHatersBullyElitistsCharDB.logs, 1) end

    if violationType then
        NoHatersBullyElitistsDB.offenseCounts[sender] = (NoHatersBullyElitistsDB.offenseCounts[sender] or 0) + 1
        NoHatersBullyElitistsCharDB.offenseCounts[sender] = (NoHatersBullyElitistsCharDB.offenseCounts[sender] or 0) + 1
        local count = GetActiveOffenses()[sender] or 1

        if count >= 3 then
            NoHatersBullyElitistsDB.blacklist[sender] = true
        end

        if violationType == "SCAM" then
            PlayNHBESound(SOUND_PHISH, false)
        elseif violationType == "THEFT" then
            PlayNHBESound(SOUND_THEFT, false)
        else
            PlayNHBESound(SOUND_HARASS, false)
        end

        if NoHatersBullyElitistsDB.chatWarnings and DEFAULT_CHAT_FRAME then
            if violationType == "SCAM" then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[NoHatersBullyElitists - PHISHING ALERT]|r Suspicious link/scam from " .. sender .. " [" .. (channelDisplay or channelCat) .. "] (Trigger: '" .. tostring(triggerWord) .. "'). Do not click external links!")
            elseif violationType == "THEFT" then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[NoHatersBullyElitists - THEFT ALERT]|r Item/Loot/Loan theft incident from " .. sender .. " [" .. (channelDisplay or channelCat) .. "] (Offense #" .. count .. " | Trigger: '" .. tostring(triggerWord) .. "'). Logged for ticket export.")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[NoHatersBullyElitists - GUARD]|r Flagged message from " .. sender .. " [" .. (channelDisplay or channelCat) .. "] (Offense #" .. count .. " | Trigger: '" .. tostring(triggerWord) .. "').")
            end
        end
    end

    if RefreshAllUI then RefreshAllUI() end
end

local function RunTestSimulation()
    RecordChatEvent("WTS HEROIC/MYTHIC [SAVED/UNSAVED] Join for more info -> https://discord.gg/CDjnjWRzBD", "Sürfräid-Tichondrius", "TRADE", "Pub:Trade (Services) - City")
    RecordChatEvent("You are a total loser, uninstall the game right now!", "TestBully-Stormwind", "PARTY", "Party")
    RecordChatEvent("Still a loser, I'm logging on my alt whisper to keep harassing you!", "TestBully-Stormwind", "WHISPER", "Whisper")
    RecordChatEvent("He ninja looted the boss drop, kept the pot in GDKP fraud, and logged off with my unreturned loan!", "TestThief-Tichondrius", "PARTY", "Party")
    RecordChatEvent("In my personal opinion and core professional belief, playing with respect makes every dungeon smoother.", "FriendlyRaider-Kil'jaeden", "GUILD", "Guild")
end

-- ============================================================================
-- DOSSIER GENERATOR (TAB 2)
-- ============================================================================
local function GenerateDossierText(mode)
    mode = mode or currentDossierMode or "HARASS"
    local logs = GetActiveLogs()
    local me = GetPlayerFullName()
    local zone = (GetZoneText and GetZoneText()) or "Azeroth"
    local now = date("%Y-%m-%d %H:%M:%S")
    local scopeLabel = NoHatersBullyElitistsDB.separateByChar and "CHARACTER-ISOLATED LOGS (" .. me .. ")" or "ACCOUNT-WIDE SHARED LOGS"

    local catTitle = "FLAGGED"
    local complaintLine = "Ongoing Harassment / Abusive Chat\nThe player(s) listed below engaged in targeted toxicity, verbal abuse, or continuous harassment in violation of the Blizzard Code of Conduct. Please verify against server-side logs for the exact timestamps below."

    if mode == "THEFT" then
        catTitle = "THEFT"
        complaintLine = "Item / Gold Theft Scam & Fraud\nThe player(s) listed below engaged in explicit item/loot theft, ninja looting, defaulted gold loan fraud, or GDKP pot theft in violation of Blizzard's Scamming & Restoration policies."
    elseif mode == "SCAM" then
        catTitle = "SCAM"
        complaintLine = "Phishing / Fake GM Link Scam\nThe player(s) listed below broadcasted suspicious external phishing links or fake GM whispers."
    elseif mode == "FULL" then
        catTitle = "FULL TRANSCRIPT"
        complaintLine = "Full Session Chat Transcript & Contextual Audit Log\nComplete chronological log exported for Game Master verification."
    end

    local lines = {
        "======================================================================",
        "OFFICIAL BLIZZARD SUPPORT TICKET EVIDENCE DOSSIER",
        "Generated by: NoHatersBullyElitists v" .. VERSION .. " (" .. scopeLabel .. ")",
        "Author: iintellectualgamer (iintellectualgamer@gmail.com | https://www.twitch.tv/iintellectualgamer | https://www.youtube.com/iintellectualgamer)",
        "Characters: Wissegmini-Kil'jaeden & Wwiisseegemi-Tichondrius",
        "======================================================================",
        "Reporting Player : " .. me,
        "Current Location : " .. zone,
        "Export Timestamp : " .. now .. " (Local Time)",
        "Dossier Category : " .. catTitle,
        "----------------------------------------------------------------------",
        "COMPLAINT TYPE: " .. complaintLine,
        "----------------------------------------------------------------------",
        "ETHICAL, LEGAL & POLICY CLASSIFICATION STATEMENT (LEGITIMATE HARASSMENT VS. PROTECTED OPINION/BELIEF):",
        "This dossier strictly filters and records actionable, continuous harassment, targeted verbal abuse, threats, malicious stalking, phishing links, and direct item/gold theft scams in violation of the Blizzard Entertainment In-Game Code of Conduct.",
        "",
        "ETHICAL NON-INFRINGEMENT OF OPINION & CORE PERSONAL/PROFESSIONAL BELIEFS:",
        "This report explicitly EXCLUDES and does NOT target players for expressing harmless personal opinions, gameplay preferences, constructive tactical feedback, or core personal, ethical, moral, philosophical, religious, or professional beliefs. An entry is flagged as [LEGITIMATE HARASSMENT] only when behavior crosses the threshold into targeted malice, repeated unwanted contact (e.g., bypassing /ignore via alts, continuous whisper beratement), severe toxicity, derogatory slurs, or fraudulent theft/phishing.",
        "----------------------------------------------------------------------"
    }

    local matched = 0
    for _, e in ipairs(logs) do
        local include = false
        if mode == "FULL" then
            include = true
        elseif mode == "THEFT" and e.violation == "THEFT" then
            include = true
        elseif mode == "SCAM" and e.violation == "SCAM" then
            include = true
        elseif mode == "HARASS" and e.violation ~= nil then
            include = true
        end

        if include then
            matched = matched + 1
            local tag = e.violation or "PROTECTED/CHAT"
            local trig = e.trigger and (" | Trigger: " .. e.trigger) or ""
            table.insert(lines, string.format("%s [%s%s] [Channel: %s] [Zone: %s] Offender/Sender: %s", e.time, tag, trig, e.channelDisplay, e.zone, e.sender))
            table.insert(lines, string.format("Message: \"%s\"", e.msg))
            table.insert(lines, "")
        end
    end

    if matched == 0 then
        table.insert(lines, "[No matching incidents currently recorded in this filter mode. Click 'Simulate Test Alert' at the bottom of the window to test dossier generation.]")
    end
    table.insert(lines, "======================================================================")
    table.insert(lines, "TIP: If you ever accidentally delete or clear text in this box, click [Restore Default Text] at the top-right (or type /reload in chat) to restore it!")
    return table.concat(lines, "\n")
end

-- ============================================================================
-- MAIN 6-TAB ENTERPRISE WINDOW
-- ============================================================================
RestoreAllDefaultText = function()
    if not MainFrame then return end
    currentFilter = "ALL"
    searchQuery = ""
    if MainFrame.panels[1] and MainFrame.panels[1].searchBox then
        MainFrame.panels[1].searchBox:SetText("")
    end
    if MainFrame.panels[2] and MainFrame.panels[2].dossierBox then
        MainFrame.panels[2].dossierBox:SetText(GenerateDossierText(currentDossierMode))
    end
    if MainFrame.panels[6] and MainFrame.panels[6].manualBox then
        MainFrame.panels[6].manualBox:SetText(DEFAULT_MANUAL_TEXT)
    end
    if RefreshAllUI then RefreshAllUI() end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[NoHatersBullyElitists]|r All default text across Tabs 1, 2, 4, and 6 has been restored! (You can also type |cff00ccff/reload|r anytime).")
    end
end

local function BuildMainWindow()
    if MainFrame then return MainFrame end
    InitDatabases()

    local f = CreateStyledFrame("Frame", "NoHatersBullyElitistsMainFrame", UIParent)
    f:SetSize(820, 560)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    ApplyBoxStyle(f, 0.04, 0.05, 0.08, 0.96, 0.85, 0.65, 0.15, 1)

    f.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.titleText:SetPoint("TOPLEFT", 16, -12)
    f.titleText:SetText("|cff00ccffNoHatersBullyElitists|r — Enterprise 6-Tab Security & Blizzard Ticket Suite v" .. VERSION)

    local closeBtn = CreateStyledButton(f, "X", 24, 22, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", -10, -8)

    local minBtn = CreateStyledButton(f, "Minimize [_]", 86, 22, function()
        NoHatersBullyElitistsDB.isMinimized = true
        f:Hide()
        CreateMinimizeBar():Show()
        if RefreshAllUI then RefreshAllUI() end
    end)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)

    -- NEW: 1-Click Restore Default Text Button on Top Header Bar
    local restoreTopBtn = CreateStyledButton(f, "Restore Default Text", 136, 22, function()
        RestoreAllDefaultText()
    end)
    restoreTopBtn:SetPoint("RIGHT", minBtn, "LEFT", -6, 0)

    local tabNames = {
        "1. Live Feed",
        "2. Ticket Export",
        "3. Blizzard URLs",
        "4. Blacklist & Scope",
        "5. Audio & Test",
        "6. Visual Manual"
    }
    f.tabBtns = {}
    for i, name in ipairs(tabNames) do
        local tb = CreateStyledButton(f, name, 128, 26, function()
            currentTab = i
            -- Automatically ensure manual and dossier text are restored when switching tabs
            if i == 2 and f.panels[2] and f.panels[2].dossierBox then
                f.panels[2].dossierBox:SetText(GenerateDossierText(currentDossierMode))
            elseif i == 6 and f.panels[6] and f.panels[6].manualBox then
                f.panels[6].manualBox:SetText(DEFAULT_MANUAL_TEXT)
            end
            RefreshAllUI()
        end)
        tb:SetPoint("TOPLEFT", 14 + (i - 1) * 132, -36)
        tb.baseLabel = name
        f.tabBtns[i] = tb
    end

    f.panels = {}
    for i = 1, 6 do
        local p = CreateStyledFrame("Frame", nil, f)
        p:SetPoint("TOPLEFT", 14, -68)
        p:SetPoint("BOTTOMRIGHT", -14, 46)
        ApplyBoxStyle(p, 0.02, 0.02, 0.04, 0.95, 0.5, 0.4, 0.2, 0.9)
        p:Hide()
        f.panels[i] = p
    end

    -- ========================================================================
    -- TAB 1: LIVE FEED
    -- ========================================================================
    local p1 = f.panels[1]
    local p1Banner = p1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p1Banner:SetPoint("TOPLEFT", 12, -10)
    p1Banner:SetText("|cff00ccffLIVE THREAT & CHAT MONITOR — WITH LIVE CHANNEL & VIOLATION COUNTERS|r")

    local filterDefs = {
        { key = "ALL",     label = "All" },
        { key = "WHISPER", label = "Whispers" },
        { key = "GUILD",   label = "Guild" },
        { key = "PARTY",   label = "Party/Raid" },
        { key = "SAY",     label = "Say/Yell" },
        { key = "TRADE",   label = "Trade/Pub" },
        { key = "FLAGGED", label = "Flagged" },
        { key = "SCAM",    label = "Scams" },
        { key = "THEFT",   label = "Theft" }
    }
    p1.filterBtns = {}
    for idx, fd in ipairs(filterDefs) do
        local fb = CreateStyledButton(p1, fd.label, 84, 22, function()
            currentFilter = fd.key
            RefreshAllUI()
        end)
        fb:SetPoint("TOPLEFT", 10 + (idx - 1) * 86, -32)
        fb.filterKey = fd.key
        fb.baseLabel = fd.label
        p1.filterBtns[idx] = fb
    end

    local searchLbl = p1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    searchLbl:SetPoint("TOPLEFT", 12, -62)
    searchLbl:SetText("SEARCH PLAYER / WORD:")

    local searchBox = CreateFrame("EditBox", nil, p1, "InputBoxTemplate")
    searchBox:SetSize(160, 20)
    searchBox:SetPoint("LEFT", searchLbl, "RIGHT", 10, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function(self)
        searchQuery = self:GetText() or ""
        if RefreshAllUI then RefreshAllUI() end
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    p1.searchBox = searchBox

    local resetBtn = CreateStyledButton(p1, "Reset / Restore Text", 122, 20, function()
        RestoreAllDefaultText()
    end)
    resetBtn:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)

    p1.statusText = p1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p1.statusText:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
    p1.statusText:SetText("|cff00ff00Filter: [ALL] | Scope: [ACCOUNT]|r")

    local p1Tip = p1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p1Tip:SetPoint("TOPLEFT", 12, -84)
    p1Tip:SetText("|cffffd100Tip: Accidentally cleared text? Click [Restore Default Text] at top-right or type /reload in chat to restore everything.|r")

    local sf1 = CreateFrame("ScrollFrame", "NHBE_Tab1Scroll", p1, "UIPanelScrollFrameTemplate")
    sf1:SetPoint("TOPLEFT", 10, -102)
    sf1:SetPoint("BOTTOMRIGHT", -30, 10)
    local eb1 = CreateFrame("EditBox", nil, sf1)
    eb1:SetMultiLine(true)
    eb1:SetFontObject(ChatFontNormal)
    eb1:SetWidth(730)
    eb1:SetAutoFocus(false)
    eb1:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sf1:SetScrollChild(eb1)
    p1.logBox = eb1

    -- ========================================================================
    -- TAB 2: TICKET DOSSIER GENERATOR (WITH HIGHLIGHTED CATEGORY BUTTONS)
    -- ========================================================================
    local p2 = f.panels[2]
    local p2Title = p2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p2Title:SetPoint("TOPLEFT", 12, -10)
    p2Title:SetText("|cff00ccff1-CLICK BLIZZARD SUPPORT TICKET & COMPLAINT DOSSIER GENERATOR|r")

    local p2RestoreTip = p2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p2RestoreTip:SetPoint("TOPLEFT", 12, -60)
    p2RestoreTip:SetText("|cffffd100Press Ctrl+C to copy. If text is accidentally erased, click any Category Button above, [Restore Default Text], or type /reload!|r")

    local sf2 = CreateFrame("ScrollFrame", "NHBE_Tab2Scroll", p2, "UIPanelScrollFrameTemplate")
    sf2:SetPoint("TOPLEFT", 10, -78)
    sf2:SetPoint("BOTTOMRIGHT", -30, 10)
    local eb2 = CreateFrame("EditBox", nil, sf2)
    eb2:SetMultiLine(true)
    eb2:SetFontObject(ChatFontNormal)
    eb2:SetWidth(730)
    eb2:SetAutoFocus(false)
    eb2:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sf2:SetScrollChild(eb2)
    p2.dossierBox = eb2

    local dModes = {
        { label = "1. Ongoing Harassment",   mode = "HARASS" },
        { label = "2. Item/Gold Theft Scam", mode = "THEFT" },
        { label = "3. Phishing/Fake GM Link", mode = "SCAM" },
        { label = "4. Full Session Transcript", mode = "FULL" }
    }
    p2.dossierBtns = {}
    for i, dm in ipairs(dModes) do
        local db = CreateStyledButton(p2, dm.label, 186, 24, function()
            currentDossierMode = dm.mode
            RefreshAllUI()
            eb2:SetText(GenerateDossierText(dm.mode))
            eb2:SetFocus()
            eb2:HighlightText()
        end)
        db:SetPoint("TOPLEFT", 10 + (i - 1) * 192, -30)
        db.modeKey = dm.mode
        db.baseLabel = dm.label
        p2.dossierBtns[i] = db
    end

    -- ========================================================================
    -- TAB 3: 8 OFFICIAL BLIZZARD COMPLAINT URL BUTTONS
    -- ========================================================================
    local p3 = f.panels[3]
    local p3Title = p3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p3Title:SetPoint("TOPLEFT", 12, -10)
    p3Title:SetText("|cff00ccffOFFICIAL BLIZZARD COMPLAINT & SUPPORT URL LAUNCHER (1 BUTTON PER PAGE)|r")

    local p3Sub = p3:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p3Sub:SetPoint("TOPLEFT", 12, -28)
    p3Sub:SetText("Click any official Blizzard Complaint Page button below to open the 1-Click Ctrl+C URL Copy Box:")

    for idx, item in ipairs(BLIZZARD_URLS) do
        local col = ((idx - 1) % 2)
        local row = math.floor((idx - 1) / 2)
        local ub = CreateStyledButton(p3, item.btnLabel, 376, 36, function()
            ShowURLCopyPopup(item.btnLabel, item.url, item.guide)
        end)
        ub:SetPoint("TOPLEFT", 12 + col * 386, -52 - row * 74)

        local desc = p3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        desc:SetPoint("TOPLEFT", ub, "BOTTOMLEFT", 2, -3)
        desc:SetWidth(374)
        desc:SetJustifyH("LEFT")
        desc:SetText("|cffffd100" .. item.url .. "|r — |cffcccccc" .. item.category .. "|r")
    end

    -- ========================================================================
    -- TAB 4: CHARACTER vs. ACCOUNT CHAT SEPARATION & BLACKLIST
    -- ========================================================================
    local p4 = f.panels[4]
    local p4Title = p4:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p4Title:SetPoint("TOPLEFT", 12, -10)
    p4Title:SetText("|cff00ccffACCOUNT vs. CHARACTER CHAT ISOLATION & BLACKLIST MANAGER|r")

    p4.scopeStatus = p4:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p4.scopeStatus:SetPoint("TOPLEFT", 12, -36)
    p4.scopeStatus:SetText("Current Chat Storage Scope: Account-Wide")

    local toggleScopeBtn = CreateStyledButton(p4, "Toggle Account-Wide vs. Per-Character Chat Separation", 360, 28, function()
        NoHatersBullyElitistsDB.separateByChar = not NoHatersBullyElitistsDB.separateByChar
        RefreshAllUI()
    end)
    toggleScopeBtn:SetPoint("TOPLEFT", 12, -60)

    local restoreTab4Btn = CreateStyledButton(p4, "Restore Default Text", 160, 28, function()
        RestoreAllDefaultText()
    end)
    restoreTab4Btn:SetPoint("LEFT", toggleScopeBtn, "RIGHT", 10, 0)

    local sf4 = CreateFrame("ScrollFrame", "NHBE_Tab4Scroll", p4, "UIPanelScrollFrameTemplate")
    sf4:SetPoint("TOPLEFT", 10, -100)
    sf4:SetPoint("BOTTOMRIGHT", -30, 10)
    local eb4 = CreateFrame("EditBox", nil, sf4)
    eb4:SetMultiLine(true)
    eb4:SetFontObject(ChatFontNormal)
    eb4:SetWidth(730)
    eb4:SetAutoFocus(false)
    eb4:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sf4:SetScrollChild(eb4)
    p4.infoBox = eb4

    -- ========================================================================
    -- TAB 5: AUDIO DIAGNOSTICS & MINIMAP POSITION CONTROLS
    -- ========================================================================
    local p5 = f.panels[5]
    local p5Title = p5:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p5Title:SetPoint("TOPLEFT", 12, -10)
    p5Title:SetText("|cff00ccffSOUND EFFECT DIAGNOSTICS (MASTER CHANNEL) & MINIMAP ICON CONTROLS|r")

    local testPhishBtn = CreateStyledButton(p5, "Test Phishing Alert Sound (Raid Warning)", 246, 28, function()
        PlayNHBESound(SOUND_PHISH, true)
    end)
    testPhishBtn:SetPoint("TOPLEFT", 12, -38)

    local testTheftBtn = CreateStyledButton(p5, "Test Theft/Scam Sound (Ready Check)", 246, 28, function()
        PlayNHBESound(SOUND_THEFT, true)
    end)
    testTheftBtn:SetPoint("LEFT", testPhishBtn, "RIGHT", 10, 0)

    local testHarassBtn = CreateStyledButton(p5, "Test Harassment Guard Sound (Alarm)", 246, 28, function()
        PlayNHBESound(SOUND_HARASS, true)
    end)
    testHarassBtn:SetPoint("LEFT", testTheftBtn, "RIGHT", 10, 0)

    local resetMinimapBtn = CreateStyledButton(p5, "Snap Minimap Icon to Upper-Right (45 deg)", 246, 28, function()
        NoHatersBullyElitistsDB.hideMinimap = false
        NoHatersBullyElitistsDB.minimapAngle = 45
        CreateMinimapButton()
        if MinimapBtn then MinimapBtn:Show() end
        UpdateMinimapButtonPosition()
        FlashMinimapButton()
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[NoHatersBullyElitists]|r Minimap Shield Icon snapped to Upper-Right (45 degrees) of your Minimap and flashing gold!")
        end
        RefreshAllUI()
    end)
    resetMinimapBtn:SetPoint("TOPLEFT", 12, -76)

    local snapTopLeftBtn = CreateStyledButton(p5, "Test Move Icon: Upper-Left (135 deg)", 246, 28, function()
        NoHatersBullyElitistsDB.hideMinimap = false
        NoHatersBullyElitistsDB.minimapAngle = 135
        CreateMinimapButton()
        if MinimapBtn then MinimapBtn:Show() end
        UpdateMinimapButtonPosition()
        FlashMinimapButton()
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[NoHatersBullyElitists]|r Minimap Shield Icon moved to Upper-Left (135 degrees) of your Minimap!")
        end
        RefreshAllUI()
    end)
    snapTopLeftBtn:SetPoint("LEFT", resetMinimapBtn, "RIGHT", 10, 0)

    local toggleMinimapBtn = CreateStyledButton(p5, "Show / Hide Minimap Icon", 246, 28, function()
        NoHatersBullyElitistsDB.hideMinimap = not NoHatersBullyElitistsDB.hideMinimap
        if MinimapBtn then
            if NoHatersBullyElitistsDB.hideMinimap then MinimapBtn:Hide() else MinimapBtn:Show() end
        end
        RefreshAllUI()
    end)
    toggleMinimapBtn:SetPoint("LEFT", snapTopLeftBtn, "RIGHT", 10, 0)

    local openMiniBarBtn = CreateStyledButton(p5, "Switch to Floating Minimize Bar", 246, 28, function()
        NoHatersBullyElitistsDB.isMinimized = true
        f:Hide()
        CreateMinimizeBar():Show()
        RefreshAllUI()
    end)
    openMiniBarBtn:SetPoint("TOPLEFT", 12, -114)

    local restoreTab5Btn = CreateStyledButton(p5, "Restore All Default Text Now", 246, 28, function()
        RestoreAllDefaultText()
    end)
    restoreTab5Btn:SetPoint("LEFT", openMiniBarBtn, "RIGHT", 10, 0)

    local p5Guide = p5:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p5Guide:SetPoint("TOPLEFT", 14, -156)
    p5Guide:SetWidth(750)
    p5Guide:SetJustifyH("LEFT")
    p5Guide:SetText(table.concat({
        "|cff00ccffHOW TO USE THE MINIMAP ICON & SNAP TO UPPER-RIGHT (45 DEGREES):|r",
        "1. Look at the circular Minimap in the top-right corner of your screen: the Shield Icon sits on the Upper-Right rim (45°).",
        "2. Why clicking 'Snap to Upper-Right (45 deg)' didn't appear to move it before: the icon starts at 45° by default! Now, clicking",
        "   [Snap Minimap Icon to Upper-Right (45 deg)] flashes a bright pulsing gold ring on the icon and prints a chat confirmation.",
        "   You can also click [Test Move Icon: Upper-Left (135 deg)] above to watch it jump across your Minimap, or Left-Click & Drag it!",
        "",
        "|cff00ccffHOW TO RESTORE ACCIDENTALLY CLEARED TEXT:|r",
        "• Clicking [Restore Default Text] in the top-right header (or typing /nhbe restore or /reload in chat) restores all default text."
    }, "\n"))

    -- ========================================================================
    -- TAB 6: VISUAL MANUAL (WITH RESTORE DEFAULT TEXT BUTTON)
    -- ========================================================================
    local p6 = f.panels[6]
    local p6Header = p6:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p6Header:SetPoint("TOPLEFT", 12, -10)
    p6Header:SetText("|cff00ccffCOMPLETE IN-GAME VISUAL ENCYCLOPEDIA & MANUAL|r |cffffd100(Cleared text? Click Restore -> or type /reload)|r")

    local p6RestoreBtn = CreateStyledButton(p6, "Restore Manual Text", 148, 22, function()
        p6.manualBox:SetText(DEFAULT_MANUAL_TEXT)
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[NoHatersBullyElitists]|r Visual Manual text restored to default!")
        end
    end)
    p6RestoreBtn:SetPoint("TOPRIGHT", -32, -6)

    local sf6 = CreateFrame("ScrollFrame", "NHBE_Tab6Scroll", p6, "UIPanelScrollFrameTemplate")
    sf6:SetPoint("TOPLEFT", 10, -34)
    sf6:SetPoint("BOTTOMRIGHT", -30, 10)
    local eb6 = CreateFrame("EditBox", nil, sf6)
    eb6:SetMultiLine(true)
    eb6:SetFontObject(ChatFontNormal)
    eb6:SetWidth(730)
    eb6:SetAutoFocus(false)
    eb6:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sf6:SetScrollChild(eb6)
    eb6:SetText(DEFAULT_MANUAL_TEXT)
    p6.manualBox = eb6

    -- ========================================================================
    -- PERSISTENT BOTTOM ACTION BAR
    -- ========================================================================
    f.clearBtn = CreateStyledButton(f, "Clear Session Logs", 118, 24, function()
        if NoHatersBullyElitistsDB.separateByChar then
            NoHatersBullyElitistsCharDB.logs = {}
            NoHatersBullyElitistsCharDB.offenseCounts = {}
        else
            NoHatersBullyElitistsDB.logs = {}
            NoHatersBullyElitistsDB.offenseCounts = {}
        end
        RefreshAllUI()
    end)
    f.clearBtn:SetPoint("BOTTOMLEFT", 14, 12)

    f.soundBtn = CreateStyledButton(f, "Sound Alerts: ON", 118, 24, function()
        NoHatersBullyElitistsDB.soundAlerts = not NoHatersBullyElitistsDB.soundAlerts
        if NoHatersBullyElitistsDB.soundAlerts then PlayNHBESound(SOUND_THEFT, true) end
        RefreshAllUI()
    end)
    f.soundBtn:SetPoint("LEFT", f.clearBtn, "RIGHT", 6, 0)

    f.warnBtn = CreateStyledButton(f, "Chat Warnings: ON", 122, 24, function()
        NoHatersBullyElitistsDB.chatWarnings = not NoHatersBullyElitistsDB.chatWarnings
        RefreshAllUI()
    end)
    f.warnBtn:SetPoint("LEFT", f.soundBtn, "RIGHT", 6, 0)

    f.scopeBtn = CreateStyledButton(f, "Scope: Account", 116, 24, function()
        NoHatersBullyElitistsDB.separateByChar = not NoHatersBullyElitistsDB.separateByChar
        RefreshAllUI()
    end)
    f.scopeBtn:SetPoint("LEFT", f.warnBtn, "RIGHT", 6, 0)

    f.simBtn = CreateStyledButton(f, "Simulate Test Alert", 126, 24, function()
        RunTestSimulation()
    end)
    f.simBtn:SetPoint("LEFT", f.scopeBtn, "RIGHT", 6, 0)

    f.urlsQuickBtn = CreateStyledButton(f, "Blizzard URLs", 96, 24, function()
        currentTab = 3
        RefreshAllUI()
    end)
    f.urlsQuickBtn:SetPoint("LEFT", f.simBtn, "RIGHT", 6, 0)

    f.jumpTicketBtn = CreateStyledButton(f, "Ticket Export", 96, 24, function()
        currentTab = 2
        if f.panels[2] and f.panels[2].dossierBox then
            f.panels[2].dossierBox:SetText(GenerateDossierText(currentDossierMode))
        end
        RefreshAllUI()
    end)
    f.jumpTicketBtn:SetPoint("LEFT", f.urlsQuickBtn, "RIGHT", 6, 0)

    MainFrame = f
    return f
end

-- ============================================================================
-- MASTER UI REFRESH (HIGHLIGHTS ACTIVE TABS, DOSSIER MODES & FILTERS)
-- ============================================================================
RefreshAllUI = function()
    InitDatabases()
    local logs = GetActiveLogs()
    local counts = { ALL = #logs, WHISPER = 0, GUILD = 0, PARTY = 0, SAY = 0, TRADE = 0, FLAGGED = 0, SCAM = 0, THEFT = 0 }
    for _, e in ipairs(logs) do
        if counts[e.channelCat] ~= nil then counts[e.channelCat] = counts[e.channelCat] + 1 end
        if e.violation then counts.FLAGGED = counts.FLAGGED + 1 end
        if e.violation == "SCAM" then counts.SCAM = counts.SCAM + 1 end
        if e.violation == "THEFT" then counts.THEFT = counts.THEFT + 1 end
    end

    if MiniBar then
        local scopeShort = NoHatersBullyElitistsDB.separateByChar and "Char" or "Acct"
        MiniBar.text:SetText(string.format("|cff00ccffNHBE|r | All: %d | Flagged: |cffff5555%d|r | %s", counts.ALL, counts.FLAGGED, scopeShort))
    end

    if not MainFrame then return end

    -- 1. Highlight Active Top Tab Button (1 through 6)
    for i, tb in ipairs(MainFrame.tabBtns) do
        SetButtonHighlightState(tb, (i == currentTab), tb.baseLabel, "")
    end

    for i, p in ipairs(MainFrame.panels) do
        if i == currentTab then p:Show() else p:Hide() end
    end

    MainFrame.soundBtn.lbl:SetText(NoHatersBullyElitistsDB.soundAlerts and "|cff00ff00Sound Alerts: ON|r" or "|cffff5555Sound Alerts: OFF|r")
    MainFrame.warnBtn.lbl:SetText(NoHatersBullyElitistsDB.chatWarnings and "|cff00ff00Chat Warnings: ON|r" or "|cffff5555Chat Warnings: OFF|r")
    MainFrame.scopeBtn.lbl:SetText(NoHatersBullyElitistsDB.separateByChar and "|cff00ccffScope: Character|r" or "|cffffd100Scope: Account|r")

    -- 2. Highlight Active Tab 1 Filter Button
    local p1 = MainFrame.panels[1]
    for _, fb in ipairs(p1.filterBtns) do
        local c = counts[fb.filterKey] or 0
        SetButtonHighlightState(fb, (fb.filterKey == currentFilter), fb.baseLabel, " (" .. c .. ")")
    end

    local qLower = string.lower(searchQuery or "")
    local outLines = {}
    for i = #logs, 1, -1 do
        local e = logs[i]
        local matchFilter = (currentFilter == "ALL")
            or (currentFilter == "FLAGGED" and e.violation ~= nil)
            or (currentFilter == "SCAM" and e.violation == "SCAM")
            or (currentFilter == "THEFT" and e.violation == "THEFT")
            or (e.channelCat == currentFilter)

        local matchQuery = (qLower == "")
            or string.find(string.lower(e.sender or ""), qLower, 1, true)
            or string.find(string.lower(e.msg or ""), qLower, 1, true)

        if matchFilter and matchQuery then
            local prefix = e.violation and ("|cffff4444[" .. e.violation .. "]|r ") or ""
            table.insert(outLines, string.format("[%s] <%s - %s> %s%s: %s", e.time, e.channelDisplay, e.zone, prefix, e.sender, e.msg))
        end
    end

    local scopeTag = NoHatersBullyElitistsDB.separateByChar and "CHARACTER ONLY" or "ACCOUNT-WIDE"
    p1.statusText:SetText(string.format("|cff00ff00Filter: [%s] | Scope: [%s] | Showing: %d (Total: %d)|r", currentFilter, scopeTag, #outLines, #logs))

    if #outLines == 0 then
        p1.logBox:SetText(table.concat({
            "No chat entries currently match Filter [" .. currentFilter .. "].",
            "",
            "• Click [Simulate Test Alert] at the bottom of the window to generate sample violations immediately!",
            "• Click [Scope: Account / Character] at the bottom to switch between shared account logs and character-only logs.",
            "• Accidentally cleared or edited text in any tab? Click [Restore Default Text] at the top-right (or type /reload in chat) to restore everything back the way it was!"
        }, "\n"))
    else
        p1.logBox:SetText(table.concat(outLines, "\n\n"))
    end

    -- 3. Highlight Active Tab 2 Dossier Mode Button (Ongoing Harassment, Item/Gold Theft, Phishing, Full Transcript)
    local p2 = MainFrame.panels[2]
    if p2.dossierBtns then
        for _, db in ipairs(p2.dossierBtns) do
            SetButtonHighlightState(db, (db.modeKey == currentDossierMode), db.baseLabel, "")
        end
    end
    if TrimStr(p2.dossierBox:GetText()) == "" then
        p2.dossierBox:SetText(GenerateDossierText(currentDossierMode))
    end

    -- 4. Refresh Tab 4 Scope & Blacklist summary
    local p4 = MainFrame.panels[4]
    p4.scopeStatus:SetText("Active Chat Storage Mode: " .. (NoHatersBullyElitistsDB.separateByChar and "|cff00ccffSEPARATED PER CHARACTER (" .. GetPlayerFullName() .. ")|r" or "|cffffd100SHARED ACCOUNT-WIDE (All Characters on Account)|r"))
    local blLines = {
        "CHAT STORAGE ISOLATION EXPLAINED:",
        "• Account-Wide Mode (Default): Shares captured chat logs across all characters on your World of Warcraft account.",
        "• Per-Character Mode: Isolates Tab 1 Live Feed and Tab 2 Ticket Dossiers strictly to " .. GetPlayerFullName() .. ".",
        "",
        "HOW TO RESTORE ACCIDENTALLY CLEARED TEXT:",
        "• Click [Restore Default Text] above (or type /nhbe restore or /reload in chat) anytime.",
        "",
        "AUTO-BLACKLISTED OFFENDERS (3+ Flagged Offenses):"
    }
    local anyBL = false
    for sender, _ in pairs(NoHatersBullyElitistsDB.blacklist or {}) do
        anyBL = true
        table.insert(blLines, "• " .. sender .. " (Offenses: " .. tostring((GetActiveOffenses()[sender] or 3)) .. ")")
    end
    if not anyBL then table.insert(blLines, "• None recorded yet.") end
    p4.infoBox:SetText(table.concat(blLines, "\n"))

    -- 5. Ensure Tab 6 Visual Manual is never left blank if accidentally cleared
    local p6 = MainFrame.panels[6]
    if p6 and p6.manualBox and TrimStr(p6.manualBox:GetText()) == "" then
        p6.manualBox:SetText(DEFAULT_MANUAL_TEXT)
    end
end

-- ============================================================================
-- SLASH COMMANDS (REGISTERED AT TOP LEVEL)
-- ============================================================================
local function HandleSlashCommand(msg)
    InitDatabases()
    local cmd = string.lower(TrimStr(msg))
    BuildMainWindow()
    CreateMinimizeBar()
    CreateMinimapButton()

    if cmd == "test" then
        NoHatersBullyElitistsDB.isMinimized = false
        MiniBar:Hide()
        MainFrame:Show()
        RunTestSimulation()
    elseif cmd == "restore" or cmd == "reset" or cmd == "resettext" then
        NoHatersBullyElitistsDB.isMinimized = false
        MiniBar:Hide()
        MainFrame:Show()
        RestoreAllDefaultText()
    elseif cmd == "soundtest" then
        PlayNHBESound(SOUND_PHISH, true)
    elseif cmd == "mini" then
        NoHatersBullyElitistsDB.isMinimized = not NoHatersBullyElitistsDB.isMinimized
        if NoHatersBullyElitistsDB.isMinimized then
            MainFrame:Hide()
            MiniBar:Show()
        else
            MiniBar:Hide()
            MainFrame:Show()
        end
        RefreshAllUI()
    elseif cmd == "urls" then
        NoHatersBullyElitistsDB.isMinimized = false
        MiniBar:Hide()
        currentTab = 3
        MainFrame:Show()
        RefreshAllUI()
    elseif cmd == "scope" then
        NoHatersBullyElitistsDB.separateByChar = not NoHatersBullyElitistsDB.separateByChar
        RefreshAllUI()
    elseif cmd == "clear" then
        if NoHatersBullyElitistsDB.separateByChar then
            NoHatersBullyElitistsCharDB.logs = {}
            NoHatersBullyElitistsCharDB.offenseCounts = {}
        else
            NoHatersBullyElitistsDB.logs = {}
            NoHatersBullyElitistsDB.offenseCounts = {}
        end
        RefreshAllUI()
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[NoHatersBullyElitists]|r Session and saved chat logs cleared.")
        end
    else
        if MainFrame:IsShown() then
            MainFrame:Hide()
        else
            NoHatersBullyElitistsDB.isMinimized = false
            MiniBar:Hide()
            MainFrame:Show()
            RefreshAllUI()
        end
    end
end

SLASH_NOHATERSBULLYELITISTS1 = "/nhbe"
SLASH_NOHATERSBULLYELITISTS2 = "/nhbeclassic"
SLASH_NOHATERSBULLYELITISTS3 = "/nohaters"
SlashCmdList["NOHATERSBULLYELITISTS"] = HandleSlashCommand

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================
local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("ADDON_LOADED")
evFrame:RegisterEvent("PLAYER_LOGIN")
evFrame:RegisterEvent("CHAT_MSG_WHISPER")
evFrame:RegisterEvent("CHAT_MSG_GUILD")
evFrame:RegisterEvent("CHAT_MSG_OFFICER")
evFrame:RegisterEvent("CHAT_MSG_PARTY")
evFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
evFrame:RegisterEvent("CHAT_MSG_RAID")
evFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
evFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
evFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
evFrame:RegisterEvent("CHAT_MSG_SAY")
evFrame:RegisterEvent("CHAT_MSG_YELL")
evFrame:RegisterEvent("CHAT_MSG_CHANNEL")

evFrame:SetScript("OnEvent", function(self, event, arg1, arg2, _, arg4, _, _, _, _, arg9)
    if event == "ADDON_LOADED" and (arg1 == ADDON_NAME or arg1 == "NoHatersBullyElitists" or arg1 == "NoHatersBullyElitists_Classic") then
        InitDatabases()
    elseif event == "PLAYER_LOGIN" then
        InitDatabases()
        BuildMainWindow()
        CreateMinimizeBar()
        CreateMinimapButton()
        if NoHatersBullyElitistsDB.isMinimized then
            MainFrame:Hide()
            MiniBar:Show()
        end
        RefreshAllUI()
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[NoHatersBullyElitists v" .. VERSION .. "]|r Loaded (iintellectualgamer@gmail.com | Twitch & YouTube: iintellectualgamer | Wissegmini-Kil'jaeden & Wwiisseegemi-Tichondrius). Type |cff00ff00/nhbe|r or |cff00ff00/nohaters|r to open, or |cff00ff00/nhbe restore|r to reset text.")
        end
    elseif event == "CHAT_MSG_WHISPER" then
        RecordChatEvent(arg1, arg2, "WHISPER", "Whisper")
    elseif event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER" then
        RecordChatEvent(arg1, arg2, "GUILD", "Guild")
    elseif event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_INSTANCE_CHAT" or event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
        RecordChatEvent(arg1, arg2, "PARTY", "Party/Raid")
    elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_YELL" then
        RecordChatEvent(arg1, arg2, "SAY", "Say/Yell")
    elseif event == "CHAT_MSG_CHANNEL" then
        RecordChatEvent(arg1, arg2, "TRADE", "Pub:" .. tostring(arg9 or arg4 or "Channel"))
    end
end)
