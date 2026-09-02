# PalBossJukebox

Companion audio process for `WorldBossAuraSystem`. It watches the mod's
`music_state.json`, crossfades regional and boss tracks, and listens for the
headshot sound-effect pipe.

Runtime tuning is read from the parent mod's `config.json`. The helper writes
`jukebox_metrics.json` once per minute with CPU, memory, handle, transition,
state-read, and playback-error counters. In game, `/bgmperf status` prints the
latest helper snapshot alongside the Lua diagnostics; use `/bgmperf start`,
`/bgmperf reset`, and `/bgmperf stop` to control Lua sampling.

Publish the Windows x64 self-contained executable with:

```powershell
dotnet publish PalBossJukebox.csproj -c Release
```

The project intentionally produces a compressed single-file application so
players do not need to install the .NET 8 Desktop Runtime separately.
