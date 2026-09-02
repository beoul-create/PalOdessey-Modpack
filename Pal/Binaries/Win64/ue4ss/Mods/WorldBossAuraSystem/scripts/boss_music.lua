local BossMusic = {}
local Performance = require("performance")

local ScriptDir = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("[^/\\]+$", "")
local AudioDir = ScriptDir .. "../audio/"
local StateFile = AudioDir .. "music_state.json"
local JukeboxExe = AudioDir .. "PalBossJukebox.exe"
local HeartbeatFile = AudioDir .. "jukebox_heartbeat.txt"
local MetricsFile = AudioDir .. "jukebox_metrics.json"
local Config = {}

local CurrentTrack = ""
local CurrentState = "idle"
local JukeboxStarted = false
local LastJukeboxStartAttempt = 0
local VictoryTimer = 0

-- State tracking
local IsInTitle = true
local IsConnecting = false
local ActiveMajorBossCombat = false
local ActiveFieldBossCombat = false
local ActiveNearBoss = false
local LastMajorBossCombatTime = 0
local LastFieldBossCombatTime = 0
local LastHeadshotSfxTime = 0

local MajorBossCombatTimeout = 20
local FieldBossCombatTimeout = 15
local MusicScanIntervalMs = 5000
local BaseScanIntervalSeconds = 30
local BossCombatProximityRadius = 15000.0
local WorldBossMusicRadius = 8000.0
local HeartbeatStaleSeconds = 12
local BossClassificationCache = {}

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function WriteState(content)
    local startedAt = Performance.Start()
    local ok, err = pcall(function()
        local f = assert(io.open(StateFile, "w"))
        f:write(content)
        f:flush()
        f:close()
    end)
    if not ok then
        Performance.Count("music_state_write_errors")
        print(string.format("[WorldBossAuraSystem] Music state write failed: %s", tostring(err)))
    else
        Performance.Count("music_state_writes")
    end
    Performance.Finish("music_state_write", startedAt, ok)
    return ok
end

local function EnsureJukeboxRunning()
    local heartbeat = io.open(HeartbeatFile, "r")
    if heartbeat then
        local heartbeatTime = tonumber(heartbeat:read("*all")) or 0
        heartbeat:close()
        local heartbeatAge = os.time() - heartbeatTime
        if heartbeatAge >= 0 and heartbeatAge <= HeartbeatStaleSeconds then
            JukeboxStarted = true
            return true
        end
    end
    JukeboxStarted = false

    local now = os.time()
    if now - LastJukeboxStartAttempt < 5 then return false end
    LastJukeboxStartAttempt = now

    -- Verify executable exists before invoking Windows shell
    local f = io.open(JukeboxExe, "rb")
    if not f then
        print("[WorldBossAuraSystem] PalBossJukebox.exe was not found; custom music is disabled.")
        return false
    end
    f:close()

    local ok, result, _, exitCode = pcall(os.execute, string.format('start "" /B "%s"', JukeboxExe:gsub("/", "\\")))
    JukeboxStarted = ok and (result == true or result == 0 or exitCode == 0)
    if not JukeboxStarted then
        print("[WorldBossAuraSystem] PalBossJukebox.exe could not be started; retrying later.")
    end
    return JukeboxStarted
end

local CurrentMasterVolume = 0.15
local CurrentBaseVolume = 0.60
local CurrentLoop = true
local LastUnmutedVolume = 0.15

local function GetMasterVolume()
    local vol = CurrentMasterVolume
    pcall(function()
        local f = io.open(ScriptDir .. "../config.json", "r")
        if f then
            local txt = f:read("*all")
            f:close()
            local m = txt:match('"MusicMasterVolume"%s*:%s*([%d%.]+)')
            if m then
                vol = tonumber(m) or vol
                CurrentMasterVolume = vol
            end
        end
    end)
    return math.max(0.0, math.min(1.0, vol))
end

function BossMusic.SetMasterVolume(vol)
    vol = math.max(0.0, math.min(1.0, vol))
    CurrentMasterVolume = vol
    if vol > 0.01 then LastUnmutedVolume = vol end

    -- 1. Save to config.json
    pcall(function()
        local cfgPath = ScriptDir .. "../config.json"
        local f = io.open(cfgPath, "r")
        local content = f and f:read("*all") or ""
        if f then f:close() end

        if content:find('"MusicMasterVolume"') then
            content = content:gsub('"MusicMasterVolume"%s*:%s*[%d%.]+', string.format('"MusicMasterVolume": %.2f', vol))
        else
            content = content:gsub("^{", string.format('{\n  "MusicMasterVolume": %.2f,', vol))
        end
        local wf = io.open(cfgPath, "w")
        if wf then wf:write(content); wf:close() end
    end)

    -- 2. Immediately update playing volume in music_state.json
    if CurrentTrack ~= "" and CurrentState == "play" then
        local finalVol = math.max(0.0, math.min(1.0, CurrentBaseVolume * vol))
        WriteState(string.format('{"state":"play","track":"%s","loop":%s,"volume":%.2f}', CurrentTrack, CurrentLoop and "true" or "false", finalVol))
    end

    print(string.format("[WorldBossAuraSystem] 🎵 Master Volume set to: %d%%", math.floor(vol * 100 + 0.5)))
end

function BossMusic.ToggleMute()
    if CurrentMasterVolume > 0.01 then
        BossMusic.SetMasterVolume(0.0)
    else
        BossMusic.SetMasterVolume(LastUnmutedVolume > 0.05 and LastUnmutedVolume or 0.15)
    end
end

function BossMusic.SetTrack(trackName, loop, volume)
    EnsureJukeboxRunning()
    local requestedBaseVolume = volume or 0.65
    local requestedLoop = loop and true or false
    if CurrentTrack == trackName and CurrentState == "play" and
       CurrentBaseVolume == requestedBaseVolume and CurrentLoop == requestedLoop then
        return
    end

    CurrentTrack = trackName
    CurrentState = "play"
    CurrentBaseVolume = requestedBaseVolume
    CurrentLoop = requestedLoop
    Performance.Count("music_track_transitions")

    local master = GetMasterVolume()
    local finalVol = math.max(0.0, math.min(1.0, CurrentBaseVolume * master))

    WriteState(string.format('{"state":"play","track":"%s","loop":%s,"volume":%.2f}', trackName, CurrentLoop and "true" or "false", finalVol))
    print(string.format("[WorldBossAuraSystem] 🎵 Jukebox playing: %s (Loop: %s, Vol: %.2f [Master: %.2f])", trackName, tostring(loop), finalVol, master))
end

function BossMusic.FadeOut()
    if CurrentState == "fade_out" then return end
    CurrentTrack = ""
    CurrentState = "fade_out"
    Performance.Count("music_fade_outs")

    WriteState('{"state":"fade_out"}')
    print("[WorldBossAuraSystem] 🎵 Jukebox fading out.")
end

function BossMusic.PlayVictoryFanfare()
    ActiveMajorBossCombat = false
    ActiveFieldBossCombat = false
    ActiveNearBoss = false
    LastMajorBossCombatTime = 0
    LastFieldBossCombatTime = 0
    VictoryTimer = os.time() + 6 -- 6 seconds fanfare
    BossMusic.SetTrack("victory_fanfare.mp3", false, 0.75)
end

function BossMusic.PlayHeadshotSFX()
    local now = os.clock()
    if now - LastHeadshotSfxTime < 0.15 then return end
    LastHeadshotSfxTime = now
    Performance.Count("headshot_sfx_requests")
    pcall(function()
        EnsureJukeboxRunning()
        local pipe = io.open([[\.\pipe\PalHeadshotPipe]], "w")
        if pipe then
            pipe:write("1")
            pipe:flush()
            pipe:close()
        end
    end)
end

local function GetLocalPlayer()
    local player = nil
    pcall(function()
        if UEHelpers and UEHelpers.GetPlayerController then
            local pc = UEHelpers.GetPlayerController()
            if pc and pc:IsValid() and pc.Pawn and pc.Pawn:IsValid() then
                player = pc.Pawn
                return
            end
        end
        local p = FindFirstOf("PalPlayerCharacter")
        if p and p:IsValid() then player = p end
    end)
    return player
end

local function ClassifyBoss(actor)
    local startedAt = Performance.Start()
    local isMajor = false
    local isField = false
    local cacheKey = nil
    pcall(function()
        if actor and type(actor.get_address) == "function" then cacheKey = tostring(actor:get_address())
        elseif actor and type(actor.GetAddress) == "function" then cacheKey = tostring(actor:GetAddress()) end
    end)
    local cached = cacheKey and BossClassificationCache[cacheKey] or nil
    if cached then
        Performance.Count("boss_classification_cache_hits")
        Performance.Finish("boss_classification", startedAt, true)
        return cached.Major, cached.Field
    end

    pcall(function()
        if not actor or not actor:IsValid() then return end
        if type(actor.IsTowerBoss) == "function" and actor:IsTowerBoss() then
            isMajor = true
            return
        end
        if type(actor.IsBoss) == "function" and actor:IsBoss() then
            local level = 1
            if actor.CharacterParameterComponent and actor.CharacterParameterComponent:IsValid() then
                level = actor.CharacterParameterComponent:GetLevel() or 1
            end
            if level >= 50 then isMajor = true else isField = true end
            return
        end
        if type(actor.IsRarePal) == "function" and actor:IsRarePal() then
            isField = true
        end
    end)
    if cacheKey then BossClassificationCache[cacheKey] = { Major = isMajor, Field = isField } end
    Performance.Count("boss_classification_cache_misses")
    Performance.Finish("boss_classification", startedAt, true)
    return isMajor, isField
end

local function ForgetBossClassification(actor)
    pcall(function()
        local key = type(actor.get_address) == "function" and tostring(actor:get_address())
            or (type(actor.GetAddress) == "function" and tostring(actor:GetAddress()) or nil)
        if key then BossClassificationCache[key] = nil end
    end)
end

local function IsNearLocalPlayer(actor, radius)
    local near = false
    pcall(function()
        local player = GetLocalPlayer()
        if not player or not player:IsValid() or not actor or not actor:IsValid() then return end
        local playerLoc = player:K2_GetActorLocation()
        local actorLoc = actor:K2_GetActorLocation()
        if not playerLoc or not actorLoc then return end
        local dx = playerLoc.X - actorLoc.X
        local dy = playerLoc.Y - actorLoc.Y
        local dz = playerLoc.Z - actorLoc.Z
        near = (dx*dx + dy*dy + dz*dz) <= (radius * radius)
    end)
    return near
end

local CachedBases = {}
local LastBaseScan = 0
local CachedTimeManager = nil

local function ClearWorldCaches()
    CachedBases = {}
    LastBaseScan = 0
    CachedTimeManager = nil
    BossClassificationCache = {}
end

local function RefreshBaseCaches()
    local startedAt = Performance.Start()
    local ok = pcall(function()
        local list = {}
        local boxClasses = { "BP_PalBox_C", "PalMapObjectBaseCampPoint", "BP_BaseCampPoint_C" }
        for _, cls in ipairs(boxClasses) do
            local boxes = FindAllOf and FindAllOf(cls)
            if boxes then
                for _, b in ipairs(boxes) do
                    if b and b:IsValid() then
                        local loc = b:K2_GetActorLocation()
                        if loc then table.insert(list, { X = loc.X, Y = loc.Y }) end
                    end
                end
            end
        end
        local camps = FindAllOf and FindAllOf("PalBaseCampModel")
        if camps then
            for _, c in ipairs(camps) do
                if c and c:IsValid() and type(c.GetLocation) == "function" then
                    local loc = c:GetLocation()
                    if loc then table.insert(list, { X = loc.X, Y = loc.Y }) end
                end
            end
        end
        CachedBases = list
    end)
    Performance.Finish("base_cache_refresh", startedAt, ok)
end

local function DetermineRegionTrack(playerLoc, player)
    -- 1. Check if inside Dungeon / Underground Cave instance
    if playerLoc.Z < -30000.0 then
        return "dungeon_weird_place.mp3", 0.65
    end

    -- 2. Base Camp Detection (Checks cached coordinates without hitching)
    local inBase = false
    local now = os.time()
    if LastBaseScan == 0 or (now - LastBaseScan >= BaseScanIntervalSeconds) then
        LastBaseScan = now
        RefreshBaseCaches()
    end

    for _, bLoc in ipairs(CachedBases) do
        local dx = playerLoc.X - bLoc.X
        local dy = playerLoc.Y - bLoc.Y
        if (dx*dx + dy*dy) <= (3800.0 * 3800.0) then
            inBase = true
            break
        end
    end

    if inBase then
        return "base_the_first_town.mp3", 0.60
    end
    -- 3. Biome Coordinates Mapping (Based on verified Palworld world grid)
    local X = playerLoc.X
    local Y = playerLoc.Y

    -- Astral Mountains (Frozen North / Arctic Tundra - Far Northwest only)
    if X < -280000 and Y > 200000 then
        return "region_snow.mp3", 0.60
    end

    -- Mount Obsidian (Volcano: Far Southwest)
    if X < -80000 and Y < -160000 then
        return "region_volcano.mp3", 0.65
    end

    -- Desolate Dunes (Far Northeast Desert)
    if X > 100000 and Y > 60000 then
        return "region_desert.mp3", 0.60
    end

    -- Windswept Hills / Grassy Plains / Starting Plateau / Central Islands
    return "region_aincrad.mp3", 0.60
end

local function IsNightTime()
    local isNight = false
    pcall(function()
        if not CachedTimeManager or not CachedTimeManager:IsValid() then
            CachedTimeManager = FindFirstOf("PalTimeManager") or FindFirstOf("PalWorldTimeManager")
        end
        if CachedTimeManager and CachedTimeManager:IsValid() then
            if type(CachedTimeManager.IsNight) == "function" then
                isNight = CachedTimeManager:IsNight()
                return
            end
            if type(CachedTimeManager.IsDay) == "function" then
                isNight = not CachedTimeManager:IsDay()
                return
            end
        end

        local gs = FindFirstOf("PalGameStateInGame")
        if gs and gs:IsValid() then
            if type(gs.IsNight) == "function" then
                isNight = gs:IsNight()
                return
            end
            local tm = gs.TimeManager or gs.WorldTimeManager
            if tm and tm:IsValid() then
                if type(tm.IsNight) == "function" then
                    isNight = tm:IsNight()
                    return
                end
                if type(tm.IsDay) == "function" then
                    isNight = not tm:IsDay()
                    return
                end
            end
        end
    end)
    return isNight
end

local function UpdateMusicState()
    local now = os.time()
    if now < VictoryTimer then
        return -- Fanfare is currently playing
    end

    if IsInTitle then
        BossMusic.SetTrack("title_perfect_time.mp3", true, 0.70)
        return
    end

    -- Priority 0.5: Connecting to server (silence / faded out)
    if IsConnecting then
        return
    end

    -- Priority 1: 5-Minute Aura World Boss / Tower Boss / Raid Boss Combat
    if ActiveMajorBossCombat then
        BossMusic.SetTrack("boss_theme_opm.mp3", true, 0.80)
        return
    end

    -- Priority 2: Field Boss Combat or World Boss Proximity (< 8000 units)
    if ActiveFieldBossCombat or ActiveNearBoss then
        BossMusic.SetTrack("boss_luminous_sword.mp3", true, 0.75)
        return
    end

    -- Priority 2.5: Night theme. Combat must always take precedence.
    if IsNightTime() then
        BossMusic.SetTrack("night_theme.mp3", true, 0.65)
        return
    end

    -- Priority 3: Regional / Dungeon / Base Camp Music
    local player = GetLocalPlayer()
    if player and player:IsValid() then
        local pLoc = player:K2_GetActorLocation()
        if pLoc then
            local track, vol = DetermineRegionTrack(pLoc, player)
            BossMusic.SetTrack(track, true, vol)
            return
        end
    end
end

function BossMusic.Init(config)
    Config = config or {}
    MajorBossCombatTimeout = Clamp(Config.MajorBossCombatTimeoutSeconds or 20, 5, 300)
    FieldBossCombatTimeout = Clamp(Config.FieldBossCombatTimeoutSeconds or 15, 5, 300)
    MusicScanIntervalMs = math.floor(Clamp(Config.MusicLocationScanIntervalSeconds or 5, 1, 60) * 1000)
    BaseScanIntervalSeconds = Clamp(Config.BaseScanIntervalSeconds or 30, 5, 600)
    BossCombatProximityRadius = Clamp(Config.BossCombatProximityRadius or 15000, 1000, 100000)
    WorldBossMusicRadius = Clamp(Config.WorldBossMusicRadius or 8000, 1000, 100000)
    local heartbeatInterval = Clamp(Config.JukeboxHeartbeatIntervalSeconds or 5, 2, 30)
    HeartbeatStaleSeconds = math.max(12, heartbeatInterval * 2 + 2)

    -- Dedicated servers do not have audio devices or local players!
    local src = (debug.getinfo(1, "S").source or ""):lower()
    if src:find("palserver") then
        print("[WorldBossAuraSystem] Dedicated server detected. Audio Jukebox disabled on server.")
        return
    end

    local isDedicated = false
    pcall(function()
        local kismet = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
        local world = UEHelpers and UEHelpers.GetWorldContextObject and UEHelpers.GetWorldContextObject()
        if kismet and kismet:IsValid() and world and world:IsValid() and type(kismet.IsDedicatedServer) == "function" then
            isDedicated = kismet:IsDedicatedServer(world)
        end
    end)
    if isDedicated then
        print("[WorldBossAuraSystem] Dedicated server detected via Kismet. Audio Jukebox disabled on server.")
        return
    end

    -- 1. In-Game Volume Chat Commands: /vol <0-100>, /mute, /unmute
    local LastPerfCommandText = ""
    local LastPerfCommandTime = 0
    local function ProcessVolumeChat(Context, Param1, Param2)
        local function TryGetStr(val)
            if not val then return "" end
            local s = ""
            pcall(function()
                if type(val.ToString) == "function" then s = val:ToString()
                else s = tostring(val) end
            end)
            return s
        end

        local text = TryGetStr(Param1)
        if text == "" then text = TryGetStr(Param2) end
        if text == "" and Context and Context.Message then text = TryGetStr(Context.Message) end
        text = text:lower():match("^%s*(.-)%s*$") or ""

        local perfAction = text:match("^[!/]bgmperf%s*(%a*)$")
        if perfAction ~= nil then
            local now = os.clock()
            if text == LastPerfCommandText and now - LastPerfCommandTime < 1.0 then return end
            LastPerfCommandText, LastPerfCommandTime = text, now
            if perfAction == "start" then
                Performance.Reset()
                Performance.SetEnabled(true)
                print("[WorldBossAuraSystem][Perf] Music diagnostics started.")
            elseif perfAction == "stop" then
                Performance.PrintReport()
                Performance.SetEnabled(false)
                print("[WorldBossAuraSystem][Perf] Music diagnostics stopped.")
            elseif perfAction == "reset" then
                Performance.Reset()
                print("[WorldBossAuraSystem][Perf] Counters reset.")
            else
                Performance.PrintReport()
                local metrics = io.open(MetricsFile, "r")
                if metrics then
                    print("[WorldBossAuraSystem][Perf] Jukebox " .. metrics:read("*all"))
                    metrics:close()
                else
                    print("[WorldBossAuraSystem][Perf] No jukebox metrics are available yet.")
                end
            end
            return
        end

        local volNum = text:match("^/[vV][oO][lL]%s+(%d+)") or text:match("^/[vV][oO][lL][uU][mM][eE]%s+(%d+)") or text:match("^/[mM][uU][sS][iI][cC]%s+(%d+)")
        if volNum then
            local n = tonumber(volNum)
            if n then
                BossMusic.SetMasterVolume(n / 100.0)
            end
        elseif text == "/mute" then
            BossMusic.SetMasterVolume(0.0)
        elseif text == "/unmute" then
            BossMusic.ToggleMute()
        end
    end

    pcall(RegisterHook, "/Script/Pal.PalPlayerState:EnterChat", ProcessVolumeChat)
    pcall(RegisterHook, "/Script/Pal.PalGameStateInGame:BroadcastChatMessage", ProcessVolumeChat)

    -- In-Game Volume Hotkeys: [ (Vol Down), ] (Vol Up), \ (Mute)
    if type(RegisterKeyBindAsync) == "function" and Key then
        pcall(function()
            if Key.OPEN_BRACKET then
                RegisterKeyBindAsync(Key.OPEN_BRACKET, {}, function()
                    BossMusic.SetMasterVolume(CurrentMasterVolume - 0.03)
                end)
            end
            if Key.CLOSE_BRACKET then
                RegisterKeyBindAsync(Key.CLOSE_BRACKET, {}, function()
                    BossMusic.SetMasterVolume(CurrentMasterVolume + 0.03)
                end)
            end
            if Key.BACKSLASH then
                RegisterKeyBindAsync(Key.BACKSLASH, {}, function()
                    BossMusic.ToggleMute()
                end)
            end
        end)
    end

    local function OnTitleScreen()
        IsInTitle = true
        IsConnecting = false
        ActiveMajorBossCombat = false
        ActiveFieldBossCombat = false
        ActiveNearBoss = false
        LastMajorBossCombatTime = 0
        LastFieldBossCombatTime = 0
        ClearWorldCaches()
        pcall(function()
            local settings = FindFirstOf("PalGameLocalSettings")
            if settings and settings:IsValid() and settings.AudioSettings then
                settings.AudioSettings.BGM = 0.0
            end
        end)
        BossMusic.SetTrack("title_perfect_time.mp3", true, 0.70)
    end

    local function OnConnectingToServer()
        IsInTitle = false
        IsConnecting = true
        ActiveMajorBossCombat = false
        ActiveFieldBossCombat = false
        ActiveNearBoss = false
        ClearWorldCaches()
        BossMusic.FadeOut(2.0)
    end

    local function OnJoinedWorld()
        IsInTitle = false
        IsConnecting = false
        ActiveMajorBossCombat = false
        ActiveFieldBossCombat = false
        ActiveNearBoss = false
        LastMajorBossCombatTime = 0
        LastFieldBossCombatTime = 0
        ClearWorldCaches()
        pcall(function()
            local settings = FindFirstOf("PalGameLocalSettings")
            if settings and settings:IsValid() and settings.AudioSettings then
                settings.AudioSettings.BGM = 0.0
            end
        end)
        local delay = ExecuteInGameThreadWithDelay or ExecuteWithDelay
        if delay then
            delay(500, UpdateMusicState)
            delay(2000, UpdateMusicState)
        else
            UpdateMusicState()
        end
    end

    -- 2. Title Screen & Connection Hooks
    pcall(function()
        NotifyOnNewObject("/Script/Pal.PalGameStateInTitle", function()
            OnTitleScreen()
        end)
    end)

    pcall(function()
        NotifyOnNewObject("/Script/Engine.NetConnection", function()
            OnConnectingToServer()
        end)
    end)

    pcall(RegisterHook, "/Script/Engine.PlayerController:ClientTravel", function(Context)
        OnConnectingToServer()
    end)

    pcall(RegisterHook, "/Script/Engine.PlayerController:ClientRestart", function(Context)
        OnJoinedWorld()
    end)

    -- 2. Headshot / Weak-Point Detection Helpers
    local function CheckHeadshotBone(bone)
        if not bone then return false end
        local str = ""
        pcall(function()
            if type(bone.ToString) == "function" then str = bone:ToString():lower()
            else str = tostring(bone):lower() end
        end)
        return str:find("head") or str:find("neck") or str:find("face") or str:find("jaw") or str:find("skull") or str:find("horn")
    end

    -- Hook Point Damage (e.g. projectile headshots)
    pcall(RegisterHook, "/Script/Engine.Actor:ReceivePointDamage", function(Context, Damage, DamageType, HitLocation, HitNormal, HitComponent, BoneName, ShotFromDirection, InstigatedBy, DamageCauser, HitInfo)
        pcall(function()
            if not GetLocalPlayer() then return end
            local b = BoneName and BoneName.get and BoneName:get() or BoneName
            if CheckHeadshotBone(b) then
                BossMusic.PlayHeadshotSFX()
            end
        end)
    end)

    -- Hook PalUIDamageText:Setup (triggers when critical/weakpoint damage numbers appear)
    pcall(RegisterHook, "/Script/Pal.PalUIDamageText:Setup", function(Context, Damage, bCritical, bWeakPoint)
        pcall(function()
            if not GetLocalPlayer() then return end
            local crit = bCritical and (bCritical.get and bCritical:get() or bCritical == true)
            local weak = bWeakPoint and (bWeakPoint.get and bWeakPoint:get() or bWeakPoint == true)
            if crit or weak then
                BossMusic.PlayHeadshotSFX()
            end
        end)
    end)

    -- Hook PalCharacter:OnDamage for event-driven boss combat music.
    pcall(RegisterHook, "/Script/Pal.PalCharacter:OnDamage", function(Context, DamageInfo)
        local perfStartedAt = Performance.Start()
        pcall(function()
            local victim = Context and Context.get and Context:get() or Context
            if not victim or not victim:IsValid() then return end

            if not IsNearLocalPlayer(victim, BossCombatProximityRadius) then return end
            local isMajor, isField = ClassifyBoss(victim)
            local now = os.time()

            if isMajor then
                ActiveMajorBossCombat = true
                ActiveFieldBossCombat = false
                LastMajorBossCombatTime = now
                BossMusic.SetTrack("boss_theme_opm.mp3", true, 0.80)
            elseif isField then
                ActiveFieldBossCombat = true
                LastFieldBossCombatTime = now
                BossMusic.SetTrack("boss_luminous_sword.mp3", true, 0.75)
            end
        end)
        Performance.Finish("music_damage_hook", perfStartedAt, true)
    end)

    -- 3. Boss HP UI Show
    pcall(RegisterHook, "/Script/Pal.PalUIBossHP:Show", function(Context)
        ActiveFieldBossCombat = true
        LastFieldBossCombatTime = os.time()
        BossMusic.SetTrack("boss_luminous_sword.mp3", true, 0.75)
    end)

    -- 4. Capture Success -> Victory Fanfare
    pcall(RegisterHook, "/Script/Pal.PalCaptureSubsystem:OnCaptureSuccess", function(Context, TargetPal)
        pcall(function()
            local captured = TargetPal and TargetPal.get and TargetPal:get() or TargetPal
            local isMajor, isField = ClassifyBoss(captured)
            if (isMajor or isField) and IsNearLocalPlayer(captured, BossCombatProximityRadius) then
                BossMusic.PlayVictoryFanfare()
            end
            ForgetBossClassification(captured)
        end)
    end)

    -- 5. Boss Death -> Victory Fanfare
    pcall(RegisterHook, "/Script/Pal.PalCharacter:OnDead", function(Context)
        pcall(function()
            local dead = Context and Context.get and Context:get() or Context
            if dead and dead:IsValid() then
                local isMajor, isField = ClassifyBoss(dead)
                if (isMajor or isField) and IsNearLocalPlayer(dead, BossCombatProximityRadius) then
                    BossMusic.PlayVictoryFanfare()
                end
                ForgetBossClassification(dead)
            end
        end)
    end)

    -- Initial startup: Check if player exists or at title
    local initP = GetLocalPlayer()
    local titleState = nil
    pcall(function() titleState = FindFirstOf("PalGameStateInTitle") end)
    if titleState and titleState:IsValid() then
        OnTitleScreen()
    elseif initP and initP:IsValid() then
        IsInTitle = false
        IsConnecting = false
    else
        -- Do not assume "no local player" means title: dedicated servers also
        -- have no local pawn. The title/new-world hooks will establish state.
        IsInTitle = false
    end

    -- 6. Periodic Background Loop
    local delayFunc = ExecuteInGameThreadWithDelay or ExecuteWithDelay
    if delayFunc then
        local function MusicLoop()
            local perfStartedAt = Performance.Start()
            local ok, err = pcall(function()
                local player = GetLocalPlayer()
                ActiveNearBoss = false
                if player and player:IsValid() then
                    IsInTitle = false
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then
                        local now = os.time()
                        if ActiveMajorBossCombat and (now - LastMajorBossCombatTime > MajorBossCombatTimeout) then
                            ActiveMajorBossCombat = false
                        end
                        if ActiveFieldBossCombat and (now - LastFieldBossCombatTime > FieldBossCombatTimeout) then
                            ActiveFieldBossCombat = false
                        end

                        -- Aura World Boss proximity uses cached spawn coordinates.
                        local wb = package.loaded["world_boss"]
                        if wb and wb.GetActiveBosses then
                            for _, data in pairs(wb.GetActiveBosses()) do
                                if data.Coords then
                                    local dx = pLoc.X - data.Coords.X
                                    local dy = pLoc.Y - data.Coords.Y
                                    Performance.Count("world_boss_proximity_checks")
                                    if (dx*dx + dy*dy) < (WorldBossMusicRadius * WorldBossMusicRadius) then
                                        ActiveNearBoss = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                elseif not IsConnecting then
                    local title = nil
                    pcall(function() title = FindFirstOf("PalGameStateInTitle") end)
                    IsInTitle = title and title:IsValid() or false
                end

                UpdateMusicState()
            end)
            Performance.Finish("music_update_loop", perfStartedAt, ok)
            if not ok then
                print(string.format("[WorldBossAuraSystem] Music loop error: %s", tostring(err)))
            end
            delayFunc(MusicScanIntervalMs, MusicLoop)
        end
        delayFunc(4000, MusicLoop)
    end

    print("[WorldBossAuraSystem] Universal Title, Regional, Dungeon & Boss Music System initialized.")
end

return BossMusic


