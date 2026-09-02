using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Media;
using System.Windows.Threading;

namespace PalBossJukebox
{
    internal class Program
    {
        private static MediaPlayer? _activePlayer;
        private static MediaPlayer? _fadingOutPlayer;
        private static string _audioDir = "";
        private static string _stateFile = "";
        private static string _heartbeatFile = "";
        private static string _metricsFile = "";
        private static string _currentTrack = "";
        private static bool _currentLoop = true;
        private static double _targetVolume = 0.65;
        private static DispatcherTimer? _crossFadeTimer;
        private static DateTime _lastStateReadTime = DateTime.MinValue;
        private static DateTime _lastGameProcessCheck = DateTime.MinValue;
        private static DateTime _lastHeartbeatWrite = DateTime.MinValue;
        private static DateTime _lastMetricsWrite = DateTime.MinValue;
        private static readonly DateTime _startedAt = DateTime.UtcNow;
        private static TimeSpan _lastCpuTime = TimeSpan.Zero;
        private static DateTime _lastCpuSampleAt = DateTime.UtcNow;
        private static double _cpuPercent;
        private static int _statePollMilliseconds = 250;
        private static int _crossfadeDurationMilliseconds = 1200;
        private static int _heartbeatIntervalSeconds = 5;
        private static long _stateReads;
        private static long _stateErrors;
        private static long _trackTransitions;
        private static long _playbackErrors;

        private class StateDto
        {
            public string? state { get; set; }
            public string? track { get; set; }
            public bool? loop { get; set; }
            public double? volume { get; set; }
        }

        [System.Runtime.InteropServices.DllImport("winmm.dll", EntryPoint = "PlaySoundA", ExactSpelling = true, SetLastError = true)]
        private static extern bool PlaySound(string pszSound, IntPtr hmod, uint fdwSound);

        private const uint SND_ASYNC = 0x0001;
        private const uint SND_FILENAME = 0x0002;
        private static string _headshotPath = "";

        [STAThread]
        static void Main(string[] args)
        {
            using var mutex = new Mutex(true, "PalBossJukebox_SingleInstance_Mutex", out bool createdNew);
            if (!createdNew) return;

            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            _audioDir = baseDir;
            _stateFile = Path.Combine(_audioDir, "music_state.json");
            _heartbeatFile = Path.Combine(_audioDir, "jukebox_heartbeat.txt");
            _metricsFile = Path.Combine(_audioDir, "jukebox_metrics.json");
            _headshotPath = Path.Combine(_audioDir, "rust_headshot.wav");
            LoadConfiguration();
            AppDomain.CurrentDomain.ProcessExit += (s, e) => DeleteHeartbeat();

            // Instant low-latency headshot SFX listener
            Task.Run(() =>
            {
                while (true)
                {
                    try
                    {
                        using var server = new System.IO.Pipes.NamedPipeServerStream("PalHeadshotPipe", System.IO.Pipes.PipeDirection.In, 4);
                        server.WaitForConnection();
                        server.ReadByte();
                        if (File.Exists(_headshotPath))
                        {
                            PlaySound(_headshotPath, IntPtr.Zero, SND_ASYNC | SND_FILENAME);
                        }
                    }
                    catch
                    {
                        Thread.Sleep(20);
                    }
                }
            });

            var app = new System.Windows.Application();
            app.Startup += (s, e) =>
            {
                // Periodic check for state changes and game process
                var checkTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(_statePollMilliseconds) };
                checkTimer.Tick += (ts, te) => CheckState();
                checkTimer.Start();

                // Cross-fade step timer
                _crossFadeTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(40) };
                _crossFadeTimer.Tick += (fs, fe) =>
                {
                    try { HandleCrossFade(); } catch { }
                };

                CheckState();
            };

            app.Run();
        }

        private static int _missingGameTicks = 0;

        private static bool IsProcessRunning(string processName)
        {
            Process[] processes = Process.GetProcessesByName(processName);
            try
            {
                return processes.Length > 0;
            }
            finally
            {
                foreach (Process process in processes)
                {
                    process.Dispose();
                }
            }
        }

        private static bool IsGameRunning()
        {
            return IsProcessRunning("Palworld-Win64-Shipping") ||
                   IsProcessRunning("Pal-Win64-Shipping") ||
                   IsProcessRunning("Pal");
        }

        private static void CheckState()
        {
            try
            {
                // Run the process watchdog once per second, not on every state poll.
                DateTime now = DateTime.UtcNow;
                if (now - _lastGameProcessCheck >= TimeSpan.FromSeconds(1))
                {
                    _lastGameProcessCheck = now;
                    if (!IsGameRunning())
                    {
                        _missingGameTicks++;
                        if (_missingGameTicks >= 2)
                        {
                            try { _activePlayer?.Close(); } catch { }
                            try { _fadingOutPlayer?.Close(); } catch { }
                            Environment.Exit(0);
                            return;
                        }
                    }
                    else
                    {
                        _missingGameTicks = 0;
                        WriteHeartbeat(now);
                        WriteMetrics(now);
                    }
                }

                if (!File.Exists(_stateFile)) return;

                var writeTime = File.GetLastWriteTimeUtc(_stateFile);
                if (writeTime == _lastStateReadTime) return;

                string json = File.ReadAllText(_stateFile);
                var dto = JsonSerializer.Deserialize<StateDto>(json);
                if (dto == null) return;
                _stateReads++;
                // Only acknowledge the timestamp after a complete, valid read.
                _lastStateReadTime = writeTime;

                string reqState = (dto.state ?? "").Trim().ToLowerInvariant();
                string reqTrack = (dto.track ?? "").Trim();
                bool reqLoop = dto.loop ?? true;
                double reqVol = dto.volume ?? 0.65;

                if (reqState == "play" && !string.IsNullOrEmpty(reqTrack))
                {
                    TransitionToTrack(reqTrack, reqLoop, reqVol);
                }
                else if (reqState == "fade_out" || reqState == "stop")
                {
                    FadeOutAll();
                }
            }
            catch
            {
                _stateErrors++;
            }
        }

        private static void LoadConfiguration()
        {
            try
            {
                string configPath = Path.GetFullPath(Path.Combine(_audioDir, "..", "config.json"));
                if (!File.Exists(configPath)) return;
                using JsonDocument document = JsonDocument.Parse(File.ReadAllText(configPath));
                JsonElement root = document.RootElement;
                if (root.TryGetProperty("JukeboxStatePollMilliseconds", out JsonElement poll) && poll.TryGetInt32(out int pollValue))
                    _statePollMilliseconds = Math.Clamp(pollValue, 100, 2000);
                if (root.TryGetProperty("JukeboxCrossfadeDurationMilliseconds", out JsonElement fade) && fade.TryGetInt32(out int fadeValue))
                    _crossfadeDurationMilliseconds = Math.Clamp(fadeValue, 200, 10000);
                if (root.TryGetProperty("JukeboxHeartbeatIntervalSeconds", out JsonElement heartbeat) && heartbeat.TryGetInt32(out int heartbeatValue))
                    _heartbeatIntervalSeconds = Math.Clamp(heartbeatValue, 2, 30);
            }
            catch
            {
                // Invalid optional tuning values fall back to safe defaults.
            }
        }

        private static void DeleteHeartbeat()
        {
            try
            {
                if (File.Exists(_heartbeatFile)) File.Delete(_heartbeatFile);
            }
            catch { }
        }

        private static void WriteHeartbeat(DateTime now)
        {
            if (now - _lastHeartbeatWrite < TimeSpan.FromSeconds(_heartbeatIntervalSeconds)) return;
            try
            {
                File.WriteAllText(
                    _heartbeatFile,
                    DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(System.Globalization.CultureInfo.InvariantCulture));
                _lastHeartbeatWrite = now;
            }
            catch
            {
                // Heartbeat failure must never block state-file processing.
            }
        }

        private static void WriteMetrics(DateTime now)
        {
            if (now - _lastMetricsWrite < TimeSpan.FromMinutes(1)) return;
            try
            {
                using Process process = Process.GetCurrentProcess();
                TimeSpan cpuTime = process.TotalProcessorTime;
                double elapsedSeconds = Math.Max(0.001, (now - _lastCpuSampleAt).TotalSeconds);
                _cpuPercent = Math.Max(0.0, (cpuTime - _lastCpuTime).TotalSeconds / elapsedSeconds / Environment.ProcessorCount * 100.0);
                _lastCpuTime = cpuTime;
                _lastCpuSampleAt = now;

                string json = JsonSerializer.Serialize(new
                {
                    timestampUtc = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
                    processId = Environment.ProcessId,
                    uptimeSeconds = Math.Round((now - _startedAt).TotalSeconds, 1),
                    cpuPercent = Math.Round(_cpuPercent, 3),
                    workingSetBytes = process.WorkingSet64,
                    privateMemoryBytes = process.PrivateMemorySize64,
                    handleCount = process.HandleCount,
                    stateReads = _stateReads,
                    stateErrors = _stateErrors,
                    trackTransitions = _trackTransitions,
                    playbackErrors = _playbackErrors,
                    currentTrack = _currentTrack
                });
                File.WriteAllText(_metricsFile, json);
                _lastMetricsWrite = now;
            }
            catch
            {
                // Metrics are diagnostic-only and must never affect playback.
            }
        }

        private static void TransitionToTrack(string trackName, bool loop, double targetVol)
        {
            trackName = Path.GetFileName(trackName);
            targetVol = Math.Clamp(targetVol, 0.0, 1.0);
            string fullPath = Path.Combine(_audioDir, trackName);
            if (!File.Exists(fullPath)) return;

            if (_currentTrack == trackName && _activePlayer != null)
            {
                // Already playing same track, just update volume/loop
                _targetVolume = targetVol;
                _currentLoop = loop;
                EnsureCrossFadeTimerRunning();
                return;
            }

            _currentTrack = trackName;
            _currentLoop = loop;
            _targetVolume = targetVol;

            // Swap players for crossfade
            if (_fadingOutPlayer != null && !ReferenceEquals(_fadingOutPlayer, _activePlayer))
            {
                _fadingOutPlayer.Close();
            }
            _fadingOutPlayer = _activePlayer;

            var newPlayer = new MediaPlayer();
            newPlayer.MediaFailed += (ms, me) => _playbackErrors++;
            newPlayer.MediaEnded += (ms, me) =>
            {
                if (_currentLoop && ReferenceEquals(newPlayer, _activePlayer))
                {
                    newPlayer.Position = TimeSpan.Zero;
                    newPlayer.Play();
                }
            };
            _activePlayer = newPlayer;

            _trackTransitions++;

            _activePlayer.Open(new Uri(fullPath));
            _activePlayer.Volume = 0.0;
            _activePlayer.Play();
            EnsureCrossFadeTimerRunning();
        }

        private static void FadeOutAll()
        {
            _currentTrack = "";
            if (_fadingOutPlayer != null && !ReferenceEquals(_fadingOutPlayer, _activePlayer))
            {
                _fadingOutPlayer.Close();
            }
            _fadingOutPlayer = _activePlayer;
            _activePlayer = null;
            EnsureCrossFadeTimerRunning();
        }

        private static void EnsureCrossFadeTimerRunning()
        {
            if (_crossFadeTimer != null && !_crossFadeTimer.IsEnabled)
            {
                _crossFadeTimer.Start();
            }
        }

        private static void HandleCrossFade()
        {
            double fadeStep = Math.Clamp(40.0 / _crossfadeDurationMilliseconds, 0.004, 0.2);
            // Move active volume toward the target in either direction. This is
            // required for volume-down and mute while the same track is playing.
            if (_activePlayer != null)
            {
                double difference = _targetVolume - _activePlayer.Volume;
                if (Math.Abs(difference) <= 0.005)
                {
                    _activePlayer.Volume = _targetVolume;
                }
                else
                {
                    _activePlayer.Volume = Math.Clamp(
                        _activePlayer.Volume + Math.Clamp(difference, -fadeStep, fadeStep),
                        0.0,
                        1.0);
                }
            }

            // Fade down fading-out player
            if (_fadingOutPlayer != null)
            {
                _fadingOutPlayer.Volume = Math.Max(0.0, _fadingOutPlayer.Volume - fadeStep);
                if (_fadingOutPlayer.Volume <= 0.005)
                {
                    _fadingOutPlayer.Stop();
                    _fadingOutPlayer.Close();
                    _fadingOutPlayer = null;
                }
            }

            bool activeAtTarget = _activePlayer == null || Math.Abs(_activePlayer.Volume - _targetVolume) <= 0.005;
            if (_fadingOutPlayer == null && activeAtTarget)
            {
                _crossFadeTimer?.Stop();
            }
        }
    }
}
