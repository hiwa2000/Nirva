import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const FrequencyPlayerApp());
}

class FrequencyPlayerApp extends StatelessWidget {
  const FrequencyPlayerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frequenzton-Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FrequencyPlayerScreen(),
    );
  }
}

class FrequencyPlayerScreen extends StatefulWidget {
  const FrequencyPlayerScreen({Key? key}) : super(key: key);

  @override
  _FrequencyPlayerScreenState createState() => _FrequencyPlayerScreenState();
}

class _FrequencyPlayerScreenState extends State<FrequencyPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = true;
  bool _isPlaying432 = false;
  bool _isPlaying963 = false;
  String? _tone432Path;
  String? _tone963Path;

  @override
  void initState() {
    super.initState();
    _generateTones();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _generateTones() async {
    setState(() {
      _isLoading = true;
    });

    // Generieren der beiden Töne
    final directory = await getApplicationDocumentsDirectory();
    
    _tone432Path = await _generateToneFile(432, directory.path, "tone_432hz.wav");
    _tone963Path = await _generateToneFile(963, directory.path, "tone_963hz.wav");

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _generateToneFile(int frequency, String directoryPath, String fileName) async {
    final filePath = '$directoryPath/$fileName';
    final file = File(filePath);
    
    // Wenn die Datei bereits existiert, verwenden wir sie
    if (await file.exists()) {
      return filePath;
    }
    
    // Sonst erstellen wir einen neuen Ton
    final sampleRate = 44100;
    final duration = 5.0; // 5 Sekunden
    final numSamples = (sampleRate * duration).toInt();
    final amplitude = 32760; // Fast maximale Amplitude für 16-bit
    
    // WAV-Header erstellen
    final header = <int>[
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
      16, 0, 0, 0, // Subchunk1 Size (16 für PCM)
      1, 0, // AudioFormat (1 für PCM)
      1, 0, // NumChannels (1 für Mono)
      
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
    
    // Samples für Sinuswelle generieren
    final dataList = <int>[];
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final sample = (amplitude * sin(2 * pi * frequency * t)).toInt();
      
      // 16-bit sample als zwei 8-bit Bytes (little-endian)
      dataList.add(sample & 0xFF);
      dataList.add((sample >> 8) & 0xFF);
    }
    
    // Alles in eine Liste kombinieren
    final audioData = [...header, ...dataList];
    
    // Als Datei speichern
    await file.writeAsBytes(audioData);
    
    return filePath;
  }

  Future<void> _playTone(int frequency) async {
    final path = frequency == 432 ? _tone432Path : _tone963Path;
    
    if (path != null) {
      if ((frequency == 432 && _isPlaying432) || 
          (frequency == 963 && _isPlaying963)) {
        // Ton stoppen, wenn er bereits abgespielt wird
        await _audioPlayer.stop();
        setState(() {
          if (frequency == 432) {
            _isPlaying432 = false;
          } else {
            _isPlaying963 = false;
          }
        });
      } else {
        // Vorher laufenden Ton stoppen
        if (_isPlaying432 || _isPlaying963) {
          await _audioPlayer.stop();
          setState(() {
            _isPlaying432 = false;
            _isPlaying963 = false;
          });
        }
        
        // Neuen Ton abspielen
        await _audioPlayer.play(DeviceFileSource(path), mode: PlayerMode.mediaPlayer);
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() {
            _isPlaying432 = false;
            _isPlaying963 = false;
          });
        });
        
        setState(() {
          if (frequency == 432) {
            _isPlaying432 = true;
          } else {
            _isPlaying963 = true;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequenzton-Player'),
      ),
      body: Center(
        child: _isLoading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Wählen Sie die Frequenz:',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToneButton(432),
                    _buildToneButton(963),
                  ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildToneButton(int frequency) {
    final isPlaying = frequency == 432 ? _isPlaying432 : _isPlaying963;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        backgroundColor: isPlaying ? Colors.green : null,
      ),
      onPressed: () => _playTone(frequency),
      child: Column(
        children: [
          Text(
            '$frequency Hz',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            isPlaying ? 'Stoppen' : 'Abspielen',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}