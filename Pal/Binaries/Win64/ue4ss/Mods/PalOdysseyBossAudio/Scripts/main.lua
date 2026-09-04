-- PalOdysseyBossAudio - Complementary Boss, Combat & Title Audio Mod for PalOdyssey
-- Works alongside AdaptiveBGM: seamlessly signals suppression during bosses & title screen
-- Uses Native in-process C++ DLL (dlls/main.dll) with MCI & atomic state synchronization (Zero external processes / Zero AV triggers)

local ModName = "PalOdysseyBossAudio"
local ScriptDir = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("[^/\\]+$", "")
local ModDir = (ScriptDir:gsub("[Ss][Cc][Rr][Ii][Pp][Tt][Ss][\\/]+$", ""))
local AudioDir = ModDir .. "audio/"
local StateFile = ModDir .. "audio_state.json"
local ConfigFile = ModDir .. "config.json"

local function Log(msg)
    print(string.format("[%s] %s", ModName, tostring(msg)))
end

-- 1. Dedicated Server Gate (Dedicated servers do not render audio)
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

-- 2. State & Volume Management
local CurrentBgmState = "stop"
local CurrentBgmTrack = ""
local CurrentBgmLoop = true
local CurrentVolume = 0.25 -- Gentle, comfortable default (25%)
local CurrentFadeSec = 1.0
local SfxSequence = 0
local CurrentSfxTrack = ""
local CurrentSfxVolume = 0.75
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

local function WriteAudioState()
    pcall(function()
        local effectiveVol = IsMuted and 0.0 or CurrentVolume
        local json = string.format(
            '{\n  "bgm_state": "%s",\n  "bgm_track": "%s",\n  "bgm_loop": %s,\n  "bgm_volume": %.2f,\n  "fade_seconds": %.1f,\n  "sfx_track": "%s",\n  "sfx_volume": %.2f,\n  "sfx_sequence": %d\n}\n',
            CurrentBgmState,
            CurrentBgmTrack,
            CurrentBgmLoop and "true" or "false",
            effectiveVol,
            CurrentFadeSec,
            CurrentSfxTrack,
            effectiveVol,
            SfxSequence
        )
        local tmpFile = StateFile .. ".tmp"
        local f = io.open(tmpFile, "w")
        if f then
            f:write(json)
            f:close()
            os.remove(StateFile)
            os.rename(tmpFile, StateFile)
        end
    end)
end

local function SetAdaptiveBGMSuppression(active)
    _G.PalOdysseyBossAudio_Active = active
end

local function PlayBossBGM(fileName, loop, volumeFraction, fadeSeconds)
    if IsMuted then return end
    if CurrentBgmTrack == fileName and CurrentBgmState == "play" then return end

    SetAdaptiveBGMSuppression(true)

    CurrentBgmState = "play"
    CurrentBgmTrack = fileName
    CurrentBgmLoop = (loop ~= false)
    CurrentFadeSec = fadeSeconds or 0.8
    WriteAudioState()

    Log(string.format("Playing Audio: %s (Volume: %.0f%%)", fileName, CurrentVolume * 100))
end

local function StopBossBGM(fadeSeconds)
    CurrentBgmState = "stop"
    CurrentFadeSec = fadeSeconds or 1.2
    WriteAudioState()
    SetAdaptiveBGMSuppression(false)
end

local function PlayOneShotSFX(fileName, volumeFraction)
    if IsMuted then return end
    SfxSequence = SfxSequence + 1
    CurrentSfxTrack = fileName
    CurrentSfxVolume = (volumeFraction or 1.0) * CurrentVolume
    WriteAudioState()
end

local function SetMasterVolume(newVol)
    CurrentVolume = math.max(0.0, math.min(1.0, newVol))
    SaveConfig()
    WriteAudioState()

    Log(string.format("Master Volume set to: %.0f%%", CurrentVolume * 100))
    pcall(function()
        local chatSub = FindFirstOf("PalChatSubsystem")
        local msg = string.format("Custom Music Volume: %.0f%% (Use [ and ] to adjust)", CurrentVolume * 100)
        if chatSub and chatSub:IsValid() and type(chatSub.SendSystemChatMessage) == "function" then
            local pc = UEHelpers and UEHelpers.GetPlayerController and UEHelpers.GetPlayerController()
            if pc and pc:IsValid() then
                chatSub:SendSystemChatMessage(pc, FText(msg))
                return
            end
        end
        local PalUtil = StaticFindObject("/Script/Pal.Default__PalUtility")
        if PalUtil and PalUtil:IsValid() and type(PalUtil.SendSystemToChat) == "function" then
            PalUtil:SendSystemToChat(msg)
        end
    end)
end

local function ToggleMute()
    IsMuted = not IsMuted
    SaveConfig()
    WriteAudioState()
    if IsMuted then
        Log("Custom Music MUTED")
    else
        Log("Custom Music UNMUTED")
    end
    pcall(function()
        local PalUtil = StaticFindObject("/Script/Pal.Default__PalUtility")
        if PalUtil and PalUtil:IsValid() and type(PalUtil.SendSystemToChat) == "function" then
            PalUtil:SendSystemToChat(IsMuted and "Custom Music: MUTED" or string.format("Custom Music: UNMUTED (%.0f%%)", CurrentVolume * 100))
        end
    end)
end

-- 3. In-Game Chat Commands & Hotkeys for Volume Adjustment
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

-- Keyboard shortcuts: [ (Volume Down 5%), ] (Volume Up 5%), \ (Mute/Unmute)
-- Uses UE4SS Key enums: OEM_FOUR = [, OEM_SIX = ], OEM_FIVE = \
if type(RegisterKeyBindAsync) == "function" and Key then
    pcall(function()
        local keyVolDown = Key.OEM_FOUR or Key.OPEN_BRACKET
        local keyVolUp = Key.OEM_SIX or Key.CLOSE_BRACKET
        local keyMute = Key.OEM_FIVE or Key.BACKSLASH

        if keyVolDown then
            RegisterKeyBindAsync(keyVolDown, {}, function()
                SetMasterVolume(CurrentVolume - 0.05)
            end)
        end
        if keyVolUp then
            RegisterKeyBindAsync(keyVolUp, {}, function()
                SetMasterVolume(CurrentVolume + 0.05)
            end)
        end
        if keyMute then
            RegisterKeyBindAsync(keyMute, {}, function()
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
                PlayBossBGM("boss_theme_opm.mp3", true, 0.80, 0.8)
            elseif isField and not ActiveMajorBossCombat then
                ActiveFieldBossCombat = true
                PlayBossBGM("boss_luminous_sword.mp3", true, 0.75, 0.8)
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
        PlayBossBGM("boss_luminous_sword.mp3", true, 0.75, 0.8)
    end
end)

-- Capture & Victory Fanfares
pcall(RegisterHook, "/Script/Pal.PalCaptureSubsystem:OnCaptureSuccess", function()
    if ActiveMajorBossCombat or ActiveFieldBossCombat then
        ActiveMajorBossCombat = false
        ActiveFieldBossCombat = false
        PlayOneShotSFX("victory_fanfare.mp3", 0.85)
        StopBossBGM(1.0)
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
            PlayOneShotSFX("victory_fanfare.mp3", 0.85)
            StopBossBGM(1.0)
        end
    end)
end)

-- Title Screen & Transitions
local function OnTitleScreen()
    IsInTitle = true
    ActiveMajorBossCombat = false
    ActiveFieldBossCombat = false
    PlayBossBGM("title_perfect_time.mp3", true, 0.65, 1.0)
end

local function OnJoinedWorld()
    if IsInTitle then
        IsInTitle = false
        StopBossBGM(1.5)
        Log("Player joined world -> Stopped title music, AdaptiveBGM active.")
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
                StopBossBGM(1.5)
                Log("Boss combat timeout -> Resumed AdaptiveBGM exploration audio.")
            end
        end)
        delayFunc(2000, MonitorLoop)
    end
    delayFunc(5000, MonitorLoop)
end

-- Initial Check on Mod Load
local okInit, pc = pcall(function()
    return UEHelpers and UEHelpers.GetPlayerController and UEHelpers.GetPlayerController()
end)
if not okInit or not pc or not pc:IsValid() then
    OnTitleScreen()
else
    IsInTitle = false
end

Log("PalOdysseyBossAudio successfully initialized alongside AdaptiveBGM with live volume controls.")
