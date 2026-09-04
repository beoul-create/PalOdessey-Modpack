local MOD_NAME = "AdaptiveBGM"
local DEBUG_LOGGING = false

local function debug_log(...)
    if DEBUG_LOGGING then
        print(...)
    end
end

local function resolve_mod_root()
    -- The current script's own location is the only root that works for both
    -- normal UE4SS installs and Steam Workshop's NativeMods layout.
    local ok_info, info = pcall(function()
        return debug.getinfo(1, "S")
    end)
    local source = ok_info and info and info.source or nil
    if type(source) == "string" and string.sub(source, 1, 1) == "@" then
        local script_path = string.gsub(string.sub(source, 2), "/", "\\")
        local suffix = "\\scripts\\main.lua"
        if string.sub(string.lower(script_path), -#suffix) == suffix then
            return string.sub(script_path, 1, #script_path - #suffix)
        end
    end

    -- Kept only for unusual UE4SS builds that do not expose script source.
    local directories = IterateGameDirectories()
    if directories and directories.Game and directories.Game.Binaries then
        local binaries = directories.Game.Binaries.Win64
            or directories.Game.Binaries.WinGDK
        if binaries then
            local mods = binaries.ue4ss and binaries.ue4ss.Mods
                or binaries.Mods
            if mods and mods.__absolute_path then
                return mods.__absolute_path .. "\\AdaptiveBGM"
            end
        end
    end
    return "AdaptiveBGM"
end

local MOD_ROOT = resolve_mod_root()
local debug_switch = io.open(MOD_ROOT .. "\\debug.txt", "r")
if debug_switch then
    DEBUG_LOGGING = true
    debug_switch:close()
end

local STATE_PATH = MOD_ROOT .. "\\runtime_state.json"
local TEMP_PATH = STATE_PATH .. ".tmp"
local POLL_MS = 500
local STATE_HEARTBEAT_SECONDS = 10
local POSITION_SAMPLE_SECONDS = 1
-- IsInStage is a cached, direct player-state call. Check it separately from
-- time/temperature so walking through a dungeon entrance is detected promptly
-- without bringing back the expensive general reflection scan.
local STAGE_SAMPLE_SECONDS = 2
-- Temperature/time reflection can hitch if repeatedly scanned. Cached direct
-- reads are staggered at this relaxed cadence, so either condition changes
-- within ten seconds without putting both providers in one frame.
local CONDITION_SAMPLE_SECONDS = 5
local HOT_TEMPERATURE_THRESHOLD = 1.25
local COLD_TEMPERATURE_THRESHOLD = -1.25

local poll_pending = false
local cached_controller = nil
local cached_character = nil
local cached_temperature = nil
local cached_time_manager = nil
local cached_pal_utility = nil
local cached_runtime_time = nil
local cached_runtime_temperature = nil
local poll_stage = 0
local last_player_position = nil
local POSITION_TRAVEL_THRESHOLD = 10000.0
local logged_temperature_source = false
local logged_time_source = false
local battle_bgm_active = false
local raid_active = false
local tower_boss_active = false
local stage_active = false
local dungeon_active = false
local cinematic_active = false
local sequence_cinematic_active = false
local view_target_cinematic_active = false
local controls_cinematic_active = false
local active_sequence_players = {}
local sequence_reconciliation_requested = true
local combat_hooks = {}
local last_game_music_active = nil
local last_stage_active = nil
local last_world_active = nil
local last_collect_error = nil
local last_written_signature = nil
local last_write_timestamp = 0
local last_slow_poll_log_timestamp = 0
local last_position_sample_timestamp = 0
local last_stage_sample_timestamp = 0
local last_condition_sample_timestamp = 0
local next_condition_provider = "time"
local world_transition_generation = 0
local pending_state_snapshot = nil
local context_refresh_requested = true
local riding_refresh_requested = true
local position_refresh_requested = true
local temperature_refresh_requested = true
local time_refresh_requested = true
local hooks_refresh_requested = true
local combat_state_changed = true
local riding_before_refresh = nil
local current_state = {
    world_active = false,
    game_music_active = false,
    riding_known = false,
    riding = false,
    flying_mount_known = false,
    flying_mount = false,
    dungeon_known = false,
    dungeon_active = false,
    time_known = false,
    time = "",
    temperature_known = false,
    temperature = "",
    world_transition_generation = 0,
}

local function valid(object)
    if object == nil then return false end
    local ok, result = pcall(function() return object:IsValid() end)
    return ok and result
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function is_dedicated_server_process()
    local command = lower(tostring(os.getenv("CMDCMDLINE") or ""))
    if string.find(command, "dedicated", 1, true)
        or string.find(command, "palserver", 1, true) then
        return true
    end
    local ok, engine = pcall(function()
        return FindFirstOf("GameEngine")
    end)
    if ok and engine ~= nil then
        local ok_net, net_mode = pcall(function()
            return engine.NetMode
        end)
        -- NM_DedicatedServer == 3 in Unreal
        if ok_net and type(net_mode) == "number" and net_mode == 3 then
            return true
        end
    end
    return false
end

local function json_bool(value)
    return value and "true" or "false"
end

local function mark_world_transition(reason)
    world_transition_generation = world_transition_generation + 1
    debug_log(
        "[" .. MOD_NAME .. "] World/loading transition "
        .. tostring(world_transition_generation) .. ": " .. reason
    )
end

local function read_actor_position(actor)
    if actor == nil then return nil end
    local ok, x, y, z = pcall(function()
        local location = actor:K2_GetActorLocation()
        return location.X, location.Y, location.Z
    end)
    if ok
        and type(x) == "number"
        and type(y) == "number"
        and type(z) == "number" then
        return {x = x, y = y, z = z}
    end
    return nil
end

local function request_player_refresh()
    -- Map transitions can destroy a controller/character before UE4SS has
    -- delivered a safe post-load callback. Never call IsValid() on those old
    -- wrappers: clear them first and let refresh_player_context() discover
    -- the new local player from scratch. This deliberately replaces the old
    -- pre-teardown invalidation path, which could itself run during UObject
    -- destruction and crash the game.
    cached_controller = nil
    cached_character = nil
    cached_temperature = nil
    cached_time_manager = nil
    cached_pal_utility = nil
    cached_runtime_time = nil
    cached_runtime_temperature = nil
    last_player_position = nil
    riding_before_refresh =
        current_state.riding_known and current_state.riding or nil
    context_refresh_requested = true
    riding_refresh_requested = true
    position_refresh_requested = true
    temperature_refresh_requested = true
    time_refresh_requested = true
    hooks_refresh_requested = true
end
local function detect_position_travel(character)
    local position = read_actor_position(character)
    if not position then return end
    if last_player_position then
        local dx = position.x - last_player_position.x
        local dy = position.y - last_player_position.y
        local dz = position.z - last_player_position.z
        local distance_squared = dx * dx + dy * dy + dz * dz
        if distance_squared
            >= POSITION_TRAVEL_THRESHOLD * POSITION_TRAVEL_THRESHOLD then
            mark_world_transition("large player-position jump")
            request_player_refresh()
        end
    end
    last_player_position = position
end

local function write_state(state)
    local payload = string.format(
        '{"world_active":%s,"game_music_active":%s,"world_transition_generation":%d,' ..
        '"riding_known":%s,"riding":%s,' ..
        '"flying_mount_known":%s,"flying_mount":%s,' ..
        '"dungeon_known":%s,"dungeon_active":%s,' ..
        '"time_known":%s,"time":"%s",' ..
        '"temperature_known":%s,"temperature":"%s"}\n',
        json_bool(state.world_active),
        json_bool(state.game_music_active),
        state.world_transition_generation or world_transition_generation,
        json_bool(state.riding_known),
        json_bool(state.riding),
        json_bool(state.flying_mount_known),
        json_bool(state.flying_mount),
        json_bool(state.dungeon_known),
        json_bool(state.dungeon_active),
        json_bool(state.time_known),
        state.time or "",
        json_bool(state.temperature_known),
        state.temperature or ""
    )

    local file = io.open(TEMP_PATH, "w")
    if not file then return false end
    file:write(payload)
    file:flush()
    file:close()
    os.remove(STATE_PATH)
    return os.rename(TEMP_PATH, STATE_PATH) ~= nil
end

local function state_signature(state)
    return table.concat({
        tostring(state.world_active),
        tostring(state.game_music_active),
        tostring(state.world_transition_generation or world_transition_generation),
        tostring(state.riding_known),
        tostring(state.riding),
        tostring(state.flying_mount_known),
        tostring(state.flying_mount),
        tostring(state.dungeon_known),
        tostring(state.dungeon_active),
        tostring(state.time_known),
        tostring(state.time or ""),
        tostring(state.temperature_known),
        tostring(state.temperature or ""),
    }, "|")
end

local function write_state_if_needed(state, force)
    local signature = state_signature(state)
    local now = os.time()
    if force
        or signature ~= last_written_signature
        or now - last_write_timestamp >= STATE_HEARTBEAT_SECONDS then
        if write_state(state) then
            last_written_signature = signature
            last_write_timestamp = now
            return true
        end
        return false
    end
    return true
end

local function map_named_state(value, hot_words, cold_words, normal_words)
    local text = lower(value)
    for _, word in ipairs(hot_words) do
        if string.find(text, word, 1, true) then return "Hot" end
    end
    for _, word in ipairs(cold_words) do
        if string.find(text, word, 1, true) then return "Cold" end
    end
    for _, word in ipairs(normal_words) do
        if string.find(text, word, 1, true) then return "Normal" end
    end
    return nil
end

local function read_properties(object, visitor)
    if not valid(object) then return end
    local ok, object_class = pcall(function() return object:GetClass() end)
    if not ok then return end
    while valid(object_class) do
        local iterate_ok = pcall(function()
            object_class:ForEachProperty(function(property)
                local name = property:GetFName():ToString()
                local value_ok, value = pcall(function() return object[name] end)
                if value_ok and visitor(property, name, value) then
                    return true
                end
                return false
            end)
        end)
        if not iterate_ok then return end
        local super_ok, super = pcall(function()
            return object_class:GetSuperStruct()
        end)
        if not super_ok then break end
        object_class = super
    end
end

local function find_temperature_component(character)
    if cached_temperature ~= nil then return cached_temperature end
    read_properties(character, function(property, _, value)
        if not property:IsA(PropertyTypes.ObjectProperty) then return false end
        local ok, property_class = pcall(function()
            return property:GetPropertyClass():GetFullName()
        end)
        if ok and string.find(lower(property_class), "temperature", 1, true)
            and valid(value) then
            cached_temperature = value
            return true
        end
        return false
    end)
    if not valid(cached_temperature) then
        local candidates = {
            "PalBodyTemperatureComponent",
            "BP_TemperatureComponent_C",
            "PalTemperatureComponent",
        }
        for _, class_name in ipairs(candidates) do
            local ok, object = pcall(function() return FindFirstOf(class_name) end)
            if ok and valid(object) then
                cached_temperature = object
                break
            end
        end
    end
    return cached_temperature
end

local function map_temperature_value(value)
    if type(value) == "number" then
        if value >= HOT_TEMPERATURE_THRESHOLD then return "Hot" end
        if value <= COLD_TEMPERATURE_THRESHOLD then return "Cold" end
        return "Normal"
    end
    return map_named_state(
        value,
        {"hot", "heat", "warm", "high"},
        {"cold", "cool", "freeze", "low"},
        {"normal", "neutral", "comfort", "default"}
    )
end

local function read_temperature(character)
    local component = find_temperature_component(character)
    if component == nil then return nil end

    local ok_info, temperature_info = pcall(function()
        return component.TemperatureInfo
    end)
    if ok_info and temperature_info then
        local ok_temperature, current_temperature = pcall(function()
            return temperature_info.CurrentTemperature
        end)
        if ok_temperature and type(current_temperature) == "number" then
            if not logged_temperature_source then
                debug_log("[" .. MOD_NAME .. "] Temperature provider: PalBodyTemperatureComponent.TemperatureInfo.CurrentTemperature")
                logged_temperature_source = true
            end
            return map_temperature_value(current_temperature)
        end

        local ok_state, body_state = pcall(function()
            return temperature_info.CurrentBodyState
        end)
        if ok_state and type(body_state) == "number" then
            if body_state == 1 then return "Cold" end
            if body_state == 2 then return "Hot" end
            if body_state == 0 then return "Normal" end
        end
    end

    local methods = {
        function() return component:GetCurrentTemperatureType() end,
        function() return component:GetTemperatureType() end,
        function() return component:GetCurrentTemperature() end,
        function() return component:GetTemperature() end,
    }
    for _, method in ipairs(methods) do
        local ok, value = pcall(method)
        if ok then
            local mapped = map_temperature_value(value)
            if mapped then
                if not logged_temperature_source then
                    debug_log("[" .. MOD_NAME .. "] Temperature provider: reflected method")
                    logged_temperature_source = true
                end
                return mapped
            end
        end
    end

    local selected = nil
    local selected_score = -1
    local selected_name = nil
    read_properties(component, function(property, name, value)
        local normalized = lower(name)
        if not string.find(normalized, "temper", 1, true) then return false end
        if string.find(normalized, "target", 1, true)
            or string.find(normalized, "threshold", 1, true)
            or string.find(normalized, "max", 1, true)
            or string.find(normalized, "min", 1, true) then
            return false
        end

        local mapped = nil
        if property:IsA(PropertyTypes.EnumProperty) then
            local ok, enum_name = pcall(function()
                return property:GetEnum():GetNameByValue(value):ToString()
            end)
            if ok then mapped = map_temperature_value(enum_name) end
        elseif type(value) == "number" then
            mapped = map_temperature_value(value)
        end
        if not mapped then return false end

        local score = 10
        if string.find(normalized, "current", 1, true) then score = score + 50 end
        if string.find(normalized, "state", 1, true)
            or string.find(normalized, "type", 1, true)
            or string.find(normalized, "rank", 1, true) then
            score = score + 30
        end
        if score > selected_score then
            selected = mapped
            selected_score = score
            selected_name = name
        end
        return false
    end)
    if selected and not logged_temperature_source then
        debug_log("[" .. MOD_NAME .. "] Temperature provider property: " .. selected_name)
        logged_temperature_source = true
    end
    return selected
end

-- Fast path for the periodic sampler. It never searches properties, components,
-- or methods: lifecycle refresh is responsible for discovering the provider.
local function read_cached_temperature()
    if not valid(cached_temperature) then return nil end
    local ok_info, temperature_info = pcall(function()
        return cached_temperature.TemperatureInfo
    end)
    if not ok_info or temperature_info == nil then return nil end
    local ok_temperature, current_temperature = pcall(function()
        return temperature_info.CurrentTemperature
    end)
    if ok_temperature and type(current_temperature) == "number" then
        return map_temperature_value(current_temperature)
    end
    local ok_state, body_state = pcall(function()
        return temperature_info.CurrentBodyState
    end)
    if ok_state and type(body_state) == "number" then
        if body_state == 1 then return "Cold" end
        if body_state == 2 then return "Hot" end
        if body_state == 0 then return "Normal" end
    end
    return nil
end

local function find_time_manager()
    if cached_time_manager ~= nil then return cached_time_manager end
    local classes = {
        "BP_PalTimeManager_C",
        "PalTimeManager",
        "PalTimeManagerBase",
    }
    for _, class_name in ipairs(classes) do
        local ok, object = pcall(function() return FindFirstOf(class_name) end)
        if ok and valid(object) then
            cached_time_manager = object
            break
        end
    end
    return cached_time_manager
end

local function map_time_number(value)
    if type(value) ~= "number" then return nil end
    if value >= 0.0 and value <= 1.0 then
        return (value < 0.25 or value >= 0.75) and "Night" or "Day"
    end
    if value >= 0.0 and value < 24.0 then
        return (value < 6.0 or value >= 18.0) and "Night" or "Day"
    end
    return nil
end

local function read_time()
    local manager = find_time_manager()
    if manager == nil then return nil end

    local direct_candidates = {
        "CurrentDayTimeType",
        "NowDayTimeType",
        "DayTimeType",
    }
    for _, name in ipairs(direct_candidates) do
        local ok, value = pcall(function() return manager[name] end)
        if ok and value ~= nil then
            if type(value) == "number" then
                if value == 1 then return "Day" end
                if value == 2 then return "Night" end
            else
                local text = lower(value)
                if string.find(text, "night", 1, true) then return "Night" end
                if string.find(text, "day", 1, true) then return "Day" end
            end
        end
    end

    local ok_day_type, day_type = pcall(function()
        return manager:GetCurrentDayTimeType()
    end)
    if ok_day_type then
        if type(day_type) == "number" then
            if day_type == 1 or day_type == 2 then
                if not logged_time_source then
                    debug_log("[" .. MOD_NAME .. "] Time provider: PalTimeManager.GetCurrentDayTimeType")
                    logged_time_source = true
                end
                return day_type == 1 and "Day" or "Night"
            end
        else
            local text = lower(day_type)
            if string.find(text, "night", 1, true) then return "Night" end
            if string.find(text, "day", 1, true) then return "Day" end
        end
    end

    local boolean_methods = {
        function() return manager:IsNight() end,
        function() return not manager:IsDay() end,
    }
    for _, method in ipairs(boolean_methods) do
        local ok, is_night = pcall(method)
        if ok and type(is_night) == "boolean" then
            if not logged_time_source then
                debug_log("[" .. MOD_NAME .. "] Time provider: reflected day/night method")
                logged_time_source = true
            end
            return is_night and "Night" or "Day"
        end
    end

    local numeric_methods = {
        function() return manager:GetCurrentPalWorldTime_Hour() end,
        function() return manager:GetCurrentPalWorldHoursFloat() end,
        function() return manager:GetCurrentTime() end,
        function() return manager:GetTimeOfDay() end,
        function() return manager:GetCurrentHour() end,
    }
    for _, method in ipairs(numeric_methods) do
        local ok, value = pcall(method)
        if ok then
            local mapped = map_time_number(value)
            if mapped then
                if not logged_time_source then
                    debug_log("[" .. MOD_NAME .. "] Time provider: reflected numeric method")
                    logged_time_source = true
                end
                return mapped
            end
        end
    end

    local selected = nil
    local selected_score = -1
    local selected_name = nil
    read_properties(manager, function(property, name, value)
        local normalized = lower(name)
        local mapped = nil
        if property:IsA(PropertyTypes.BoolProperty)
            and string.find(normalized, "night", 1, true) then
            mapped = value and "Night" or "Day"
        elseif property:IsA(PropertyTypes.EnumProperty)
            and (string.find(normalized, "time", 1, true)
                or string.find(normalized, "day", 1, true)) then
            local ok, enum_name = pcall(function()
                return property:GetEnum():GetNameByValue(value):ToString()
            end)
            if ok then
                local text = lower(enum_name)
                if string.find(text, "night", 1, true) then mapped = "Night" end
                if string.find(text, "day", 1, true) then mapped = "Day" end
            end
        elseif type(value) == "number"
            and (normalized == "currenttime"
                or normalized == "timeofday"
                or normalized == "currenthour"
                or normalized == "nowtime") then
            mapped = map_time_number(value)
        end
        if not mapped then return false end
        local score = 10
        if string.find(normalized, "current", 1, true) then score = score + 20 end
        if property:IsA(PropertyTypes.BoolProperty) then score = score + 50 end
        if score > selected_score then
            selected = mapped
            selected_score = score
            selected_name = name
        end
        return false
    end)
    if selected and not logged_time_source then
        debug_log("[" .. MOD_NAME .. "] Time provider property: " .. selected_name)
        logged_time_source = true
    end
    return selected
end

-- Fast counterpart to read_time(): only cached direct properties/methods are
-- considered here. This keeps periodic updates independent of slow object
-- discovery and property enumeration.
local function read_cached_time()
    if not valid(cached_time_manager) then return nil end
    for _, name in ipairs({
        "CurrentDayTimeType",
        "NowDayTimeType",
        "DayTimeType",
    }) do
        local ok, value = pcall(function() return cached_time_manager[name] end)
        if ok and value ~= nil then
            if type(value) == "number" then
                if value == 1 then return "Day" end
                if value == 2 then return "Night" end
            else
                local text = lower(value)
                if string.find(text, "night", 1, true) then return "Night" end
                if string.find(text, "day", 1, true) then return "Day" end
            end
        end
    end
    local ok_day_type, day_type = pcall(function()
        return cached_time_manager:GetCurrentDayTimeType()
    end)
    if ok_day_type and type(day_type) == "number" then
        if day_type == 1 then return "Day" end
        if day_type == 2 then return "Night" end
    end
    return nil
end

local function hook_combat_event(key, path, callback)
    if combat_hooks[key] then return true end
    local ok, pre_id = pcall(function()
        return RegisterHook(path, callback)
    end)
    if ok and pre_id then
        combat_hooks[key] = true
        return true
    end
    return false
end

local function sequence_player_key(player)
    local ok_address, address = pcall(function() return player:GetAddress() end)
    if not ok then address = tostring(player) end
    return tostring(address)
end

local function track_sequence_player(player, source)
    if not valid(player) then return nil end
    local key = sequence_player_key(player)
    local entry = active_sequence_players[key]
    if not entry then
        entry = {player = player, playing = false}
        active_sequence_players[key] = entry
        debug_log(
            "[" .. MOD_NAME .. "] Level sequence discovered via "
            .. tostring(source) .. ": " .. key
        )
    end
    return entry
end

local function remember_sequence_player(context)
    local ok, player = pcall(function() return context:get() end)
    if not ok then return end
    local entry = track_sequence_player(player, "play hook")
    if not entry then return end
    entry.playing = true
    sequence_cinematic_active = true
    combat_state_changed = true
    debug_log(
        "[" .. MOD_NAME .. "] Level sequence playing: "
        .. sequence_player_key(player)
    )
end

local function reconcile_sequence_players()
    sequence_reconciliation_requested = false
    local ok, players = pcall(function()
        return FindAllOf("LevelSequencePlayer")
    end)
    if not ok or not players then return end
    for _, player in pairs(players) do
        track_sequence_player(player, "world reconciliation")
    end
end

local function refresh_sequence_cinematic_state()
    local any_playing = false
    for key, entry in pairs(active_sequence_players) do
        local player = entry.player
        if not valid(player) then
            active_sequence_players[key] = nil
        else
            local ok, playing = pcall(function()
                return player:IsPlaying()
            end)
            if ok and playing == true then
                any_playing = true
                if not entry.playing then
                    entry.playing = true
                    debug_log(
                        "[" .. MOD_NAME .. "] Level sequence playing: " .. key
                    )
                end
            elseif entry.playing then
                entry.playing = false
                debug_log(
                    "[" .. MOD_NAME .. "] Level sequence finished: " .. key
                )
            end
        end
    end
    if sequence_cinematic_active ~= any_playing then
        sequence_cinematic_active = any_playing
        combat_state_changed = true
    end
end

local function class_name(object)
    if not valid(object) then return "" end
    local ok, name = pcall(function()
        return object:GetClass():GetFName():ToString()
    end)
    return ok and lower(name) or ""
end

local function is_cinematic_view_target(target)
    local name = class_name(target)
    return string.find(name, "cinecamera", 1, true) ~= nil
        or string.find(name, "cameraactor", 1, true) ~= nil
end

local function set_view_target_cinematic(target)
    local active = is_cinematic_view_target(target)
    if view_target_cinematic_active ~= active then
        view_target_cinematic_active = active
        combat_state_changed = true
        debug_log(
            "[" .. MOD_NAME .. "] Cinematic camera active: "
            .. tostring(active) .. " (" .. class_name(target) .. ")"
        )
    end
end

local function refresh_view_target_cinematic()
    if not valid(cached_controller) then return end
    local ok, target = pcall(function()
        return cached_controller:GetViewTarget()
    end)
    if ok then set_view_target_cinematic(target) end
end

local function refresh_control_lock_cinematic()
    if not valid(cached_controller) then return end
    local move_ok, move_ignored = pcall(function()
        return cached_controller:IsMoveInputIgnored()
    end)
    local look_ok, look_ignored = pcall(function()
        return cached_controller:IsLookInputIgnored()
    end)
    local active = move_ok and look_ok
        and move_ignored == true and look_ignored == true
    if controls_cinematic_active ~= active then
        controls_cinematic_active = active
        combat_state_changed = true
        debug_log(
            "[" .. MOD_NAME .. "] Player controls locked: "
            .. tostring(active)
        )
    end
end

local function suppression_active()
    if _G.PalOdysseyBossAudio_Active then return true end
    return battle_bgm_active or raid_active or tower_boss_active
        -- IsInStage covers both ordinary dungeons and towers. Only a positive
        -- dungeon identification may release stage suppression.
        or (stage_active and not dungeon_active)
        -- These are explicit, game-owned signals. Camera targets, input locks,
        -- and arbitrary LevelSequence players are deliberately excluded: all
        -- three can remain active during ordinary exploration and previously
        -- left AdaptiveBGM blocked forever after returning to the world.
        or cinematic_active
end

local function register_combat_hooks()
    hook_combat_event(
        "client_travel",
        "/Script/Engine.PlayerController:ClientTravel",
        function() request_player_refresh() end
    )
    hook_combat_event(
        "view_target_blend",
        "/Script/Engine.PlayerController:SetViewTargetWithBlend",
        function(_, target_parameter)
            local ok, target = pcall(function()
                return target_parameter:get()
            end)
            if ok then set_view_target_cinematic(target) end
        end
    )
    hook_combat_event(
        "level_sequence_play",
        "/Script/MovieScene.MovieSceneSequencePlayer:Play",
        function(context) remember_sequence_player(context) end
    )
    hook_combat_event(
        "level_sequence_play_reverse",
        "/Script/MovieScene.MovieSceneSequencePlayer:PlayReverse",
        function(context) remember_sequence_player(context) end
    )
    hook_combat_event(
        "cinematic_mode",
        "/Script/Engine.PlayerController:SetCinematicMode",
        function(_, enabled_parameter)
            local ok, enabled = pcall(function()
                return enabled_parameter:get()
            end)
            if ok and type(enabled) == "boolean" then
                cinematic_active = enabled
                combat_state_changed = true
            end
        end
    )
    hook_combat_event(
        "battle_bgm",
        "/Script/Pal.PalPlayerCharacter:OnChangeBattleBGM",
        function(_, rank_parameter)
            local ok, rank = pcall(function() return rank_parameter:get() end)
            if ok and type(rank) == "number" then
                battle_bgm_active = rank ~= 0
                combat_state_changed = true
            end
        end
    )
    hook_combat_event(
        "raid_start",
        "/Game/Pal/Blueprint/Audio/BP_PalAudioWorldSubsystem.BP_PalAudioWorldSubsystem_C:OnStartRaid",
        function()
            raid_active = true
            combat_state_changed = true
        end
    )
    hook_combat_event(
        "raid_arrived",
        "/Game/Pal/Blueprint/Audio/BP_PalAudioWorldSubsystem.BP_PalAudioWorldSubsystem_C:OnArrivedRaid",
        function()
            raid_active = true
            combat_state_changed = true
        end
    )
    hook_combat_event(
        "raid_end",
        "/Game/Pal/Blueprint/Audio/BP_PalAudioWorldSubsystem.BP_PalAudioWorldSubsystem_C:OnEndRaid",
        function()
            raid_active = false
            combat_state_changed = true
        end
    )
    hook_combat_event(
        "tower_boss",
        "/Game/Pal/Model/Other/Tower/BP_PalBossTower.BP_PalBossTower_C:OnChangeBossBattleStateBP",
        function(_, new_state)
            local ok, value = pcall(function() return new_state:get() end)
            if ok then
                if value == 1 then tower_boss_active = true end
                if value == 0 then tower_boss_active = false end
                combat_state_changed = true
            end
        end
    )
end

local function read_battle_bgm_rank(character)
    local ok_situation, situation = pcall(function()
        return character.PlayerBattleSituation
    end)
    if not ok_situation or not valid(situation) then
        return battle_bgm_active
    end

    local ok_rank, rank = pcall(function()
        return situation.CurrentMaxRank
    end)
    if ok_rank and type(rank) == "number" then
        battle_bgm_active = rank ~= 0
        return battle_bgm_active
    end

    local active = false
    read_properties(situation, function(property, name, value)
        if name ~= "CurrentMaxRank" then return false end
        if type(value) == "number" then
            active = value ~= 0
        elseif property:IsA(PropertyTypes.EnumProperty) then
            local enum_ok, enum_name = pcall(function()
                return property:GetEnum():GetNameByValue(value):ToString()
            end)
            if enum_ok then
                local normalized = lower(enum_name)
                active = not string.find(normalized, "none", 1, true)
            end
        end
        return true
    end)
    battle_bgm_active = active
    return active
end

local function read_cinematic_active()
    if not valid(cached_controller) then return cinematic_active end
    local ok, enabled = pcall(function()
        return cached_controller.bCinematicMode
    end)
    if ok and type(enabled) == "boolean" then return enabled end
    return cinematic_active
end

local function read_stage_active()
    local player_state = nil
    if valid(cached_controller) then
        local ok_player_state, reflected_player_state = pcall(function()
            return cached_controller.PlayerState
        end)
        if ok_player_state and valid(reflected_player_state) then
            player_state = reflected_player_state
        end
    end
    if not valid(player_state) and valid(cached_character) then
        if not valid(cached_pal_utility) then
            local ok_utility, utility = pcall(function()
                return StaticFindObject("/Script/Pal.Default__PalUtility")
            end)
            if ok_utility and valid(utility) then
                cached_pal_utility = utility
            end
        end
        if valid(cached_pal_utility) then
            local ok_player_state, reflected_player_state = pcall(function()
                return cached_pal_utility:GetPlayerStateByPlayer(
                    cached_character
                )
            end)
            if ok_player_state and valid(reflected_player_state) then
                player_state = reflected_player_state
            end
        end
    end
    if not valid(player_state) then return false end
    local ok_stage, in_stage = pcall(function()
        return player_state:IsInStage()
    end)
    return ok_stage and type(in_stage) == "boolean" and in_stage
end

local function object_name(object)
    if object == nil then return "" end
    local ok_name, name = pcall(function() return object:GetName() end)
    if ok_name and name ~= nil then return lower(name) end
    local ok_string, text = pcall(function() return object:ToString() end)
    if ok_string and text ~= nil then return lower(text) end
    return lower(object)
end

local function current_world_identity()
    if not valid(cached_character) then return "", nil end
    local ok_world, world = pcall(function() return cached_character:GetWorld() end)
    if not ok_world or not valid(world) then return "", nil end

    local parts = {object_name(world)}
    local ok_outer, outer = pcall(function() return world:GetOutermost() end)
    if ok_outer and outer ~= nil then table.insert(parts, object_name(outer)) end
    local ok_map, map_name = pcall(function() return world:GetMapName() end)
    if ok_map and map_name ~= nil then table.insert(parts, lower(map_name)) end
    return table.concat(parts, " "), world
end

local function is_tower_identity(identity)
    return string.find(identity, "tower", 1, true) ~= nil
        or string.find(identity, "bossbattle", 1, true) ~= nil
end

local function is_dungeon_identity(identity)
    return not is_tower_identity(identity)
        and string.find(identity, "dungeon", 1, true) ~= nil
end

local function dungeon_instance_in_current_world(world)
    if not valid(world) then return false end
    for _, class_name in ipairs({
        "PalDungeonInstance",
        "PalDungeonInstanceModel",
        "BP_PalDungeonInstance_C",
    }) do
        local ok_instances, instances = pcall(function()
            return FindAllOf(class_name)
        end)
        if ok_instances and instances then
            for _, instance in pairs(instances) do
                if valid(instance) then
                    local ok_instance_world, instance_world = pcall(function()
                        return instance:GetWorld()
                    end)
                    if ok_instance_world and valid(instance_world)
                        and object_name(instance_world) == object_name(world) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Returns (known, active). IsInStage is Palworld's reliable ordinary-dungeon
-- signal in current builds; regular dungeon maps do not consistently include
-- "dungeon" in their reflected identity or expose a PalDungeonInstance.
-- Explicit tower maps remain blocked, while battle, raid, and cinematic
-- suppression continues to protect game-owned boss/cutscene audio.
local function read_dungeon_state(in_stage)
    if not in_stage then return true, false end
    local identity, world = current_world_identity()
    if is_tower_identity(identity) then return true, false end
    if is_dungeon_identity(identity)
        or dungeon_instance_in_current_world(world) then
        return true, true
    end
    return true, true
end

-- Dungeon identity discovery can involve a FindAllOf fallback, so perform it
-- only when the direct IsInStage signal changes (or a new player context is
-- created). The regular two-second probe itself is just the cached direct
-- IsInStage call.
local function refresh_stage_state(force_resolution)
    local detected_stage = read_stage_active()
    local stage_changed = detected_stage ~= stage_active
    if not stage_changed and not force_resolution then return false end

    stage_active = detected_stage
    local dungeon_known, detected_dungeon = read_dungeon_state(stage_active)
    current_state.dungeon_known = dungeon_known
    current_state.dungeon_active = detected_dungeon
    dungeon_active = detected_dungeon

    if stage_changed or force_resolution then
        if stage_active ~= last_stage_active then
            debug_log(
                "[" .. MOD_NAME .. "] Instanced stage active: "
                .. tostring(stage_active)
            )
            last_stage_active = stage_active
        end
    end
    return stage_changed
end

local function controlled_mount_pal()
    return nil
end

local function read_flying_mount_capability(riding)
    if not riding then return true, false end
    if not valid(cached_controller) then return true, false end

    local ok_direct, direct = pcall(function()
        return cached_controller:IsRidingFlyPal()
    end)
    if ok_direct and type(direct) == "boolean" then
        return true, direct
    end
    return true, false
end

local function character_for_controller(controller)
    if not valid(controller) then return nil end
    local ok_character, character = pcall(function()
        return controller.Character
    end)
    if ok_character and valid(character) then return character end

    local ok_pawn, pawn = pcall(function() return controller:GetPawn() end)
    if ok_pawn and valid(pawn) then return pawn end
    return nil
end

local function is_local_controller(controller)
    local ok, result = pcall(function()
        return controller:IsLocalController()
    end)
    return ok and result
end

local function refresh_player_context()
    if valid(cached_controller) and valid(cached_character) then
        return true
    end

    local ok_all, controllers = pcall(function()
        return FindAllOf("PalPlayerController")
    end)
    if ok_all and controllers then
        for _, require_local in ipairs({true, false}) do
            for _, controller in pairs(controllers) do
                local character = character_for_controller(controller)
                if valid(character)
                    and (not require_local or is_local_controller(controller)) then
                    cached_controller = controller
                    if cached_character ~= character then
                        cached_character = character
                        cached_temperature = nil
                        cached_runtime_temperature = nil
                    end
                    return true
                end
            end
        end
    end

    cached_controller = nil
    cached_character = nil
    cached_temperature = nil
    return false
end
local function copy_current_state()
    return {
        world_active = current_state.world_active,
        game_music_active = current_state.game_music_active,
        riding_known = current_state.riding_known,
        riding = current_state.riding,
        flying_mount_known = current_state.flying_mount_known,
        flying_mount = current_state.flying_mount,
        dungeon_known = current_state.dungeon_known,
        dungeon_active = current_state.dungeon_active,
        time_known = current_state.time_known,
        time = current_state.time,
        temperature_known = current_state.temperature_known,
        temperature = current_state.temperature,
        world_transition_generation = world_transition_generation,
    }
end

local function invalidate_world(reason)
    if current_state.world_active then
        mark_world_transition(reason)
    end
    current_state.world_active = false
    current_state.game_music_active = false
    stage_active = false
    dungeon_active = false
    cinematic_active = false
    sequence_cinematic_active = false
    view_target_cinematic_active = false
    controls_cinematic_active = false
    active_sequence_players = {}
    sequence_reconciliation_requested = true
    current_state.riding_known = false
    current_state.flying_mount_known = false
    current_state.dungeon_known = false
    current_state.dungeon_active = false
    current_state.time_known = false
    current_state.temperature_known = false
    cached_controller = nil
    cached_character = nil
    cached_temperature = nil
    cached_time_manager = nil
    cached_runtime_time = nil
    cached_runtime_temperature = nil
    last_player_position = nil
    context_refresh_requested = false
    riding_refresh_requested = false
    position_refresh_requested = false
    temperature_refresh_requested = false
    time_refresh_requested = false
    pending_state_snapshot = copy_current_state()
end

local function collect_state_stage()
    poll_stage = (poll_stage + 1) % 5

    if poll_stage == 0 then
        if hooks_refresh_requested then
            hooks_refresh_requested = false
            register_combat_hooks()
        end
        local context_refreshed = false
        if context_refresh_requested or not current_state.world_active then
            if not refresh_player_context() then
                current_state.world_active = false
                current_state.game_music_active = false
                current_state.riding_known = false
                current_state.flying_mount_known = false
                current_state.dungeon_known = false
                current_state.dungeon_active = false
                current_state.time_known = false
                current_state.temperature_known = false
                return
            end
            context_refresh_requested = false
            context_refreshed = true
        end

        current_state.world_active = true
        local battle_active = suppression_active()
        if context_refreshed then
            refresh_stage_state(true)
            cinematic_active = read_cinematic_active()
            local battle_ok, reflected_active =
                pcall(read_battle_bgm_rank, cached_character)
            if battle_ok then battle_active = reflected_active end
        end
        battle_active = battle_active or suppression_active()
        current_state.game_music_active = battle_active
        if current_state.game_music_active ~= last_game_music_active then
            debug_log(
                "[" .. MOD_NAME .. "] Palworld priority audio/cutscene active: "
                .. tostring(current_state.game_music_active)
            )
            last_game_music_active = current_state.game_music_active
        end
    elseif not current_state.world_active then
        return
    elseif poll_stage == 1 then
        if not riding_refresh_requested then return end
        local ok_riding, riding = pcall(function()
            return cached_controller:IsRiding()
        end)
        if ok_riding and type(riding) == "boolean" then
            riding_refresh_requested = false
            current_state.riding_known = true
            current_state.riding = riding
            local flying_known, flying =
                read_flying_mount_capability(riding)
            current_state.flying_mount_known = flying_known
            current_state.flying_mount = flying
            if riding then
                debug_log(
                    "[" .. MOD_NAME .. "] Mounted Pal capability: "
                    .. (flying_known
                        and (flying and "Flying" or "Riding")
                        or "Unknown")
                )
            end
        else
            context_refresh_requested = true
        end
    elseif poll_stage == 2 then
        if position_refresh_requested then
            position_refresh_requested = false
            local riding_changed =
                riding_before_refresh ~= nil
                and current_state.riding_known
                and riding_before_refresh ~= current_state.riding
            if not riding_changed then
                detect_position_travel(cached_character)
            end
            riding_before_refresh = nil
        end
    elseif poll_stage == 3 then
        if not temperature_refresh_requested then return end
        temperature_refresh_requested = false
        local temperature_ok, temperature =
            pcall(read_temperature, cached_character)
        if temperature_ok and temperature then
            cached_runtime_temperature = temperature
            current_state.temperature_known = true
            current_state.temperature = temperature
        end
    elseif poll_stage == 4 then
        if not time_refresh_requested then return end
        time_refresh_requested = false
        local time_ok, time = pcall(read_time)
        if time_ok and time then
            cached_runtime_time = time
            current_state.time_known = true
            current_state.time = time
        end
    end
end

local function poll()
    if pending_state_snapshot then
        write_state_if_needed(pending_state_snapshot, false)
        pending_state_snapshot = nil
    end
    if combat_state_changed then
        combat_state_changed = false
        current_state.game_music_active = suppression_active()
        pending_state_snapshot = copy_current_state()
    end
    local work_requested =
        context_refresh_requested
        or riding_refresh_requested
        or position_refresh_requested
        or temperature_refresh_requested
        or time_refresh_requested
        or hooks_refresh_requested
    local now = os.time()
    local stage_due = not work_requested
        and current_state.world_active
        and now - last_stage_sample_timestamp >= STAGE_SAMPLE_SECONDS
    if stage_due then
        if poll_pending then return end
        poll_pending = true
        last_stage_sample_timestamp = now
        ExecuteInGameThread(function()
            local ok, error_text = pcall(function()
                refresh_stage_state(false)
                current_state.game_music_active = suppression_active()
            end)
            if not ok and tostring(error_text) ~= last_collect_error then
                debug_log(
                    "[" .. MOD_NAME .. "] Stage refresh error: "
                    .. tostring(error_text)
                )
                last_collect_error = tostring(error_text)
            end
            pending_state_snapshot = copy_current_state()
            poll_pending = false
        end)
        return
    end
    local condition_due = not work_requested
        and current_state.world_active
        and now - last_condition_sample_timestamp
            >= CONDITION_SAMPLE_SECONDS
    if condition_due then
        if poll_pending then return end
        poll_pending = true
        last_condition_sample_timestamp = now
        ExecuteInGameThread(function()
            local ok, error_text = pcall(function()
                if next_condition_provider == "time" then
                    next_condition_provider = "temperature"
                    local time = read_cached_time()
                    if time then
                        current_state.time_known = true
                        current_state.time = time
                    end
                else
                    next_condition_provider = "time"
                    local temperature = read_cached_temperature()
                    if temperature then
                        current_state.temperature_known = true
                        current_state.temperature = temperature
                    end
                end
            end)
            if not ok and tostring(error_text) ~= last_collect_error then
                debug_log(
                    "[" .. MOD_NAME .. "] Cached condition refresh error: "
                    .. tostring(error_text)
                )
                last_collect_error = tostring(error_text)
            end
            pending_state_snapshot = copy_current_state()
            poll_pending = false
        end)
        return
    end
    if not work_requested
        and current_state.world_active
        and cached_character ~= nil
        and now - last_position_sample_timestamp
            >= POSITION_SAMPLE_SECONDS then
        if poll_pending then return end
        poll_pending = true
        last_position_sample_timestamp = now
        ExecuteInGameThread(function()
            local ok, error_text = pcall(function()
                if valid(cached_controller) then
                    local ok_riding, riding = pcall(function()
                        return cached_controller:IsRiding()
                    end)
                    if ok_riding and type(riding) == "boolean" then
                        local riding_changed =
                            not current_state.riding_known
                            or current_state.riding ~= riding
                        current_state.riding_known = true
                        current_state.riding = riding
                        if riding_changed or riding then
                            local flying_known, flying =
                                read_flying_mount_capability(riding)
                            local flying_changed =
                                current_state.flying_mount_known
                                    ~= flying_known
                                or current_state.flying_mount ~= flying
                            current_state.flying_mount_known = flying_known
                            current_state.flying_mount = flying
                            if riding_changed then
                                debug_log(
                                    "[" .. MOD_NAME
                                    .. "] Mounted state: "
                                    .. (riding
                                        and (flying and "Flying" or "Riding")
                                        or "On foot")
                                )
                            elseif flying_changed and riding then
                                debug_log(
                                    "[" .. MOD_NAME
                                    .. "] Mount capability updated: "
                                    .. (flying and "Flying" or "Riding")
                                )
                            end
                        else
                            current_state.flying_mount_known = true
                            current_state.flying_mount = false
                        end
                    end
                end
                detect_position_travel(cached_character)
            end)
            if not ok and tostring(error_text) ~= last_collect_error then
                debug_log(
                    "[" .. MOD_NAME .. "] Position sample error: "
                    .. tostring(error_text)
                )
                last_collect_error = tostring(error_text)
            end
            pending_state_snapshot = copy_current_state()
            poll_pending = false
        end)
        return
    end
    if not work_requested then
        write_state_if_needed(copy_current_state(), false)
        return
    end
    if poll_pending then return end
    poll_pending = true
    ExecuteInGameThread(function()
        local poll_started = os.clock()
        local ok, state = pcall(collect_state_stage)
        if ok then
            last_collect_error = nil
            if current_state.world_active ~= last_world_active then
                if last_world_active == true
                    and not current_state.world_active then
                    mark_world_transition("active world lost")
                end
                debug_log(
                    "[" .. MOD_NAME .. "] Active player world: "
                    .. tostring(current_state.world_active)
                )
                last_world_active = current_state.world_active
            end
            pending_state_snapshot = copy_current_state()
        else
            local error_text = tostring(state)
            if error_text ~= last_collect_error then
                debug_log("[" .. MOD_NAME .. "] State collection error: " .. error_text)
                last_collect_error = error_text
            end
            pending_state_snapshot = {
                world_active = false,
                game_music_active = false,
                riding_known = false,
                riding = false,
                flying_mount_known = false,
                flying_mount = false,
                dungeon_known = false,
                dungeon_active = false,
                time_known = false,
                time = "",
                temperature_known = false,
                temperature = "",
                world_transition_generation = world_transition_generation,
            }
        end
        local poll_elapsed_ms = (os.clock() - poll_started) * 1000.0
        local now = os.time()
        if poll_elapsed_ms >= 8.0
            and now - last_slow_poll_log_timestamp >= 30 then
            debug_log(
                string.format(
                    "[" .. MOD_NAME .. "] Slow state poll stage %d: %.2f ms",
                    poll_stage,
                    poll_elapsed_ms
                )
            )
            last_slow_poll_log_timestamp = now
        end
        poll_pending = false
    end)
end

write_state_if_needed({
    world_active = false,
    game_music_active = false,
    riding_known = false,
    riding = false,
    flying_mount_known = false,
    flying_mount = false,
    dungeon_known = false,
    dungeon_active = false,
    time_known = false,
    time = "",
    temperature_known = false,
    temperature = "",
    world_transition_generation = world_transition_generation,
}, true)

if is_dedicated_server_process() then
    debug_log("[" .. MOD_NAME .. "] Dedicated server detected; bridge idle")
    return
end

local sequence_notify_ok = pcall(function()
    NotifyOnNewObject(
        "/Script/LevelSequence.LevelSequencePlayer",
        function(player)
            track_sequence_player(player, "object notification")
        end
    )
end)
debug_log(
    "[" .. MOD_NAME .. "] Level sequence notifications: "
    .. tostring(sequence_notify_ok)
)

local load_post_ok = pcall(function()
    RegisterLoadMapPostHook(function()
        request_player_refresh()
    end)
end)
local game_state_post_ok = pcall(function()
    RegisterInitGameStatePostHook(function()
        request_player_refresh()
    end)
end)
debug_log(
    "[" .. MOD_NAME .. "] Lifecycle hooks: load-post="
    .. tostring(load_post_ok)
    .. ", game-state-post=" .. tostring(game_state_post_ok)
    .. " (pre-teardown hooks intentionally disabled)"
)

LoopAsync(POLL_MS, function()
    poll()
    return false
end)

debug_log("[" .. MOD_NAME .. "] State provider started")
