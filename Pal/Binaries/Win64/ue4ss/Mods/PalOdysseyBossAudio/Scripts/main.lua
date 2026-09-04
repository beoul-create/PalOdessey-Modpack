-- PalOdysseyBossAudio - Complementary Boss & Combat Audio Mod for PalOdyssey
-- Works alongside AdaptiveBGM: seamlessly signals suppression during bosses & title screen
-- Uses Native Windows MCI API in-process via UE4SS FFI (Zero external process / Zero AV triggers)

local ModName = "PalOdysseyBossAudio"
local ScriptDir = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("[^/\\]+$", "")
local AudioDir = ScriptDir .. "../audio/"
local ConfigFile = ScriptDir .. "../config.json"

local function Log(msg)
    print(string.format("[%s] %s", ModName, tostring(msg)))
end

-- 1. Dedicated Server Gate (Servers do not render audio)
local isDedicated = false
pcall(function()
    local kismet = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
    local world = UEHelpers and UEHelpers.GetWorldContextObject and UEHelpers.GetWorldContextObject()
    if kismet and kismet:IsValid() and world and world:IsValid() and type(kismet.IsDedicatedServer) == "function" then
        isDedicated = kismet:IsDedicatedServer(world)
    end
end)
if isDedicated then
    Log("Dedicated server detected; companion audio disabled on server.")
    return
end

-- 2. Windows Native In-Process MCI via FFI
local ok_ffi, ffi = pcall(require, "ffi")
local NativeAudioReady = false

if ok_ffi and ffi then
    pcall(function()
        ffi.cdef[[
            int mciSendStringA(const char* lpstrCommand, char* lpstrReturnString, unsigned int uReturnLength, size_t hwndCallback);
        ]]
        NativeAudioReady = true
    end)
end

local function MciExec(cmd)
    if not NativeAudioReady then return -1 end
    local ok, res = pcall(function()
        return ffi.C.mciSendStringA(cmd, nil, 0, 0)
    end)
    return ok and res or -1
end

local CurrentTrackAlias = nil
local CurrentTrackFile = nil
local CurrentVolume = 0.25 -- Gentle, comfortable default (25%)
local IsMuted = false

local function LoadConfig()
    pcall(function()
        local f = io.open(ConfigFile, "r")
        if f then
            local str = f:read("*all")
            f:close()
            local vol = str:match('"Volume"%s*:%s*([%d%.]+)')
            if vol then CurrentVolume = tonumber(vol) or CurrentVolume end
            local muted = str:match('"Muted"%s*:%s*(%a+)')
            if muted then IsMuted = (muted == "true") end
        end
    end)
end

local function SaveConfig()
    pcall(function()
        local f = io.open(ConfigFile, "w")
        if f then
            f:write(string.format('{\n  "Volume": %.2f,\n  "Muted": %s\n}\n', CurrentVolume, IsMuted and "true" or "false"))
            f:close()
        end
    end)
end

LoadConfig()

local function SetAdaptiveBGMSuppression(active)
    _G.PalOdysseyBossAudio_Active = active
end

local function StopCurrentBGM()
    if CurrentTrackAlias then
        MciExec(string.format("stop %s", CurrentTrackAlias))
        MciExec(string.format("close %s", CurrentTrackAlias))
        CurrentTrackAlias = nil
        CurrentTrackFile = nil
    end
end

local function SetMasterVolume(newVol)
    CurrentVolume = math.max(0.0, math.min(1.0, newVol))
    SaveConfig()
    if CurrentTrackAlias then
        local vol = math.floor(CurrentVolume * 1000 + 0.5)
        MciExec(string.format("setaudio %s volume to %d", CurrentTrackAlias, math.max(0, math.min(1000, vol))))
    end
    Log(string.format("Master Volume set to: %.0f%%", CurrentVolume * 100))
    pcall(function()
        local PalUtil = StaticFindObject("/Script/Pal.Default__PalUtility")
        if PalUtil and PalUtil:IsValid() and type(PalUtil.SendSystemToChat) == "function" then
            PalUtil:SendSystemToChat(string.format("Custom Music Volume: %.0f%% (Use [ and ] to adjust)", CurrentVolume * 100))
        end
    end)
end

local function ToggleMute()
    IsMuted = not IsMuted
    SaveConfig()
    if IsMuted then
        StopCurrentBGM()
        Log("Custom Music MUTED")
    else
        Log("Custom Music UNMUTED")
    end
    pcall(function()
        local PalUtil = StaticFindObject("/Script/Pal.Default__PalUtility")
        if PalUtil and PalUtil:IsValid() and type(PalUtil.SendSystemToChat) == "function" then
            PalUtil:SendSystemToChat(IsMuted and "Custom Music: MUTED (Press \\ or type /mute to toggle)" or "Custom Music: UNMUTED")
        end
    end)
end

local function PlayBossBGM(fileName, loop, volumeFraction)
    if IsMuted then return end
    if CurrentTrackFile == fileName then return end

    StopCurrentBGM()
    SetAdaptiveBGMSuppression(true)

    local fullPath = (AudioDir .. fileName):gsub("/", "\\")
    local alias = "PalBoss_" .. tostring(os.time())
    local openCmd = string.format('open "%s" type mpegvideo alias %s', fullPath, alias)
    local ret = MciExec(openCmd)
    if ret == 0 then
        CurrentTrackAlias = alias
        CurrentTrackFile = fileName

        local vol = math.floor(((volumeFraction or 1.0) * CurrentVolume * 1000) + 0.5)
        MciExec(string.format("setaudio %s volume to %d", alias, math.max(0, math.min(1000, vol))))

        local playCmd = loop and string.format("play %s repeat", alias) or string.format("play %s", alias)
        MciExec(playCmd)
        Log(string.format("🎵 Playing Boss BGM: %s (Volume: %d/1000)", fileName, vol))
    else
        Log(string.format("Warning: Failed to play %s (ret: %d)", fileName, ret))
    end
end

local function StopBossBGM()
    StopCurrentBGM()
    SetAdaptiveBGMSuppression(false)
end

local function PlayOneShotSFX(fileName, volumeFraction)
    if IsMuted then return end
    local fullPath = (AudioDir .. fileName):gsub("/", "\\")
    local alias = "PalSFX_" .. tostring(os.clock()):gsub("%.", "")
    local openCmd = fileName:find("%.wav$") and string.format('open "%s" type waveaudio alias %s', fullPath, alias)
        or string.format('open "%s" type mpegvideo alias %s', fullPath, alias)
    
    if MciExec(openCmd) == 0 then
        local vol = math.floor(((volumeFraction or 1.0) * CurrentVolume * 1000) + 0.5)
        MciExec(string.format("setaudio %s volume to %d", alias, math.max(0, math.min(1000, vol))))
        MciExec(string.format("play %s", alias))

        -- Auto-close SFX after 8 seconds
        local delay = ExecuteInGameThreadWithDelay or ExecuteWithDelay
        if delay then
            delay(8000, function()
                MciExec(string.format("stop %s", alias))
                MciExec(string.format("close %s", alias))
            end)
        end
    end
end

-- 3. In-Game Chat Commands and Hotkeys for Volume Adjustment
local function ProcessVolumeChat(Context, Param1)
    local function TryGetStr(val)
        if not val then return "" end
        local s = ""
        pcall(function()
            local obj = val
            if type(val.get) == "function" then obj = val:get() end
            if type(obj) == "string" then s = obj
            elseif type(obj.ToString) == "function" then s = obj:ToString()
            elseif obj.Message and type(obj.Message.ToString) == "function" then s = obj.Message:ToString() end
        end)
        return s
    end

    local text = TryGetStr(Param1):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local volArg = text:match("^/vol%s+(%d+)") or text:match("^!vol%s+(%d+)") or text:match("^/volume%s+(%d+)")
    if volArg then
        local pct = tonumber(volArg)
        if pct then
            SetMasterVolume(pct / 100.0)
        end
    elseif text == "/mute" or text == "!mute" or text == "/unmute" then
        ToggleMute()
    end
end

pcall(RegisterHook, "/Script/Pal.PalPlayerState:EnterChat", ProcessVolumeChat)
pcall(RegisterHook, "/Script/Pal.PalGameStateInGame:BroadcastChatMessage", ProcessVolumeChat)

-- Keyboard shortcuts: [ (Volume Down 5%), ] (Volume Up 5%),  (Mute/Unmute)
if type(RegisterKeyBindAsync) == "function" and Key then
    pcall(function()
        if Key.OPEN_BRACKET then
            RegisterKeyBindAsync(Key.OPEN_BRACKET, {}, function()
                SetMasterVolume(CurrentVolume - 0.05)
            end)
        end
        if Key.CLOSE_BRACKET then
            RegisterKeyBindAsync(Key.CLOSE_BRACKET, {}, function()
                SetMasterVolume(CurrentVolume + 0.05)
            end)
        end
        if Key.BACKSLASH then
            RegisterKeyBindAsync(Key.BACKSLASH, {}, function()
                ToggleMute()
            end)
        end
    end)
end

-- 4. Game State & Combat Detection
local ActiveMajorBossCombat = false
local ActiveFieldBossCombat = false
local LastCombatHitTime = 0
local IsInTitle = true

local function CheckHeadshotBone(bone)
    if not bone then return false end
    local str = ""
    pcall(function()
        if type(bone.ToString) == "function" then str = bone:ToString():lower()
        else str = tostring(bone):lower() end
    end)
    return str:find("head") or str:find("neck") or str:find("face") or str:find("jaw") or str:find("skull") or str:find("horn")
end

-- Headshot / Weak-Point Hit SFX
pcall(RegisterHook, "/Script/Engine.Actor:ReceivePointDamage", function(Context, Damage, DamageType, HitLocation, HitNormal, HitComponent, BoneName)
    pcall(function()
        local b = BoneName and BoneName.get and BoneName:get() or BoneName
        if CheckHeadshotBone(b) then
            PlayOneShotSFX("rust_headshot.wav", 0.85)
        end
    end)
end)

pcall(RegisterHook, "/Script/Pal.PalUIDamageText:Setup", function(Context, Damage, bCritical, bWeakPoint)
    pcall(function()
        local crit = bCritical and (bCritical.get and bCritical:get() or bCritical == true)
        local weak = bWeakPoint and (bWeakPoint.get and bWeakPoint:get() or bWeakPoint == true)
        if crit or weak then
            PlayOneShotSFX("rust_headshot.wav", 0.85)
        end
    end)
end)

-- Combat & Boss Damage Hooks
local function OnDamageProcessed(Context, DamageInfo)
    pcall(function()
        local victim = Context and Context.get and Context:get() or Context
        if not victim or not victim:IsValid() then return end

        local isMajor = false
        local isField = false

        if victim.IsTowerBoss and type(victim.IsTowerBoss) == "function" and victim:IsTowerBoss() then isMajor = true end
        if not isMajor and victim.IsBoss and type(victim.IsBoss) == "function" and victim:IsBoss() then
            local level = 1
            if victim.CharacterParameterComponent and victim.CharacterParameterComponent:IsValid() then
                level = victim.CharacterParameterComponent:GetLevel() or 1
            end
            if level >= 50 then isMajor = true else isField = true end
        end
        if not isMajor and not isField and victim.IsRarePal and type(victim.IsRarePal) == "function" and victim:IsRarePal() then
            isField = true
        end

        if isMajor or isField then
            LastCombatHitTime = os.time()
            if isMajor then
                ActiveMajorBossCombat = true
                ActiveFieldBossCombat = false
                PlayBossBGM("boss_theme_opm.mp3", true, 0.80)
            elseif isField and not ActiveMajorBossCombat then
                ActiveFieldBossCombat = true
                PlayBossBGM("boss_luminous_sword.mp3", true, 0.75)
            end
        end
    end)
end

pcall(RegisterHook, "/Script/Pal.PalCharacter:OnDamage", OnDamageProcessed)

-- Boss HP Bar UI Display
pcall(RegisterHook, "/Script/Pal.PalUIBossHP:Show", function()
    LastCombatHitTime = os.time()
    if not ActiveMajorBossCombat then
        ActiveFieldBossCombat = true
        PlayBossBGM("boss_luminous_sword.mp3", true, 0.75)
    end
end)

-- Capture & Victory Fanfares
pcall(RegisterHook, "/Script/Pal.PalCaptureSubsystem:OnCaptureSuccess", function()
    if ActiveMajorBossCombat or ActiveFieldBossCombat then
        ActiveMajorBossCombat = false
        ActiveFieldBossCombat = false
        PlayBossBGM("victory_fanfare.mp3", false, 0.80)
        local delay = ExecuteInGameThreadWithDelay or ExecuteWithDelay
        if delay then
            delay(7000, function()
                StopBossBGM()
            end)
        end
    end
end)

pcall(RegisterHook, "/Script/Pal.PalCharacter:OnDead", function(Context)
    pcall(function()
        local dead = Context and Context.get and Context:get() or Context
        if not dead or not dead:IsValid() then return end

        local isBoss = false
        if dead.IsBoss and type(dead.IsBoss) == "function" and dead:IsBoss() then isBoss = true end
        if not isBoss and dead.IsRarePal and type(dead.IsRarePal) == "function" and dead:IsRarePal() then isBoss = true end
        if not isBoss and dead.IsTowerBoss and type(dead.IsTowerBoss) == "function" and dead:IsTowerBoss() then isBoss = true end

        if isBoss and (ActiveMajorBossCombat or ActiveFieldBossCombat) then
            ActiveMajorBossCombat = false
            ActiveFieldBossCombat = false
            PlayBossBGM("victory_fanfare.mp3", false, 0.80)
            local delay = ExecuteInGameThreadWithDelay or ExecuteWithDelay
            if delay then
                delay(7000, function()
                    StopBossBGM()
                end)
            end
        end
    end)
end)

-- Title Screen & Transitions
local function OnTitleScreen()
    IsInTitle = true
    ActiveMajorBossCombat = false
    ActiveFieldBossCombat = false
    PlayBossBGM("title_perfect_time.mp3", true, 0.65)
end

local function OnJoinedWorld()
    if IsInTitle then
        IsInTitle = false
        StopBossBGM()
    end
end

pcall(function()
    NotifyOnNewObject("/Script/Pal.PalGameStateInTitle", function()
        OnTitleScreen()
    end)
end)

pcall(RegisterHook, "/Script/Engine.PlayerController:ClientRestart", function()
    OnJoinedWorld()
end)

-- Background Proximity & Combat Expiry Loop
local delayFunc = ExecuteInGameThreadWithDelay or ExecuteWithDelay
if delayFunc then
    local function MonitorLoop()
        pcall(function()
            local now = os.time()
            if (ActiveMajorBossCombat or ActiveFieldBossCombat) and (now - LastCombatHitTime > 18) then
                ActiveMajorBossCombat = false
                ActiveFieldBossCombat = false
                StopBossBGM()
                Log("Boss combat timeout -> Resumed AdaptiveBGM exploration audio.")
            end
        end)
        delayFunc(2000, MonitorLoop)
    end
    delayFunc(5000, MonitorLoop)
end

-- Initial Check
local okInit, pc = pcall(function()
    return UEHelpers and UEHelpers.GetPlayerController and UEHelpers.GetPlayerController()
end)
if not okInit or not pc or not pc:IsValid() then
    OnTitleScreen()
else
    IsInTitle = false
end

Log("PalOdysseyBossAudio successfully initialized alongside AdaptiveBGM with live volume controls.")
