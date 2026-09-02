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
        private static string _currentTrack = "";
        private static bool _currentLoop = true;
        private static double _targetVolume = 0.65;
        private static DispatcherTimer? _crossFadeTimer;
        private static DateTime _lastStateReadTime = DateTime.MinValue;
        private static DateTime _lastGameProcessCheck = DateTime.MinValue;
        private static DateTime _lastHeartbeatWrite = DateTime.MinValue;

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
            _headshotPath = Path.Combine(_audioDir, "rust_headshot.wav");
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
                var checkTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(250) };
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
                    }
                }

                if (!File.Exists(_stateFile)) return;

                var writeTime = File.GetLastWriteTimeUtc(_stateFile);
                if (writeTime == _lastStateReadTime) return;

                string json = File.ReadAllText(_stateFile);
                var dto = JsonSerializer.Deserialize<StateDto>(json);
                if (dto == null) return;
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
            catch { }
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
            if (now - _lastHeartbeatWrite < TimeSpan.FromSeconds(5)) return;
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
            newPlayer.MediaEnded += (ms, me) =>
            {
                if (_currentLoop && ReferenceEquals(newPlayer, _activePlayer))
                {
                    newPlayer.Position = TimeSpan.Zero;
                    newPlayer.Play();
                }
            };
            _activePlayer = newPlayer;

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
                        _activePlayer.Volume + Math.Clamp(difference, -0.03, 0.03),
                        0.0,
                        1.0);
                }
            }

            // Fade down fading-out player
            if (_fadingOutPlayer != null)
            {
                _fadingOutPlayer.Volume = Math.Max(0.0, _fadingOutPlayer.Volume - 0.035);
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
