import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CosmicFrequencyApp());
}

class CosmicFrequencyApp extends StatelessWidget {
  const CosmicFrequencyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmic Frequency Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        useMaterial3: true,
      ),
      home: const CosmicFrequencyPlayerScreen(),
    );
  }
}

class CosmicFrequencyPlayerScreen extends StatefulWidget {
  const CosmicFrequencyPlayerScreen({Key? key}) : super(key: key);

  @override
  _CosmicFrequencyPlayerScreenState createState() => _CosmicFrequencyPlayerScreenState();
}

class _CosmicFrequencyPlayerScreenState extends State<CosmicFrequencyPlayerScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = true;
  bool _isPlaying = false;
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  int _currentTrackIndex = 0;
  
  // Animation controller for pulsating effect
  late AnimationController _animationController;
  
  // List of music tracks with their frequencies
  final List<MusicTrack> _musicTracks = [
    MusicTrack(
      title: 'Cosmic Harmony',
      description: 'Healing vibrations at 432 Hz',
      baseFrequency: 432,
      duration: 30.0,
      color: Colors.purpleAccent,
    ),
    MusicTrack(
      title: 'Celestial Awakening',
      description: 'Spiritual vibrations at 963 Hz',
      baseFrequency: 963,
      duration: 30.0,
      color: Colors.blueAccent,
    ),
    MusicTrack(
      title: 'Galactic Meditation',
      description: 'Combination of 528 Hz and 639 Hz',
      baseFrequency: 528,
      secondaryFrequency: 639,
      duration: 45.0,
      color: Colors.tealAccent,
    ),
    MusicTrack(
      title: 'Astral Journey',
      description: 'Deep relaxation at 396 Hz',
      baseFrequency: 396,
      duration: 40.0,
      color: Colors.amberAccent,
    ),
    MusicTrack(
      title: 'Quantum Resonance',
      description: 'Balancing vibrations at 741 Hz',
      baseFrequency: 741,
      duration: 35.0,
      color: Colors.greenAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Initialize audio player listeners
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
        if (_totalDuration.inSeconds > 0) {
          _currentProgress = position.inSeconds / _totalDuration.inSeconds;
        }
      });
    });
    
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      _nextTrack();
    });
    
    // Generate all the music tracks
    _generateAllTracks();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateAllTracks() async {
    setState(() {
      _isLoading = true;
    });

    final directory = await getApplicationDocumentsDirectory();
    
    // Generate all music tracks
    for (int i = 0; i < _musicTracks.length; i++) {
      final track = _musicTracks[i];
      final fileName = 'music_${track.baseFrequency}hz${track.secondaryFrequency != null ? '_${track.secondaryFrequency}hz' : ''}.wav';
      
      String filePath = await _generateMusic(
        track.baseFrequency, 
        track.secondaryFrequency,
        directory.path, 
        fileName,
        track.duration,
      );
      
      setState(() {
        _musicTracks[i] = track.copyWith(filePath: filePath);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _generateMusic(int baseFrequency, int? secondaryFrequency, String directoryPath, String fileName, double duration) async {
    final filePath = '$directoryPath/$fileName';
    final file = File(filePath);
    
    // Use existing file if it exists
    if (await file.exists()) {
      return filePath;
    }
    
    // Create a new musical composition
    final sampleRate = 44100;
    final numSamples = (sampleRate * duration).toInt();
    final amplitude = 20000; // Lower amplitude for softer sound
    
    // Define musical parameters
    final Random random = Random();
    
    // Create harmonics based on the base frequency
    List<double> harmonics = _generateHarmonics(baseFrequency.toDouble());
    
    // Add secondary frequency harmonics if specified
    if (secondaryFrequency != null) {
      harmonics.addAll(_generateHarmonics(secondaryFrequency.toDouble()));
    }
    
    // Create WAV header
    final header = _createWavHeader(numSamples, sampleRate);
    
    // Generate musical composition samples
    final dataList = <int>[];
    
    // Create "notes" with random durations and frequencies from the scale
    int currentSample = 0;
    while (currentSample < numSamples) {
      // Choose a note length (in seconds)
      final noteLength = 0.2 + random.nextDouble() * 0.8; // Between 0.2 and 1.0 seconds
      final noteSamples = (noteLength * sampleRate).toInt();
      
      // Choose which harmonics to play (1-3 notes at once for chords)
      final numHarmonics = 1 + random.nextInt(3); // 1 to 3 harmonics at once
      final selectedHarmonics = <double>[];
      
      for (int h = 0; h < numHarmonics; h++) {
        selectedHarmonics.add(harmonics[random.nextInt(harmonics.length)]);
      }
      
      // Add the base frequency occasionally
      if (random.nextDouble() < 0.6) {
        selectedHarmonics.add(baseFrequency.toDouble());
      }
      
      // Add the secondary frequency occasionally if specified
      if (secondaryFrequency != null && random.nextDouble() < 0.5) {
        selectedHarmonics.add(secondaryFrequency.toDouble());
      }
      
      // Generate the samples for this note/chord
      for (int i = 0; i < noteSamples && currentSample + i < numSamples; i++) {
        final t = (currentSample + i) / sampleRate;
        
        // Sum all the selected harmonics
        double sample = 0;
        for (final harmonic in selectedHarmonics) {
          // Add some gentle vibrato
          final vibrato = 1.0 + 0.005 * sin(2 * pi * 5 * t);
          sample += (amplitude / selectedHarmonics.length) * 
                   sin(2 * pi * harmonic * vibrato * t);
                   
          // Add harmonics
          if (random.nextDouble() < 0.4) {
            sample += (amplitude / selectedHarmonics.length / 3) * 
                     sin(4 * pi * harmonic * t); // Second harmonic
          }
          
          // Add soft third harmonic occasionally
          if (random.nextDouble() < 0.2) {
            sample += (amplitude / selectedHarmonics.length / 5) * 
                     sin(6 * pi * harmonic * t); // Third harmonic
          }
        }
        
        // Apply envelope for smoother note transitions
        double envelope = 1.0;
        final attackTime = 0.03;
        final releaseTime = 0.15;
        final attackSamples = (attackTime * sampleRate).toInt();
        final releaseSamples = (releaseTime * sampleRate).toInt();
        
        if (i < attackSamples) {
          envelope = i / attackSamples;
        } else if (i > noteSamples - releaseSamples) {
          envelope = (noteSamples - i) / releaseSamples;
        }
        
        sample *= envelope;
        
        // Add a bit of noise for texture
        if (random.nextDouble() < 0.15) {
          sample += (random.nextDouble() * 2 - 1) * amplitude * 0.008;
        }
        
        // Convert to 16-bit
        final intSample = sample.toInt();
        
        // 16-bit sample as two 8-bit bytes (little-endian)
        dataList.add(intSample & 0xFF);
        dataList.add((intSample >> 8) & 0xFF);
      }
      
      // Sometimes add a short rest
      if (random.nextDouble() < 0.25) {
        final restLength = 0.1 + random.nextDouble() * 0.3; // 0.1 to 0.4 seconds
        final restSamples = (restLength * sampleRate).toInt();
        
        for (int i = 0; i < restSamples && currentSample + noteSamples + i < numSamples; i++) {
          dataList.add(0);
          dataList.add(0);
        }
        
        currentSample += noteSamples + restSamples;
      } else {
        currentSample += noteSamples;
      }
    }
    
    // Combine everything into a list
    final audioData = [...header, ...dataList];
    
    // Save as file
    await file.writeAsBytes(audioData);
    
    return filePath;
  }
  
  List<double> _generateHarmonics(double baseFrequency) {
    List<double> harmonics = [];
    
    // Create a scale based on the base frequency
    if (baseFrequency == 432) {
      // A-based scale with 432 Hz as A
      harmonics = [
        baseFrequency * 0.75, // F
        baseFrequency * 0.84375, // G
        baseFrequency * 0.9375, // A♭
        baseFrequency, // A (432 Hz)
        baseFrequency * 1.125, // B
        baseFrequency * 1.25, // C
        baseFrequency * 1.40625, // D
      ];
    } else if (baseFrequency == 963) {
      // Scale based on 963 Hz
      harmonics = [
        baseFrequency * 0.5, // Lower octave
        baseFrequency * 0.667, // Perfect fifth below
        baseFrequency * 0.75, // Perfect fourth below
        baseFrequency, // Base (963 Hz)
        baseFrequency * 1.125, // Major third above
        baseFrequency * 1.25, // Perfect fourth above
        baseFrequency * 1.5, // Perfect fifth above
      ];
    } else if (baseFrequency == 528) {
      // Solfeggio frequency 528 Hz (Transformation)
      harmonics = [
        baseFrequency * 0.667, // Perfect fifth below
        baseFrequency * 0.75, // Perfect fourth below
        baseFrequency * 0.889, // Major second below
        baseFrequency, // Base (528 Hz)
        baseFrequency * 1.125, // Major third above
        baseFrequency * 1.333, // Perfect fifth above
        baseFrequency * 1.5, // Major sixth above
      ];
    } else if (baseFrequency == 639) {
      // Solfeggio frequency 639 Hz (Relationships)
      harmonics = [
        baseFrequency * 0.5, // Octave below
        baseFrequency * 0.667, // Perfect fifth below
        baseFrequency * 0.75, // Perfect fourth below
        baseFrequency, // Base (639 Hz)
        baseFrequency * 1.125, // Major third above
        baseFrequency * 1.25, // Perfect fourth above
        baseFrequency * 1.5, // Perfect fifth above
      ];
    } else if (baseFrequency == 396) {
      // Solfeggio frequency 396 Hz (Liberation)
      harmonics = [
        baseFrequency * 0.75, // Perfect fourth below
        baseFrequency * 0.889, // Major second below
        baseFrequency, // Base (396 Hz)
        baseFrequency * 1.125, // Major third above
        baseFrequency * 1.333, // Perfect fifth above
        baseFrequency * 1.5, // Major sixth above
        baseFrequency * 2.0, // Octave above
      ];
    } else if (baseFrequency == 741) {
      // Solfeggio frequency 741 Hz (Awakening)
      harmonics = [
        baseFrequency * 0.5, // Octave below
        baseFrequency * 0.667, // Perfect fifth below
        baseFrequency * 0.889, // Major second below
        baseFrequency, // Base (741 Hz)
        baseFrequency * 1.125, // Major third above
        baseFrequency * 1.333, // Perfect fifth above
        baseFrequency * 1.5, // Major sixth above
      ];
    } else {
      // Generic scale for any other frequency
      harmonics = [
        baseFrequency * 0.5, // Octave below
        baseFrequency * 0.667, // Perfect fifth below
        baseFrequency * 0.75, // Perfect fourth below
        baseFrequency, // Base frequency
        baseFrequency * 1.125, // Major third above
        baseFrequency * 1.25, // Perfect fourth above
        baseFrequency * 1.5, // Perfect fifth above
      ];
    }
    
    return harmonics;
  }
  
  List<int> _createWavHeader(int numSamples, int sampleRate) {
    return [
      // RIFF Header
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      // Chunk size (file size - 8)
      (numSamples * 2 + 36) & 0xFF,
      ((numSamples * 2 + 36) >> 8) & 0xFF,
      ((numSamples * 2 + 36) >> 16) & 0xFF,
      ((numSamples * 2 + 36) >> 24) & 0xFF,
      
      // WAV Format
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      
      // Format Subchunk
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      16, 0, 0, 0, // Subchunk1 Size (16 for PCM)
      1, 0, // AudioFormat (1 for PCM)
      1, 0, // NumChannels (1 for Mono)
      
      // Sample Rate
      sampleRate & 0xFF,
      (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF,
      (sampleRate >> 24) & 0xFF,
      
      // Byte Rate (SampleRate * NumChannels * BitsPerSample/8)
      (sampleRate * 2) & 0xFF,
      ((sampleRate * 2) >> 8) & 0xFF,
      ((sampleRate * 2) >> 16) & 0xFF,
      ((sampleRate * 2) >> 24) & 0xFF,
      
      2, 0, // BlockAlign (NumChannels * BitsPerSample/8)
      16, 0, // BitsPerSample
      
      // Data Subchunk
      0x64, 0x61, 0x74, 0x61, // "data"
      
      // Subchunk2 Size (numSamples * NumChannels * BitsPerSample/8)
      (numSamples * 2) & 0xFF,
      ((numSamples * 2) >> 8) & 0xFF,
      ((numSamples * 2) >> 16) & 0xFF,
      ((numSamples * 2) >> 24) & 0xFF,
    ];
  }

  // Play/pause the current track
  Future<void> _togglePlayPause() async {
    if (_musicTracks[_currentTrackIndex].filePath == null) {
      return;
    }
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      final filePath = _musicTracks[_currentTrackIndex].filePath!;
      
      if (_currentPosition.inSeconds > 0) {
        // Resume playback from current position
        await _audioPlayer.resume();
      } else {
        // Start playing from beginning
        await _audioPlayer.play(DeviceFileSource(filePath), mode: PlayerMode.mediaPlayer);
      }
    }
    
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Play the next track
  Future<void> _nextTrack() async {
    int nextIndex = (_currentTrackIndex + 1) % _musicTracks.length;
    await _changeTrack(nextIndex);
  }

  // Play the previous track
  Future<void> _previousTrack() async {
    int prevIndex = (_currentTrackIndex - 1 + _musicTracks.length) % _musicTracks.length;
    await _changeTrack(prevIndex);
  }

  // Change to a specific track
  Future<void> _changeTrack(int index) async {
    if (index < 0 || index >= _musicTracks.length) {
      return;
    }
    
    // Stop current playback
    await _audioPlayer.stop();
    
    setState(() {
      _currentTrackIndex = index;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _currentProgress = 0.0;
    });
    
    // Start new track if we were playing
    if (_isPlaying) {
      final filePath = _musicTracks[_currentTrackIndex].filePath;

if (filePath != null) {
  await _audioPlayer.play(DeviceFileSource(filePath), mode: PlayerMode.mediaPlayer);
}

    }
  }

  // Seek to a specific position
  Future<void> _seekTo(double value) async {
    final newPosition = Duration(seconds: (value * _totalDuration.inSeconds).round());
    await _audioPlayer.seek(newPosition);
    setState(() {
      _currentPosition = newPosition;
      _currentProgress = value;
    });
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingScreen()
          : Stack(
              children: [
                // Cosmic background
                _buildCosmicBackground(),
                
                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Title and app bar
                        _buildAppBar(),
                        
                        const SizedBox(height: 20),
                        
                        // Currently playing track visualization
                        Expanded(
                          flex: 5,
                          child: _buildTrackVisualization(),
                        ),
                        
                        // Track info
                        _buildTrackInfo(),
                        
                        // Playback controls and progress
                        _buildPlaybackControls(),
                        
                        const SizedBox(height: 16),
                        
                        // Track list
                        Expanded(
                          flex: 4,
                          child: _buildTrackList(),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage('assets/images/cosmos_dark.jpg'), // You'd need to add this asset
          fit: BoxFit.cover,
          opacity: 0.7,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Generating Cosmic Frequencies',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
            ),
            const SizedBox(height: 24),
            Text(
              'Creating healing vibrations for your journey...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCosmicBackground() {
    return Container(
      decoration: BoxDecoration(
        // In a real app, you'd use an actual cosmic image asset
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color(0xFF1A1040),
            Color(0xFF2B1458),
          ],
        ),
      ),
      child: CustomPaint(
        painter: StarfieldPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'COSMIC FREQUENCY',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Sacred Healing Vibrations',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.white70),
          onPressed: () {
            _showInfoDialog();
          },
        ),
      ],
    );
  }

  Widget _buildTrackVisualization() {
    final currentTrack = _musicTracks[_currentTrackIndex];
    
    return Center(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      currentTrack.color.withOpacity(0.7),
                      currentTrack.color.withOpacity(0.0),
                    ],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
              
              // Middle circle
              Container(
                width: 220 + (_isPlaying ? _animationController.value * 20 : 0),
                height: 220 + (_isPlaying ? _animationController.value * 20 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      currentTrack.color.withOpacity(0.2 + (_isPlaying ? _animationController.value * 0.3 : 0)),
                      currentTrack.color.withOpacity(0.0),
                    ],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
              
              // Inner circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      currentTrack.color,
                      currentTrack.color.withOpacity(0.7),
                    ],
                    stops: [0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentTrack.color.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${currentTrack.baseFrequency}${currentTrack.secondaryFrequency != null ? ' & ${currentTrack.secondaryFrequency}' : ''} Hz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // For visualizing waveform, add several circles that pulse with the music
              if (_isPlaying)
                ...List.generate(
                  5,
                  (index) {
                    final double delay = index * 0.2;
                    final double size = 160 + (index + 1) * 20;
                    final double animValue = (_animationController.value + delay) % 1.0;
                    
                    return Opacity(
                      opacity: 1.0 - animValue,
                      child: Container(
                        width: size + animValue * 40,
                        height: size + animValue * 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentTrack.color.withOpacity(0.5 - animValue * 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrackInfo() {
    final currentTrack = _musicTracks[_currentTrackIndex];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            currentTrack.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            currentTrack.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Column(
      children: [
        // Progress slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: _musicTracks[_currentTrackIndex].color,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: _musicTracks[_currentTrackIndex].color.withOpacity(0.3),
          ),
          child: Slider(
            value: _currentProgress,
            onChanged: _seekTo,
          ),
        ),
        
        // Time indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 8),
        
        // Playback buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.skip_previous, color: Colors.white, size: 32),
              onPressed: _previousTrack,
            ),
            SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _musicTracks[_currentTrackIndex].color.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: _musicTracks[_currentTrackIndex].color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                onPressed: _togglePlayPause,
              ),
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.skip_next, color: Colors.white, size: 32),
              onPressed: _nextTrack,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRACK LIBRARY',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: _musicTracks.length,
            itemBuilder: (context, index) {
              final track = _musicTracks[index];
              final isCurrentTrack = index == _currentTrackIndex;
              
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isCurrentTrack 
                      ? track.color.withOpacity(0.2) 
                      : Colors.white.withOpacity(0.05),
                ),
                child: ListTile(
                  onTap: () => _changeTrack(index),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: track.color.withOpacity(0.8),
                    ),
                    child: Center(
                      child: Icon(
                        isCurrentTrack && _isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    track.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  trailing: Text(
                    '${track.baseFrequency}${track.secondaryFrequency != null ? ' & ${track.secondaryFrequency}' : ''} Hz',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1040),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'About Sacred Frequencies',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoSection(
                  '432 Hz',
                  'Believed to be mathematically consistent with the patterns of the universe. Said to be the frequency of nature, promoting healing and relaxation.'
                ),
                _infoSection(
                  '963 Hz',
                  'Associated with the crown chakra, awakening and connecting to spiritual realms. Often used in deep meditation practices.'
                ),
                _infoSection(
                  '528 Hz',
                  'Known as the "Love Frequency", it\'s said to restore human DNA and bring transformation and miracles.'
                ),
                _infoSection(
                  '396 Hz',
                  'Helps in liberating fear and guilt, allowing for grounding and connecting to earth energies.'
                ),
                _infoSection(
                  '741 Hz',
                  'Associated with awakening intuition and solving problems, helping the listener to express themselves more clearly.'
                ),
                SizedBox(height: 16),
                Text(
                  'For best experience, use headphones in a quiet space for deep meditation.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _infoSection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// MusicTrack data class
class MusicTrack {
  final String title;
  final String description;
  final int baseFrequency;
  final int? secondaryFrequency;
  final double duration;
  final Color color;
  final String? filePath;

  const MusicTrack({
    required this.title,
    required this.description,
    required this.baseFrequency,
    this.secondaryFrequency,
    required this.duration,
    required this.color,
    this.filePath,
  });

  MusicTrack copyWith({
    String? title,
    String? description,
    int? baseFrequency,
    int? secondaryFrequency,
    double? duration,
    Color? color,
    String? filePath,
  }) {
    return MusicTrack(
      title: title ?? this.title,
      description: description ?? this.description,
      baseFrequency: baseFrequency ?? this.baseFrequency,
      secondaryFrequency: secondaryFrequency ?? this.secondaryFrequency,
      duration: duration ?? this.duration,
      color: color ?? this.color,
      filePath: filePath ?? this.filePath,
    );
  }
}

// Starfield painter for cosmic background
class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistent stars
    final Paint starPaint = Paint()..color = Colors.white;
    
    // Draw about 300 stars of different sizes
    for (int i = 0; i < 300; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5;
      final opacity = 0.3 + random.nextDouble() * 0.7;
      
      starPaint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
    
    // Draw a few brighter stars
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.0 + random.nextDouble() * 2.0;
      
      // Draw glow effect for bright stars
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), radius * 3, glowPaint);
      
      // Draw the star
      starPaint.color = Colors.white;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
    
    // Draw a few colorful nebulae
    _drawNebula(canvas, size, random, Colors.purpleAccent, 0.2);
    _drawNebula(canvas, size, random, Colors.blueAccent, 0.15);
    _drawNebula(canvas, size, random, Colors.tealAccent, 0.1);
  }
  
  void _drawNebula(Canvas canvas, Size size, Random random, Color color, double opacity) {
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final radius = 50 + random.nextDouble() * 100;
    
    final Paint nebulaPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30);
    
    canvas.drawCircle(Offset(x, y), radius, nebulaPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}