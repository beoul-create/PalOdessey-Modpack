# 🌌 PalOdyssey Official Modpack Repository

This repository hosts the official modpack distribution, individual mod files, and the `version.json` update manifest for the **PalOdyssey Custom Launcher**.

---

## 📦 What is Included in this Repository

* **`version.json`**: Master manifest consumed by the PalOdyssey Launcher for SHA-256 integrity verification, auto-updates, and download routing.
* **`PalOdyssey-Modpack-Latest.zip`**: One-click complete archive containing all 14 pre-configured mods, UE4SS 3.0.1 runtime, Shaders, and data tables.
* **`mods/`**: Hosted standalone mod files for remote delta updates (`dwmapi.dll`, `PalSchema.dll`, `APSE.json`, `main.lua` scripts, etc.).
* **`Pal/`**: Unpacked game directory structure ready to commit directly to GitHub.

---

## 🚀 How to Host on GitHub

1. Create a new public or private repository on GitHub (e.g. `https://github.com/<YourUsername>/mods-manifest` or `https://github.com/<YourUsername>/PalOdyssey-Modpack`).
2. Clone or push the contents of this folder to the `main` branch of your repository:
   ```bash
   git init
   git add .
   git commit -m "feat: initial PalOdyssey v1.5.0 base modpack release"
   git branch -M main
   git remote add origin https://github.com/<YourUsername>/mods-manifest.git
   git push -u origin main
   ```
3. Update the **Manifest URL** in your Launcher Settings or `config.json`:
   ```text
   https://raw.githubusercontent.com/<YourUsername>/mods-manifest/main/version.json
   ```

---

## 🎮 Included Core Mods (v1.5.0)

1. **UE4SS 3.0.1 Core Modding Framework** (`dwmapi.dll`)
2. **PalSchema Dynamic Data Engine** (`PalSchema.dll`)
3. **Azomer Passive Skill Expansion (APSE)** (`APSE.json`)
4. **APSE Forces Of Palpagos** (`APSE_FoP.json`)
5. **DarnMenu In-Game UI Suite** (`DarnMenu.lua`)
6. **DarnToasts + Panels** (`DarnToasts.lua`)
7. **Expedition XP & Level Balancer** (`ExpeditionXP.lua`)
8. **Living Arsenal - Weapon Proficiency** (`WeaponProficiency.lua`)
9. **Weapon Stats Customizer (+100% Melee Buff)** (`WeaponStatsCustomizer.lua`)
10. **LevelLock Progression Gating** (`LevelLock.lua`)
11. **Palworld Gameplay & Combat Tuner** (`PalworldTuner.lua`)
12. **Palworld Borealis Visual Overhaul** (`Borealis.lua`)
13. **RamTrimMod Memory Optimizer** (`RamTrimMod.dll`)
14. **PalOlympics FPS & Performance Booster** (`PalOlympicsFPSBooster.lua`)
