# PalBossJukebox

Companion audio process for `WorldBossAuraSystem`. It watches the mod's
`music_state.json`, crossfades regional and boss tracks, and listens for the
headshot sound-effect pipe.

Publish the Windows x64 self-contained executable with:

```powershell
dotnet publish PalBossJukebox.csproj -c Release
```

The project intentionally produces a compressed single-file application so
players do not need to install the .NET 8 Desktop Runtime separately.
