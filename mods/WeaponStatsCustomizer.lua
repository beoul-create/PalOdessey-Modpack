-- ========================================================================================
-- Mod: Weapon Stats Customizer By Wol4ara896
-- ========================================================================================

local Config = {
    -- ====================================================================================
    -- 1. GLOBAL MULTIPLIERS & CHEATS (Affects all weapons unless overridden)
    -- ====================================================================================
    Global = {
        EnableMod = true,                   -- Master mod switch
        DamageMultiplier = 1.0,             -- Global damage multiplier (e.g. 2.0 = double damage)
        MagazineMultiplier = 1.0,           -- Global magazine capacity multiplier (e.g. 2.0 = double mag)
        DurabilityMultiplier = 1.0,         -- Global durability multiplier (e.g. 5.0 = 5x durability)
        WeightMultiplier = 1.0,             -- Global weight multiplier (e.g. 0.0 = zero weight)
        ExplosionRadiusMultiplier = 1.0,    -- Global blast radius multiplier for grenades & launchers
        ExplosionDamageMultiplier = 1.0,    -- Global explosion damage multiplier
        
        InfiniteDurability = false,         -- If true, weapons never lose durability
        InfiniteAmmo = false,               -- If true, weapons never consume ammunition
        NoRecoil = false,                   -- If true, removes weapon recoil & camera kick
        IncreasedBulletLifetime = false,    -- If true, maximum bullet range & no dropoff
        
        DebugLogging = true,                -- Print logs to the UE4SS console
    },

    -- ====================================================================================
    -- 2. COMPLETE WEAPON DATABASE (EXACT VANILLA DEFAULT VALUES)
    -- Attack     : Base weapon damage
    -- Mag        : Ammo capacity per magazine
    -- Durability : Maximum durability before breaking
    -- Weight     : Inventory weight (in kg)
    -- Sneak      : Damage multiplier when attacking from stealth / behind
    -- ====================================================================================
    Weapons = {
        -- ================================================================================
        -- ASSAULT RIFLES, COMBAT SMGs & SUBMACHINE GUNS
        -- ================================================================================
        ["AssaultRifle_Default1"]       = { Attack = 320,   Mag = 20, Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["AssaultRifle_Default2"]       = { Attack = 400,   Mag = 24, Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["AssaultRifle_Default3"]       = { Attack = 448,   Mag = 26, Durability = 4000, Weight = 15.0, Sneak = 1.0 },
        ["AssaultRifle_Default4"]       = { Attack = 512,   Mag = 28, Durability = 5000, Weight = 15.0, Sneak = 1.0 },
        ["AssaultRifle_Default5"]       = { Attack = 560,   Mag = 30, Durability = 6000, Weight = 15.0, Sneak = 1.0 },
        ["SkyAssaultRifle"]             = { Attack = 1615,  Mag = 30, Durability = 5500, Weight = 5.0,  Sneak = 1.0 },
        ["SkyAssaultRifle_2"]           = { Attack = 1695,  Mag = 34, Durability = 8250, Weight = 5.0,  Sneak = 1.0 },
        ["SkyAssaultRifle_3"]           = { Attack = 1776,  Mag = 38, Durability = 11000,Weight = 5.0,  Sneak = 1.0 },
        ["SkyAssaultRifle_4"]           = { Attack = 1857,  Mag = 42, Durability = 16500,Weight = 5.0,  Sneak = 1.0 },
        ["SkyAssaultRifle_5"]           = { Attack = 1938,  Mag = 46, Durability = 22000,Weight = 5.0,  Sneak = 1.0 },
        ["ElectricArcAssaultRifle"]     = { Attack = 1860,  Mag = 38, Durability = 25000,Weight = 5.0,  Sneak = 1.0 },
        ["ElectricArcAssaultRifle_2"]   = { Attack = 1953,  Mag = 40, Durability = 37500,Weight = 5.0,  Sneak = 1.0 },
        ["ElectricArcAssaultRifle_3"]   = { Attack = 2046,  Mag = 42, Durability = 50000,Weight = 5.0,  Sneak = 1.0 },
        ["ElectricArcAssaultRifle_4"]   = { Attack = 2139,  Mag = 44, Durability = 75000,Weight = 5.0,  Sneak = 1.0 },
        ["ElectricArcAssaultRifle_5"]   = { Attack = 2232,  Mag = 46, Durability = 100000,Weight = 5.0, Sneak = 1.0 },
        ["MakeshiftAssaultRifle"]       = { Attack = 170,   Mag = 15, Durability = 1500, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftAssaultRifle_2"]     = { Attack = 204,   Mag = 17, Durability = 2250, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftAssaultRifle_3"]     = { Attack = 229,   Mag = 19, Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftAssaultRifle_4"]     = { Attack = 255,   Mag = 21, Durability = 4500, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftAssaultRifle_5"]     = { Attack = 297,   Mag = 23, Durability = 6000, Weight = 15.0, Sneak = 1.0 },
        ["SkySubmachineGun"]            = { Attack = 907,   Mag = 42, Durability = 8000, Weight = 15.0, Sneak = 1.0 },
        ["SkySubmachineGun_2"]          = { Attack = 1088,  Mag = 44, Durability = 12000,Weight = 15.0, Sneak = 1.0 },
        ["SkySubmachineGun_3"]          = { Attack = 1224,  Mag = 46, Durability = 16000,Weight = 15.0, Sneak = 1.0 },
        ["SkySubmachineGun_4"]          = { Attack = 1360,  Mag = 48, Durability = 24000,Weight = 15.0, Sneak = 1.0 },
        ["SkySubmachineGun_5"]          = { Attack = 1587,  Mag = 50, Durability = 32000,Weight = 15.0, Sneak = 1.0 },
        ["SubmachineGun"]               = { Attack = 130,   Mag = 24, Durability = 2000, Weight = 15.0, Sneak = 1.0 },
        ["SubmachineGun_2"]             = { Attack = 156,   Mag = 26, Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["SubmachineGun_3"]             = { Attack = 175,   Mag = 28, Durability = 4000, Weight = 15.0, Sneak = 1.0 },
        ["SubmachineGun_4"]             = { Attack = 195,   Mag = 30, Durability = 6000, Weight = 15.0, Sneak = 1.0 },
        ["SubmachineGun_5"]             = { Attack = 227,   Mag = 32, Durability = 8000, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftSubmachineGun"]      = { Attack = 100,   Mag = 24, Durability = 1000, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftSubmachineGun_2"]    = { Attack = 120,   Mag = 26, Durability = 1500, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftSubmachineGun_3"]    = { Attack = 135,   Mag = 28, Durability = 2000, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftSubmachineGun_4"]    = { Attack = 150,   Mag = 30, Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["MakeshiftSubmachineGun_5"]    = { Attack = 175,   Mag = 32, Durability = 4000, Weight = 15.0, Sneak = 1.0 },

        -- ================================================================================
        -- LASER, ENERGY, PULSE RIFLES & SNIPERS
        -- ================================================================================
        ["LaserRifle"]                  = { Attack = 1250,  Mag = 30, Durability = 3000, Weight = 18.0, Sneak = 1.0 },
        ["LaserRifle_2"]                = { Attack = 1437,  Mag = 30, Durability = 4500, Weight = 18.0, Sneak = 1.0 },
        ["LaserRifle_3"]                = { Attack = 1562,  Mag = 30, Durability = 6000, Weight = 18.0, Sneak = 1.0 },
        ["LaserRifle_4"]                = { Attack = 1687,  Mag = 30, Durability = 9000, Weight = 18.0, Sneak = 1.0 },
        ["LaserRifle_5"]                = { Attack = 1875,  Mag = 30, Durability = 12000,Weight = 18.0, Sneak = 1.0 },
        ["ChargeLaserRifle"]            = { Attack = 12500, Mag = 6,  Durability = 200,  Weight = 20.0, Sneak = 1.0 },
        ["ChargeLaserRifle_2"]          = { Attack = 13125, Mag = 7,  Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["ChargeLaserRifle_3"]          = { Attack = 13750, Mag = 8,  Durability = 400,  Weight = 20.0, Sneak = 1.0 },
        ["ChargeLaserRifle_4"]          = { Attack = 14375, Mag = 9,  Durability = 600,  Weight = 20.0, Sneak = 1.0 },
        ["ChargeLaserRifle_5"]          = { Attack = 15000, Mag = 10, Durability = 800,  Weight = 20.0, Sneak = 1.0 },
        ["OverHeatRifle"]               = { Attack = 1225,  Mag = 0,  Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["OverHeatRifle_2"]             = { Attack = 1286,  Mag = 0,  Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["OverHeatRifle_3"]             = { Attack = 1347,  Mag = 0,  Durability = 4000, Weight = 15.0, Sneak = 1.0 },
        ["OverHeatRifle_4"]             = { Attack = 1408,  Mag = 0,  Durability = 5000, Weight = 15.0, Sneak = 1.0 },
        ["OverHeatRifle_5"]             = { Attack = 1470,  Mag = 0,  Durability = 6000, Weight = 15.0, Sneak = 1.0 },
        ["SemiAutoRifle"]               = { Attack = 1150,  Mag = 8,  Durability = 1000, Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoRifle_2"]             = { Attack = 1265,  Mag = 9,  Durability = 1500, Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoRifle_3"]             = { Attack = 1380,  Mag = 10, Durability = 2000, Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoRifle_4"]             = { Attack = 1495,  Mag = 11, Durability = 3000, Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoRifle_5"]             = { Attack = 1610,  Mag = 12, Durability = 4000, Weight = 20.0, Sneak = 1.0 },
        ["SingleShotRifle"]             = { Attack = 1100,  Mag = 1,  Durability = 1000, Weight = 20.0, Sneak = 1.0 },
        ["SingleShotRifle_2"]           = { Attack = 1650,  Mag = 1,  Durability = 2000, Weight = 20.0, Sneak = 1.0 },
        ["SingleShotRifle_3"]           = { Attack = 1870,  Mag = 1,  Durability = 2500, Weight = 20.0, Sneak = 1.0 },
        ["SingleShotRifle_4"]           = { Attack = 2090,  Mag = 1,  Durability = 3000, Weight = 20.0, Sneak = 1.0 },
        ["SingleShotRifle_5"]           = { Attack = 2310,  Mag = 1,  Durability = 4000, Weight = 20.0, Sneak = 1.0 },
        ["SniperRifle_Default"]         = { Attack = 1000,  Mag = 4,  Durability = 500,  Weight = 25.0, Sneak = 1.0 },
        ["Musket"]                      = { Attack = 1000,  Mag = 1,  Durability = 200,  Weight = 20.0, Sneak = 1.0 },
        ["Musket_2"]                    = { Attack = 1400,  Mag = 1,  Durability = 400,  Weight = 20.0, Sneak = 1.0 },
        ["Musket_3"]                    = { Attack = 1600,  Mag = 1,  Durability = 500,  Weight = 20.0, Sneak = 1.0 },
        ["Musket_4"]                    = { Attack = 1800,  Mag = 1,  Durability = 600,  Weight = 20.0, Sneak = 1.0 },
        ["Musket_5"]                    = { Attack = 2000,  Mag = 1,  Durability = 800,  Weight = 20.0, Sneak = 1.0 },

        -- ================================================================================
        -- SHOTGUNS
        -- ================================================================================
        ["PumpActionShotgun"]           = { Attack = 220,   Mag = 8,  Durability = 150,  Weight = 20.0, Sneak = 1.0 },
        ["PumpActionShotgun_2"]         = { Attack = 275,   Mag = 9,  Durability = 500,  Weight = 20.0, Sneak = 1.0 },
        ["PumpActionShotgun_3"]         = { Attack = 308,   Mag = 10, Durability = 600,  Weight = 20.0, Sneak = 1.0 },
        ["PumpActionShotgun_4"]         = { Attack = 352,   Mag = 11, Durability = 700,  Weight = 20.0, Sneak = 1.0 },
        ["PumpActionShotgun_5"]         = { Attack = 385,   Mag = 12, Durability = 800,  Weight = 20.0, Sneak = 1.0 },
        ["DoubleBarrelShotgun"]         = { Attack = 190,   Mag = 2,  Durability = 200,  Weight = 24.0, Sneak = 1.0 },
        ["DoubleBarrelShotgun_2"]       = { Attack = 285,   Mag = 2,  Durability = 400,  Weight = 24.0, Sneak = 1.0 },
        ["DoubleBarrelShotgun_3"]       = { Attack = 323,   Mag = 2,  Durability = 500,  Weight = 24.0, Sneak = 1.0 },
        ["DoubleBarrelShotgun_4"]       = { Attack = 361,   Mag = 2,  Durability = 600,  Weight = 24.0, Sneak = 1.0 },
        ["DoubleBarrelShotgun_5"]       = { Attack = 399,   Mag = 2,  Durability = 800,  Weight = 24.0, Sneak = 1.0 },
        ["SemiAutoShotgun"]             = { Attack = 195,   Mag = 10, Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoShotgun_2"]           = { Attack = 214,   Mag = 11, Durability = 450,  Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoShotgun_3"]           = { Attack = 234,   Mag = 12, Durability = 600,  Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoShotgun_4"]           = { Attack = 253,   Mag = 13, Durability = 900,  Weight = 20.0, Sneak = 1.0 },
        ["SemiAutoShotgun_5"]           = { Attack = 282,   Mag = 14, Durability = 1200, Weight = 20.0, Sneak = 1.0 },
        ["SkyShotgun"]                  = { Attack = 1167,  Mag = 12, Durability = 6000, Weight = 20.0, Sneak = 1.0 },
        ["SkyShotgun_2"]                = { Attack = 1225,  Mag = 14, Durability = 9000, Weight = 20.0, Sneak = 1.0 },
        ["SkyShotgun_3"]                = { Attack = 1283,  Mag = 16, Durability = 12000,Weight = 20.0, Sneak = 1.0 },
        ["SkyShotgun_4"]                = { Attack = 1342,  Mag = 18, Durability = 18000,Weight = 20.0, Sneak = 1.0 },
        ["SkyShotgun_5"]                = { Attack = 1400,  Mag = 20, Durability = 24000,Weight = 20.0, Sneak = 1.0 },
        ["EnergyShotgun"]               = { Attack = 402,   Mag = 10, Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["EnergyShotgun_2"]             = { Attack = 422,   Mag = 11, Durability = 450,  Weight = 20.0, Sneak = 1.0 },
        ["EnergyShotgun_3"]             = { Attack = 442,   Mag = 12, Durability = 600,  Weight = 20.0, Sneak = 1.0 },
        ["EnergyShotgun_4"]             = { Attack = 462,   Mag = 13, Durability = 900,  Weight = 20.0, Sneak = 1.0 },
        ["EnergyShotgun_5"]             = { Attack = 482,   Mag = 14, Durability = 1200, Weight = 20.0, Sneak = 1.0 },
        ["WidePenetrateShotgun"]        = { Attack = 508,   Mag = 30, Durability = 950,  Weight = 20.0, Sneak = 1.0 },
        ["WidePenetrateShotgun_2"]      = { Attack = 533,   Mag = 32, Durability = 1425, Weight = 20.0, Sneak = 1.0 },
        ["WidePenetrateShotgun_3"]      = { Attack = 558,   Mag = 34, Durability = 1900, Weight = 20.0, Sneak = 1.0 },
        ["WidePenetrateShotgun_4"]      = { Attack = 584,   Mag = 36, Durability = 2850, Weight = 20.0, Sneak = 1.0 },
        ["WidePenetrateShotgun_5"]      = { Attack = 609,   Mag = 38, Durability = 3800, Weight = 20.0, Sneak = 1.0 },
        ["OctaviaShotgun"]              = { Attack = 230,   Mag = 0,  Durability = 150,  Weight = 20.0, Sneak = 1.0 },
        ["OctaviaShotgun_2"]            = { Attack = 402,   Mag = 0,  Durability = 225,  Weight = 20.0, Sneak = 1.0 },
        ["OctaviaShotgun_3"]            = { Attack = 460,   Mag = 0,  Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["OctaviaShotgun_4"]            = { Attack = 517,   Mag = 0,  Durability = 450,  Weight = 20.0, Sneak = 1.0 },
        ["OctaviaShotgun_5"]            = { Attack = 575,   Mag = 0,  Durability = 600,  Weight = 20.0, Sneak = 1.0 },
        ["MakeshiftShotgun"]            = { Attack = 215,   Mag = 1,  Durability = 200,  Weight = 24.0, Sneak = 1.0 },
        ["MakeshiftShotgun_2"]          = { Attack = 258,   Mag = 1,  Durability = 300,  Weight = 24.0, Sneak = 1.0 },
        ["MakeshiftShotgun_3"]          = { Attack = 290,   Mag = 1,  Durability = 400,  Weight = 24.0, Sneak = 1.0 },
        ["MakeshiftShotgun_4"]          = { Attack = 322,   Mag = 1,  Durability = 600,  Weight = 24.0, Sneak = 1.0 },
        ["MakeshiftShotgun_5"]          = { Attack = 376,   Mag = 1,  Durability = 800,  Weight = 24.0, Sneak = 1.0 },

        -- ================================================================================
        -- HEAVY WEAPONS, MINIGUNS & FLAMETHROWERS
        -- ================================================================================
        ["GatlingGun"]                  = { Attack = 375,   Mag = 100,Durability = 6000, Weight = 50.0, Sneak = 1.0 },
        ["GatlingGun_2"]                = { Attack = 431,   Mag = 100,Durability = 9000, Weight = 50.0, Sneak = 1.0 },
        ["GatlingGun_3"]                = { Attack = 468,   Mag = 100,Durability = 12000,Weight = 50.0, Sneak = 1.0 },
        ["GatlingGun_4"]                = { Attack = 506,   Mag = 100,Durability = 18000,Weight = 50.0, Sneak = 1.0 },
        ["GatlingGun_5"]                = { Attack = 562,   Mag = 100,Durability = 24000,Weight = 50.0, Sneak = 1.0 },
        ["LaserGatlingGun"]             = { Attack = 530,   Mag = 100,Durability = 8000, Weight = 50.0, Sneak = 1.0 },
        ["LaserGatlingGun_2"]           = { Attack = 583,   Mag = 100,Durability = 12000,Weight = 50.0, Sneak = 1.0 },
        ["LaserGatlingGun_3"]           = { Attack = 609,   Mag = 100,Durability = 16000,Weight = 50.0, Sneak = 1.0 },
        ["LaserGatlingGun_4"]           = { Attack = 636,   Mag = 100,Durability = 24000,Weight = 50.0, Sneak = 1.0 },
        ["LaserGatlingGun_5"]           = { Attack = 689,   Mag = 100,Durability = 32000,Weight = 50.0, Sneak = 1.0 },
        ["FlameThrower"]                = { Attack = 636,   Mag = 100,Durability = 6000, Weight = 45.0, Sneak = 1.0 },
        ["FlameThrower_2"]              = { Attack = 731,   Mag = 100,Durability = 9000, Weight = 45.0, Sneak = 1.0 },
        ["FlameThrower_3"]              = { Attack = 795,   Mag = 100,Durability = 12000,Weight = 45.0, Sneak = 1.0 },
        ["FlameThrower_4"]              = { Attack = 858,   Mag = 100,Durability = 18000,Weight = 45.0, Sneak = 1.0 },
        ["FlameThrower_5"]              = { Attack = 954,   Mag = 100,Durability = 24000,Weight = 45.0, Sneak = 1.0 },

        -- ================================================================================
        -- ROCKET, MISSILE, GRENADE & BEAM LAUNCHERS
        -- ================================================================================
        ["Launcher_Default"]            = { Attack = 10000, Mag = 1,  Durability = 300,  Weight = 30.0, Sneak = 1.0 },
        ["Launcher_Default_2"]          = { Attack = 11000, Mag = 1,  Durability = 800,  Weight = 30.0, Sneak = 1.0 },
        ["Launcher_Default_3"]          = { Attack = 12000, Mag = 1,  Durability = 1000, Weight = 30.0, Sneak = 1.0 },
        ["Launcher_Default_4"]          = { Attack = 13000, Mag = 1,  Durability = 1200, Weight = 30.0, Sneak = 1.0 },
        ["Launcher_Default_5"]          = { Attack = 14000, Mag = 1,  Durability = 1400, Weight = 30.0, Sneak = 1.0 },
        ["EnergyRocketLauncher"]        = { Attack = 10000, Mag = 2,  Durability = 300,  Weight = 30.0, Sneak = 1.0 },
        ["EnergyRocketLauncher_2"]      = { Attack = 11000, Mag = 2,  Durability = 450,  Weight = 50.0, Sneak = 1.0 },
        ["EnergyRocketLauncher_3"]      = { Attack = 11500, Mag = 2,  Durability = 600,  Weight = 50.0, Sneak = 1.0 },
        ["EnergyRocketLauncher_4"]      = { Attack = 12000, Mag = 2,  Durability = 900,  Weight = 50.0, Sneak = 1.0 },
        ["EnergyRocketLauncher_5"]      = { Attack = 13000, Mag = 2,  Durability = 1200, Weight = 50.0, Sneak = 1.0 },
        ["Launcher_Meteor"]             = { Attack = 2000,  Mag = 1,  Durability = 300,  Weight = 30.0, Sneak = 1.0 },
        ["Launcher_Meteor_5"]           = { Attack = 10500, Mag = 1,  Durability = 450,  Weight = 30.0, Sneak = 1.0 },
        ["Launcher_Meat"]               = { Attack = 20,    Mag = 1,  Durability = 300,  Weight = 30.0, Sneak = 1.0 },
        ["GuidedMissileLauncher"]       = { Attack = 5900,  Mag = 1,  Durability = 300,  Weight = 30.0, Sneak = 1.0 },
        ["GuidedMissileLauncher_2"]     = { Attack = 6785,  Mag = 1,  Durability = 450,  Weight = 30.0, Sneak = 1.0 },
        ["GuidedMissileLauncher_3"]     = { Attack = 7375,  Mag = 1,  Durability = 600,  Weight = 30.0, Sneak = 1.0 },
        ["GuidedMissileLauncher_4"]     = { Attack = 7965,  Mag = 1,  Durability = 900,  Weight = 30.0, Sneak = 1.0 },
        ["GuidedMissileLauncher_5"]     = { Attack = 8850,  Mag = 1,  Durability = 1200, Weight = 30.0, Sneak = 1.0 },
        ["MultiGuidedMissileLauncher"]  = { Attack = 5900,  Mag = 4,  Durability = 300,  Weight = 30.0, Sneak = 1.0 },
        ["MultiGuidedMissileLauncher_2"]= { Attack = 6785,  Mag = 4,  Durability = 450,  Weight = 30.0, Sneak = 1.0 },
        ["MultiGuidedMissileLauncher_3"]= { Attack = 7375,  Mag = 4,  Durability = 600,  Weight = 30.0, Sneak = 1.0 },
        ["MultiGuidedMissileLauncher_4"]= { Attack = 7965,  Mag = 4,  Durability = 900,  Weight = 30.0, Sneak = 1.0 },
        ["MultiGuidedMissileLauncher_5"]= { Attack = 8850,  Mag = 4,  Durability = 1200, Weight = 30.0, Sneak = 1.0 },
        ["GrenadeLauncher"]             = { Attack = 3000,  Mag = 5,  Durability = 600,  Weight = 30.0, Sneak = 1.0 },
        ["GrenadeLauncher_2"]           = { Attack = 3450,  Mag = 5,  Durability = 900,  Weight = 30.0, Sneak = 1.0 },
        ["GrenadeLauncher_3"]           = { Attack = 3750,  Mag = 5,  Durability = 1200, Weight = 30.0, Sneak = 1.0 },
        ["GrenadeLauncher_4"]           = { Attack = 4050,  Mag = 5,  Durability = 1800, Weight = 30.0, Sneak = 1.0 },
        ["GrenadeLauncher_5"]           = { Attack = 4500,  Mag = 5,  Durability = 2400, Weight = 30.0, Sneak = 1.0 },
        ["SkyGrenadeLauncher"]          = { Attack = 6722,  Mag = 8,  Durability = 800,  Weight = 30.0, Sneak = 1.0 },
        ["SkyGrenadeLauncher_2"]        = { Attack = 7058,  Mag = 10, Durability = 1200, Weight = 30.0, Sneak = 1.0 },
        ["SkyGrenadeLauncher_3"]        = { Attack = 7394,  Mag = 10, Durability = 1600, Weight = 30.0, Sneak = 1.0 },
        ["SkyGrenadeLauncher_4"]        = { Attack = 7730,  Mag = 12, Durability = 2400, Weight = 30.0, Sneak = 1.0 },
        ["SkyGrenadeLauncher_5"]        = { Attack = 8066,  Mag = 12, Durability = 3200, Weight = 30.0, Sneak = 1.0 },
        ["BeamLauncher"]                = { Attack = 14000, Mag = 0,  Durability = 3500, Weight = 30.0, Sneak = 1.0 },
        ["BeamLauncher_2"]              = { Attack = 14700, Mag = 0,  Durability = 5250, Weight = 30.0, Sneak = 1.0 },
        ["BeamLauncher_3"]              = { Attack = 15400, Mag = 0,  Durability = 7000, Weight = 30.0, Sneak = 1.0 },
        ["BeamLauncher_4"]              = { Attack = 16100, Mag = 0,  Durability = 10500,Weight = 30.0, Sneak = 1.0 },
        ["BeamLauncher_5"]              = { Attack = 16800, Mag = 0,  Durability = 14000,Weight = 30.0, Sneak = 1.0 },
        ["DroneLauncher"]               = { Attack = 200,   Mag = 0,  Durability = 6500, Weight = 5.0,  Sneak = 1.0 },
        ["DroneLauncher_2"]             = { Attack = 210,   Mag = 0,  Durability = 9750, Weight = 5.0,  Sneak = 1.0 },
        ["DroneLauncher_3"]             = { Attack = 220,   Mag = 0,  Durability = 13000,Weight = 5.0,  Sneak = 1.0 },
        ["DroneLauncher_4"]             = { Attack = 230,   Mag = 0,  Durability = 19500,Weight = 5.0,  Sneak = 1.0 },
        ["DroneLauncher_5"]             = { Attack = 240,   Mag = 0,  Durability = 26000,Weight = 5.0,  Sneak = 1.0 },
        ["PenguinLauncher"]             = { Attack = 10000, Mag = 1,  Durability = 0,    Weight = 30.0, Sneak = 1.0 },
        ["SphereLauncher"]              = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 30.0, Sneak = 1.0 },
        ["SphereLauncher_Once"]         = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 30.0, Sneak = 1.0 },
        ["HomingSphereLauncher"]        = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 30.0, Sneak = 1.0 },

        -- ================================================================================
        -- PISTOLS, REVOLVERS & SHIELDS
        -- ================================================================================
        ["HandGun_Default"]             = { Attack = 250,   Mag = 8,  Durability = 400,  Weight = 8.0,  Sneak = 1.0 },
        ["HandGun_Default_2"]           = { Attack = 437,   Mag = 10, Durability = 1200, Weight = 8.0,  Sneak = 1.0 },
        ["HandGun_Default_3"]           = { Attack = 500,   Mag = 12, Durability = 1600, Weight = 8.0,  Sneak = 1.0 },
        ["HandGun_Default_4"]           = { Attack = 562,   Mag = 14, Durability = 2000, Weight = 8.0,  Sneak = 1.0 },
        ["HandGun_Default_5"]           = { Attack = 625,   Mag = 16, Durability = 2400, Weight = 8.0,  Sneak = 1.0 },
        ["MakeshiftHandgun"]            = { Attack = 320,   Mag = 6,  Durability = 300,  Weight = 10.0, Sneak = 1.0 },
        ["MakeshiftHandgun_2"]          = { Attack = 560,   Mag = 6,  Durability = 600,  Weight = 10.0, Sneak = 1.0 },
        ["MakeshiftHandgun_3"]          = { Attack = 640,   Mag = 6,  Durability = 900,  Weight = 10.0, Sneak = 1.0 },
        ["MakeshiftHandgun_4"]          = { Attack = 720,   Mag = 6,  Durability = 1200, Weight = 10.0, Sneak = 1.0 },
        ["MakeshiftHandgun_5"]          = { Attack = 800,   Mag = 6,  Durability = 1500, Weight = 10.0, Sneak = 1.0 },
        ["OldRevolver"]                 = { Attack = 600,   Mag = 6,  Durability = 400,  Weight = 8.0,  Sneak = 1.0 },
        ["OldRevolver_2"]               = { Attack = 1050,  Mag = 6,  Durability = 600,  Weight = 8.0,  Sneak = 1.0 },
        ["OldRevolver_3"]               = { Attack = 1200,  Mag = 6,  Durability = 800,  Weight = 8.0,  Sneak = 1.0 },
        ["OldRevolver_4"]               = { Attack = 1350,  Mag = 6,  Durability = 1200, Weight = 8.0,  Sneak = 1.0 },
        ["OldRevolver_5"]               = { Attack = 1500,  Mag = 6,  Durability = 1600, Weight = 8.0,  Sneak = 1.0 },
        ["OctaviaRevolver"]             = { Attack = 250,   Mag = 0,  Durability = 400,  Weight = 8.0,  Sneak = 1.0 },
        ["OctaviaRevolver_2"]           = { Attack = 437,   Mag = 0,  Durability = 1200, Weight = 8.0,  Sneak = 1.0 },
        ["OctaviaRevolver_3"]           = { Attack = 500,   Mag = 0,  Durability = 1600, Weight = 8.0,  Sneak = 1.0 },
        ["OctaviaRevolver_4"]           = { Attack = 562,   Mag = 0,  Durability = 2000, Weight = 8.0,  Sneak = 1.0 },
        ["OctaviaRevolver_5"]           = { Attack = 625,   Mag = 0,  Durability = 2400, Weight = 8.0,  Sneak = 1.0 },
        ["HandgunShield"]               = { Attack = 250,   Mag = 20, Durability = 400,  Weight = 8.0,  Sneak = 1.0 },
        ["PalDopingShot"]               = { Attack = 250,   Mag = 8,  Durability = 400,  Weight = 8.0,  Sneak = 1.0 },
        ["PalDopingShot_2"]             = { Attack = 250,   Mag = 8,  Durability = 400,  Weight = 8.0,  Sneak = 1.0 },
        ["PalDopingShot_3"]             = { Attack = 250,   Mag = 8,  Durability = 400,  Weight = 8.0,  Sneak = 1.0 },
        ["DecalGun_1"]                  = { Attack = 0,     Mag = 99, Durability = 0,    Weight = 8.0,  Sneak = 1.0 },
        ["DecalGun_2"]                  = { Attack = 0,     Mag = 99, Durability = 0,    Weight = 8.0,  Sneak = 1.0 },
        ["DecalGun_3"]                  = { Attack = 0,     Mag = 99, Durability = 0,    Weight = 8.0,  Sneak = 1.0 },
        ["DecalGun_4"]                  = { Attack = 0,     Mag = 99, Durability = 0,    Weight = 8.0,  Sneak = 1.0 },
        ["DecalGun_5"]                  = { Attack = 0,     Mag = 99, Durability = 0,    Weight = 8.0,  Sneak = 1.0 },

        -- ================================================================================
        -- BOWS & CROSSBOWS
        -- ================================================================================
        ["WeakerBow"]                   = { Attack = 65,    Mag = 1,  Durability = 150,  Weight = 6.0,  Sneak = 1.0 },
        ["WeakerBow_2"]                 = { Attack = 130,   Mag = 1,  Durability = 400,  Weight = 6.0,  Sneak = 1.0 },
        ["WeakerBow_3"]                 = { Attack = 169,   Mag = 1,  Durability = 500,  Weight = 6.0,  Sneak = 1.0 },
        ["WeakerBow_4"]                 = { Attack = 208,   Mag = 1,  Durability = 600,  Weight = 6.0,  Sneak = 1.0 },
        ["WeakerBow_5"]                 = { Attack = 247,   Mag = 1,  Durability = 700,  Weight = 6.0,  Sneak = 1.0 },
        ["CompoundBow"]                 = { Attack = 1100,  Mag = 1,  Durability = 400,  Weight = 17.0, Sneak = 1.0 },
        ["CompoundBow_2"]               = { Attack = 1265,  Mag = 1,  Durability = 600,  Weight = 17.0, Sneak = 1.0 },
        ["CompoundBow_3"]               = { Attack = 1375,  Mag = 1,  Durability = 800,  Weight = 17.0, Sneak = 1.0 },
        ["CompoundBow_4"]               = { Attack = 1485,  Mag = 1,  Durability = 1200, Weight = 17.0, Sneak = 1.0 },
        ["CompoundBow_5"]               = { Attack = 1650,  Mag = 1,  Durability = 1600, Weight = 17.0, Sneak = 1.0 },
        ["SFBow"]                       = { Attack = 5800,  Mag = 1,  Durability = 500,  Weight = 25.0, Sneak = 1.0 },
        ["SFBow_2"]                     = { Attack = 6670,  Mag = 1,  Durability = 750,  Weight = 25.0, Sneak = 1.0 },
        ["SFBow_3"]                     = { Attack = 7250,  Mag = 1,  Durability = 1000, Weight = 25.0, Sneak = 1.0 },
        ["SFBow_4"]                     = { Attack = 7830,  Mag = 1,  Durability = 1500, Weight = 25.0, Sneak = 1.0 },
        ["SFBow_5"]                     = { Attack = 8700,  Mag = 1,  Durability = 2000, Weight = 25.0, Sneak = 1.0 },
        ["SkyBow"]                      = { Attack = 20000, Mag = 1,  Durability = 2000, Weight = 6.0,  Sneak = 1.0 },
        ["SkyBow_2"]                    = { Attack = 21000, Mag = 1,  Durability = 3000, Weight = 6.0,  Sneak = 1.0 },
        ["SkyBow_3"]                    = { Attack = 22000, Mag = 1,  Durability = 4000, Weight = 6.0,  Sneak = 1.0 },
        ["SkyBow_4"]                    = { Attack = 23000, Mag = 1,  Durability = 6000, Weight = 6.0,  Sneak = 1.0 },
        ["SkyBow_5"]                    = { Attack = 24000, Mag = 1,  Durability = 8000, Weight = 6.0,  Sneak = 1.0 },
        ["Bow_Poison"]                  = { Attack = 65,    Mag = 1,  Durability = 150,  Weight = 6.0,  Sneak = 1.0 },
        ["Bow_Fire"]                    = { Attack = 65,    Mag = 1,  Durability = 150,  Weight = 6.0,  Sneak = 1.0 },
        ["Bow_triple"]                  = { Attack = 40,    Mag = 1,  Durability = 250,  Weight = 8.0,  Sneak = 1.0 },
        ["Bow_Fifth"]                   = { Attack = 30,    Mag = 1,  Durability = 350,  Weight = 8.0,  Sneak = 1.0 },
        ["RecurveBow"]                  = { Attack = 40,    Mag = 1,  Durability = 200,  Weight = 15.0, Sneak = 1.0 },
        ["BowGun"]                      = { Attack = 280,   Mag = 1,  Durability = 300,  Weight = 13.0, Sneak = 1.0 },
        ["BowGun_2"]                    = { Attack = 364,   Mag = 1,  Durability = 800,  Weight = 13.0, Sneak = 1.0 },
        ["BowGun_3"]                    = { Attack = 406,   Mag = 1,  Durability = 1000, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_4"]                    = { Attack = 448,   Mag = 1,  Durability = 1200, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_5"]                    = { Attack = 490,   Mag = 1,  Durability = 1400, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Poison"]               = { Attack = 280,   Mag = 1,  Durability = 300,  Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Poison_2"]             = { Attack = 364,   Mag = 1,  Durability = 800,  Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Poison_3"]             = { Attack = 406,   Mag = 1,  Durability = 1000, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Poison_4"]             = { Attack = 448,   Mag = 1,  Durability = 1200, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Poison_5"]             = { Attack = 490,   Mag = 1,  Durability = 1400, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Fire"]                 = { Attack = 280,   Mag = 1,  Durability = 300,  Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Fire_2"]               = { Attack = 364,   Mag = 1,  Durability = 800,  Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Fire_3"]               = { Attack = 406,   Mag = 1,  Durability = 1000, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Fire_4"]               = { Attack = 448,   Mag = 1,  Durability = 1200, Weight = 13.0, Sneak = 1.0 },
        ["BowGun_Fire_5"]               = { Attack = 490,   Mag = 1,  Durability = 1400, Weight = 13.0, Sneak = 1.0 },

        -- ================================================================================
        -- MELEE WEAPONS, KATANAS, BEAM SWORDS, SPEARS & YAKUSHIMA BLADES (BUFFED +100%)
        -- ================================================================================
        ["Katana"]                      = { Attack = 1560,  Mag = 0,  Durability = 500,  Weight = 10.0, Sneak = 1.0 },
        ["Katana_2"]                    = { Attack = 1716,  Mag = 0,  Durability = 750,  Weight = 10.0, Sneak = 1.0 },
        ["Katana_3"]                    = { Attack = 1872,  Mag = 0,  Durability = 1000, Weight = 10.0, Sneak = 1.0 },
        ["Katana_4"]                    = { Attack = 2028,  Mag = 0,  Durability = 1500, Weight = 10.0, Sneak = 1.0 },
        ["Katana_5"]                    = { Attack = 2340,  Mag = 0,  Durability = 2000, Weight = 10.0, Sneak = 1.0 },
        ["Sword"]                       = { Attack = 720,   Mag = 0,  Durability = 500,  Weight = 10.0, Sneak = 1.0 },
        ["Sword_2"]                     = { Attack = 792,   Mag = 0,  Durability = 750,  Weight = 10.0, Sneak = 1.0 },
        ["Sword_3"]                     = { Attack = 864,   Mag = 0,  Durability = 1000, Weight = 10.0, Sneak = 1.0 },
        ["Sword_4"]                     = { Attack = 936,   Mag = 0,  Durability = 1500, Weight = 10.0, Sneak = 1.0 },
        ["Sword_5"]                     = { Attack = 1080,  Mag = 0,  Durability = 2000, Weight = 10.0, Sneak = 1.0 },
        ["BronzeSword"]                 = { Attack = 360,   Mag = 0,  Durability = 500,  Weight = 10.0, Sneak = 1.0 },
        ["BeamSword"]                   = { Attack = 1860,  Mag = 0,  Durability = 500,  Weight = 10.0, Sneak = 1.0 },
        ["BeamSword_2"]                 = { Attack = 2046,  Mag = 0,  Durability = 750,  Weight = 10.0, Sneak = 1.0 },
        ["BeamSword_3"]                 = { Attack = 2232,  Mag = 0,  Durability = 1000, Weight = 10.0, Sneak = 1.0 },
        ["BeamSword_4"]                 = { Attack = 2418,  Mag = 0,  Durability = 1500, Weight = 10.0, Sneak = 1.0 },
        ["BeamSword_5"]                 = { Attack = 2790,  Mag = 0,  Durability = 2000, Weight = 10.0, Sneak = 1.0 },
        ["SkyBeamSword"]                = { Attack = 4000,  Mag = 0,  Durability = 1200, Weight = 10.0, Sneak = 1.0 },
        ["SkyBeamSword_2"]              = { Attack = 4200,  Mag = 0,  Durability = 1800, Weight = 10.0, Sneak = 1.0 },
        ["SkyBeamSword_3"]              = { Attack = 4400,  Mag = 0,  Durability = 2400, Weight = 10.0, Sneak = 1.0 },
        ["SkyBeamSword_4"]              = { Attack = 4600,  Mag = 0,  Durability = 3600, Weight = 10.0, Sneak = 1.0 },
        ["SkyBeamSword_5"]              = { Attack = 4800,  Mag = 0,  Durability = 4800, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade"]              = { Attack = 400,   Mag = 0,  Durability = 2222, Weight = 22.0, Sneak = 1.0 },
        ["YakushimaBlade002"]           = { Attack = 850,   Mag = 0,  Durability = 757,  Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade002_2"]         = { Attack = 934,   Mag = 0,  Durability = 1135, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade002_3"]         = { Attack = 1020,  Mag = 0,  Durability = 1514, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade002_4"]         = { Attack = 1104,  Mag = 0,  Durability = 2271, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade002_5"]         = { Attack = 1274,  Mag = 0,  Durability = 3028, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade003"]           = { Attack = 180,   Mag = 0,  Durability = 5000, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaBlade003_2"]         = { Attack = 200,   Mag = 0,  Durability = 6000, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaBlade003_3"]         = { Attack = 220,   Mag = 0,  Durability = 7200, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaBlade003_4"]         = { Attack = 250,   Mag = 0,  Durability = 8640, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaBlade003_5"]         = { Attack = 300,   Mag = 0,  Durability = 10368,Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaBlade004"]           = { Attack = 720,   Mag = 0,  Durability = 600,  Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade004_2"]         = { Attack = 792,   Mag = 0,  Durability = 900,  Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade004_3"]         = { Attack = 864,   Mag = 0,  Durability = 1200, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade004_4"]         = { Attack = 936,   Mag = 0,  Durability = 1800, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade004_5"]         = { Attack = 1080,  Mag = 0,  Durability = 2400, Weight = 10.0, Sneak = 1.0 },
        ["YakushimaBlade005"]           = { Attack = 444,   Mag = 0,  Durability = 22222,Weight = 22.0, Sneak = 1.0 },
        ["YakushimaGun001"]             = { Attack = 600,   Mag = 0,  Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["YakushimaGun001_2"]           = { Attack = 660,   Mag = 0,  Durability = 3000, Weight = 15.0, Sneak = 1.0 },
        ["YakushimaGun001_3"]           = { Attack = 720,   Mag = 0,  Durability = 4000, Weight = 15.0, Sneak = 1.0 },
        ["YakushimaGun001_4"]           = { Attack = 780,   Mag = 0,  Durability = 5000, Weight = 15.0, Sneak = 1.0 },
        ["YakushimaGun001_5"]           = { Attack = 900,   Mag = 0,  Durability = 6000, Weight = 15.0, Sneak = 1.0 },
        ["YakushimaLantern001"]         = { Attack = 100,   Mag = 0,  Durability = 3000, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaLantern001_2"]       = { Attack = 120,   Mag = 0,  Durability = 3000, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaLantern001_3"]       = { Attack = 140,   Mag = 0,  Durability = 4000, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaLantern001_4"]       = { Attack = 160,   Mag = 0,  Durability = 5000, Weight = 5.0,  Sneak = 1.0 },
        ["YakushimaLantern001_5"]       = { Attack = 200,   Mag = 0,  Durability = 6000, Weight = 5.0,  Sneak = 1.0 },
        ["Spear"]                       = { Attack = 70,    Mag = 0,  Durability = 200,  Weight = 10.0, Sneak = 1.0 },
        ["Spear_2"]                     = { Attack = 160,   Mag = 0,  Durability = 250,  Weight = 15.0, Sneak = 1.0 },
        ["Spear_3"]                     = { Attack = 620,   Mag = 0,  Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["Spear_Lily"]                  = { Attack = 1720,  Mag = 0,  Durability = 500,  Weight = 10.0, Sneak = 1.0 },
        ["Spear_ForestBoss"]            = { Attack = 1720,  Mag = 0,  Durability = 500,  Weight = 10.0, Sneak = 1.0 },
        ["Spear_ForestBoss_5"]          = { Attack = 2150,  Mag = 0,  Durability = 2000, Weight = 10.0, Sneak = 1.0 },
        ["Spear_ForestBoss2"]           = { Attack = 2400,  Mag = 0,  Durability = 600,  Weight = 10.0, Sneak = 1.0 },
        ["Spear_ForestBoss2_5"]         = { Attack = 3000,  Mag = 0,  Durability = 2400, Weight = 10.0, Sneak = 1.0 },
        ["Spear_QueenBee"]              = { Attack = 300,   Mag = 0,  Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["Spear_SoldierBee"]            = { Attack = 300,   Mag = 0,  Durability = 400,  Weight = 15.0, Sneak = 1.0 },
        ["ElecBaton"]                   = { Attack = 20,    Mag = 0,  Durability = 300,  Weight = 10.0, Sneak = 1.0 },
        ["Bat"]                         = { Attack = 50,    Mag = 0,  Durability = 150,  Weight = 5.0,  Sneak = 1.0 },
        ["Bat2"]                        = { Attack = 100,   Mag = 0,  Durability = 150,  Weight = 3.0,  Sneak = 1.0 },
        ["Bat3"]                        = { Attack = 1000,  Mag = 0,  Durability = 500,  Weight = 3.0,  Sneak = 1.0 },
        ["Bat3_2"]                      = { Attack = 1100,  Mag = 0,  Durability = 750,  Weight = 3.0,  Sneak = 1.0 },
        ["Bat3_3"]                      = { Attack = 1200,  Mag = 0,  Durability = 1000, Weight = 3.0,  Sneak = 1.0 },
        ["Bat3_4"]                      = { Attack = 1300,  Mag = 0,  Durability = 1500, Weight = 3.0,  Sneak = 1.0 },
        ["Bat3_5"]                      = { Attack = 1500,  Mag = 0,  Durability = 2000, Weight = 3.0,  Sneak = 1.0 },
        ["MeatCutterKnife"]             = { Attack = 50,    Mag = 0,  Durability = 300,  Weight = 10.0, Sneak = 1.0 },
        ["Torch"]                       = { Attack = 20,    Mag = 0,  Durability = 100,  Weight = 5.0,  Sneak = 1.0 },

        -- ================================================================================
        -- ALL 10+ GRENADE TYPES & THROWABLES
        -- ================================================================================
        ["FragGrenade"]                 = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Fire"]            = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Elec"]            = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Ice"]             = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Dark"]            = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Dragon"]          = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Ground"]          = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Leaf"]            = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Water"]           = { Attack = 750,   Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["FragGrenade_Super"]           = { Attack = 4000,  Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["PalHealingGrenade"]           = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },
        ["ThrowStone"]                  = { Attack = 50,    Mag = 0,  Durability = 0,    Weight = 0.1,  Sneak = 1.0 },

        -- ================================================================================
        -- HARVESTING TOOLS, MINING & GRAPPLING GUNS (BUFFED +100%)
        -- ================================================================================
        ["Axe_Tier_00"]                 = { Attack = 40,    Mag = 0,  Durability = 150,  Weight = 10.0, Sneak = 1.0 },
        ["Axe_Tier_01"]                 = { Attack = 60,    Mag = 0,  Durability = 250,  Weight = 15.0, Sneak = 1.0 },
        ["Axe_Tier_02"]                 = { Attack = 120,   Mag = 0,  Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["Axe_Tier_03"]                 = { Attack = 150,   Mag = 0,  Durability = 400,  Weight = 25.0, Sneak = 1.0 },
        ["Axe_Steal"]                   = { Attack = 240,   Mag = 0,  Durability = 400,  Weight = 25.0, Sneak = 1.0 },
        ["Pickaxe_Tier_00"]             = { Attack = 40,    Mag = 0,  Durability = 150,  Weight = 10.0, Sneak = 1.0 },
        ["Pickaxe_Tier_01"]             = { Attack = 60,    Mag = 0,  Durability = 250,  Weight = 15.0, Sneak = 1.0 },
        ["Pickaxe_Tier_02"]             = { Attack = 120,   Mag = 0,  Durability = 300,  Weight = 20.0, Sneak = 1.0 },
        ["Pickaxe_Tier_03"]             = { Attack = 150,   Mag = 0,  Durability = 400,  Weight = 25.0, Sneak = 1.0 },
        ["Pickaxe_Steal"]               = { Attack = 240,   Mag = 0,  Durability = 400,  Weight = 25.0, Sneak = 1.0 },
        ["LaserMiningTool"]             = { Attack = 500,   Mag = 0,  Durability = 850,  Weight = 50.0, Sneak = 1.0 },
        ["GrapplingGun"]                = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 1.0,  Sneak = 1.0 },
        ["GrapplingGun2"]               = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 1.0,  Sneak = 1.0 },
        ["GrapplingGun3"]               = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 1.0,  Sneak = 1.0 },
        ["GrapplingGun4"]               = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 1.0,  Sneak = 1.0 },
        ["GrapplingGun5"]               = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 1.0,  Sneak = 1.0 },
        ["AirGrapplingGun"]             = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 1.0,  Sneak = 1.0 },
        ["CaptureRope"]                 = { Attack = 1000,  Mag = 4,  Durability = 200,  Weight = 5.0,  Sneak = 1.0 },
        ["MetalDetector"]               = { Attack = 0,     Mag = 0,  Durability = 400,  Weight = 25.0, Sneak = 1.0 },

        -- ================================================================================
        -- FISHING RODS
        -- ================================================================================
        ["FishingRod_01_1"]             = { Attack = 25,    Mag = 0,  Durability = 120,  Weight = 5.0,  Sneak = 1.0 },
        ["FishingRod_01_2"]             = { Attack = 25,    Mag = 0,  Durability = 180,  Weight = 5.0,  Sneak = 1.0 },
        ["FishingRod_02_1"]             = { Attack = 25,    Mag = 0,  Durability = 240,  Weight = 5.0,  Sneak = 1.0 },
        ["FishingRod_02_2"]             = { Attack = 25,    Mag = 0,  Durability = 360,  Weight = 5.0,  Sneak = 1.0 },
        ["FishingRod_03_1"]             = { Attack = 25,    Mag = 0,  Durability = 480,  Weight = 5.0,  Sneak = 1.0 },
        ["FishingRod_03_2"]             = { Attack = 25,    Mag = 0,  Durability = 720,  Weight = 5.0,  Sneak = 1.0 },
        ["FishingRod_Test"]             = { Attack = 25,    Mag = 0,  Durability = 150,  Weight = 5.0,  Sneak = 1.0 },
        ["FishingRod_Good"]             = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 15.0, Sneak = 1.0 },
        ["FishingRod_Old"]              = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 15.0, Sneak = 1.0 },
        ["FishingRod_Super"]            = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 15.0, Sneak = 1.0 },
        ["FishingRod_Legendary"]        = { Attack = 0,     Mag = 0,  Durability = 0,    Weight = 15.0, Sneak = 1.0 },
    }
}

-- ========================================================================================
-- HELPER FUNCTIONS
-- ========================================================================================

local function Log(message)
    if Config.Global.DebugLogging then
        print(string.format("[WeaponStatsCustomizer] %s", tostring(message)))
    end
end

local function FindWeaponConfig(weaponId)
    if not weaponId then return nil end
    if Config.Weapons[weaponId] then
        return Config.Weapons[weaponId]
    end
    for key, cfg in pairs(Config.Weapons) do
        if string.find(weaponId, "^" .. key) then
            return cfg
        end
    end
    return nil
end

local function ApplyStaticWeaponStats(weaponStaticData)
    if not weaponStaticData or not weaponStaticData:IsValid() then return end

    local weaponId = weaponStaticData.ID:ToString()
    local customCfg = FindWeaponConfig(weaponId)

    if customCfg and customCfg.Attack ~= nil then
        weaponStaticData.AttackValue = math.floor(customCfg.Attack * Config.Global.DamageMultiplier)
    elseif Config.Global.DamageMultiplier ~= 1.0 then
        weaponStaticData.AttackValue = math.floor(weaponStaticData.AttackValue * Config.Global.DamageMultiplier)
    end

    if customCfg and customCfg.Mag ~= nil then
        weaponStaticData.MagazineSize = math.floor(customCfg.Mag * Config.Global.MagazineMultiplier)
    elseif Config.Global.MagazineMultiplier ~= 1.0 then
        weaponStaticData.MagazineSize = math.floor(weaponStaticData.MagazineSize * Config.Global.MagazineMultiplier)
    end

    if Config.Global.InfiniteDurability then
        weaponStaticData.Durability = 999999.0
    elseif customCfg and customCfg.Durability ~= nil then
        weaponStaticData.Durability = customCfg.Durability * Config.Global.DurabilityMultiplier
    elseif Config.Global.DurabilityMultiplier ~= 1.0 then
        weaponStaticData.Durability = weaponStaticData.Durability * Config.Global.DurabilityMultiplier
    end

    if customCfg and customCfg.Weight ~= nil then
        weaponStaticData.Weight = customCfg.Weight * Config.Global.WeightMultiplier
    elseif Config.Global.WeightMultiplier ~= 1.0 then
        weaponStaticData.Weight = weaponStaticData.Weight * Config.Global.WeightMultiplier
    end

    if customCfg and customCfg.Sneak ~= nil then
        weaponStaticData.SneakAttackRate = customCfg.Sneak
    end
end

local function UpdateAllStaticWeapons()
    if not Config.Global.EnableMod then return end

    Log("Applying configured stats to all in-game weapon entries...")

    local staticWeapons = FindAllOf("PalStaticWeaponItemData")
    local count = 0

    if staticWeapons then
        for _, weaponData in ipairs(staticWeapons) do
            if weaponData:IsValid() then
                ApplyStaticWeaponStats(weaponData)
                count = count + 1
            end
        end
    end

    Log(string.format("Successfully applied stats to %d weapons & grenades!", count))
end

RegisterHook("/Script/Pal.PalWeaponBase:OnAttachWeapon", function(Context, AttachActor)
    if not Config.Global.EnableMod then return end

    local Weapon = Context:get()
    if not Weapon or not Weapon:IsValid() then return end

    local weaponIdStr = ""
    if Weapon.ownWeaponStaticData and Weapon.ownWeaponStaticData:IsValid() then
        weaponIdStr = Weapon.ownWeaponStaticData.ID:ToString()
        ApplyStaticWeaponStats(Weapon.ownWeaponStaticData)
    end

    local customCfg = FindWeaponConfig(weaponIdStr)

    if Config.Global.InfiniteAmmo then
        Weapon.IsInfinityMagazine = true
        Weapon.IsRequiredBullet = false
        Weapon.IsRequiredBulletForAltFire = false
    end

    if Config.Global.NoRecoil then
        Weapon.RecoilPowerRate = 0.0
        Weapon.RecoilYawRange = 0.0
        Weapon.RecoilPitchTotalMax = 0.0
    elseif customCfg and customCfg.RecoilRate ~= nil then
        Weapon.RecoilPowerRate = customCfg.RecoilRate
        Weapon.RecoilYawRange = Weapon.RecoilYawRange * customCfg.RecoilRate
        Weapon.RecoilPitchTotalMax = Weapon.RecoilPitchTotalMax * customCfg.RecoilRate
    end

    if Config.Global.IncreasedBulletLifetime then
        Weapon.BulletDeleteTime = 30.0
        Weapon.BulletDecayStartRate = 1.0
    end

    if customCfg and customCfg.CoolDownTime ~= nil then
        Weapon.CoolDownTime = customCfg.CoolDownTime
    end

    if Weapon.ownWeaponDynamicData and Weapon.ownWeaponDynamicData:IsValid() then
        local dynamicData = Weapon.ownWeaponDynamicData
        if Config.Global.InfiniteDurability then
            dynamicData.Durability = 999999.0
            dynamicData.MaxDurability = 999999.0
        end
        if Weapon.ownWeaponStaticData and Weapon.ownWeaponStaticData:IsValid() then
            dynamicData.MaxMagazineSize = Weapon.ownWeaponStaticData.MagazineSize
        end
    end
end)

RegisterHook("/Script/Engine.Actor:ReceiveBeginPlay", function(Context)
    if not Config.Global.EnableMod then return end

    local Actor = Context:get()
    if not Actor or not Actor:IsValid() then return end

    if Actor:IsA("/Script/Pal.PalExplosionAttackBase") or string.find(Actor:GetFullName(), "ExplosionAttack") then
        local ownerIdStr = ""
        if Actor.OwnerStaticItemId then
            ownerIdStr = Actor.OwnerStaticItemId:ToString()
        end

        local customCfg = FindWeaponConfig(ownerIdStr)

        if customCfg and customCfg.Attack ~= nil then
            Actor.AttackPower = math.floor(customCfg.Attack * Config.Global.ExplosionDamageMultiplier)
        elseif Config.Global.ExplosionDamageMultiplier ~= 1.0 then
            Actor.AttackPower = math.floor(Actor.AttackPower * Config.Global.ExplosionDamageMultiplier)
        end

        if customCfg and customCfg.ExplosionRadius ~= nil then
            if Actor.SetRadius then
                Actor:SetRadius(math.floor(customCfg.ExplosionRadius * Config.Global.ExplosionRadiusMultiplier))
            end
        elseif Config.Global.ExplosionRadiusMultiplier ~= 1.0 and Actor.SetRadius then
            Actor:SetRadius(math.floor(500 * Config.Global.ExplosionRadiusMultiplier))
        end

        if customCfg and customCfg.BlowPower ~= nil then
            Actor.BlowPower = customCfg.BlowPower
        end
    end
end)

RegisterHook("/Script/Pal.PalWeaponBase:DecreaseDurabilityWithValue", function(Context, DurabilityParam)
    if Config.Global.EnableMod and Config.Global.InfiniteDurability then
        return true
    end
end)


RegisterHook("/Script/Pal.PalPlayerCharacter:OnCompleteInitializeParameter", function(Context, InCharacter)
    ExecuteWithDelay(1500, function()
        UpdateAllStaticWeapons()
    end)
end)

ExecuteWithDelay(4000, function()
    UpdateAllStaticWeapons()
end)

Log("WeaponStatsCustomizer loaded")