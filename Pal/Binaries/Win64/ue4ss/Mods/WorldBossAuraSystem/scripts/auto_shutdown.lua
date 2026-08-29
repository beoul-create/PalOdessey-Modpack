local AutoShutdown = {}

local IDLE_TIMEOUT_SECONDS = 900 -- 15 minutes
local IdleAccumulator = 0
local IsShuttingDown = false

function AutoShutdown.Init()
    print("[AutoShutdown] 15-minute inactivity watchdog started.")

    RegisterHook("/Script/Engine.World:Tick", function(Context, DeltaSeconds)
        if IsShuttingDown then return end

        local Delta = DeltaSeconds:get()
        local World = GetWorldContext()

        -- Query connected players
        local GameplayStatics = StaticFindObject("/Script/Engine.GameplayStatics")
        local PlayerStateClass = StaticFindObject("/Script/Pal.PalPlayerState")
        
        local PlayerCount = 0
        if GameplayStatics:IsValid() and PlayerStateClass:IsValid() then
            local PlayerStates = GameplayStatics:GetAllActorsOfClass(World, PlayerStateClass)
            if PlayerStates:IsValid() then
                PlayerCount = PlayerStates:Num()
            end
        end

        if PlayerCount == 0 then
            IdleAccumulator = IdleAccumulator + Delta

            -- Periodic log every 3 minutes while idling
            if math.floor(IdleAccumulator) % 180 == 0 and math.floor(IdleAccumulator) > 0 then
                print(string.format("[AutoShutdown] Server empty. Idle: %ds / %ds", math.floor(IdleAccumulator), IDLE_TIMEOUT_SECONDS))
            end

            if IdleAccumulator >= IDLE_TIMEOUT_SECONDS then
                IsShuttingDown = true
                AutoShutdown.ExecuteGracefulShutdown()
            end
        else
            -- Reset accumulator when a player is active
            if IdleAccumulator > 0 then
                print("[AutoShutdown] Player detected online. Resetting idle watchdog.")
                IdleAccumulator = 0
            end
        end
    end)
end

function AutoShutdown.ExecuteGracefulShutdown()
    print("[AutoShutdown] 15 minutes of zero player activity reached. Initiating graceful shutdown...")

    -- 1. Update liveboard state to OFFLINE
    local File = io.open("Pal/Saved/liveboard_state.json", "w")
    if File then
        File:write('{"ServerOnline":false,"PlayerCount":0,"MaxPlayers":32,"Players":[],"ActiveBosses":[],"Timestamp":' .. os.time() .. '}')
        File:close()
    end

    -- 2. Trigger World Save
    local SaveSubsystem = StaticFindObject("/Script/Pal.PalSaveSubsystem")
    if SaveSubsystem:IsValid() then
        SaveSubsystem:SaveWorld()
        print("[AutoShutdown] World save completed.")
    end

    -- 3. Graceful Process Termination
    ExecuteWithDelay(3000, function()
        local KismetSystem = StaticFindObject("/Script/Engine.KismetSystemLibrary")
        if KismetSystem:IsValid() then
            KismetSystem:QuitGame(GetWorldContext(), nil, 0, false)
        else
            os.exit(0)
        end
    end)
end

return AutoShutdown
