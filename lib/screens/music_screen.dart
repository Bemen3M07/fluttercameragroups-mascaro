import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  Future<void> _initializeAudioPlayer() async {
    // Escuchar cambios en la duración del audio
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Escuchar cambios en la posición del audio
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Escuchar cuando el audio termina
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });

    // Configurar el reproductor para asegurar que se oiga
    try {
      // Configurar modo de audio (importante para Android)
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {},
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      print('Audio player configurado correctamente');
    } catch (e) {
      print('Error al configurar audio: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // Si la posición es 0, es la primera vez o después de stop
        if (_position == Duration.zero) {
          await _audioPlayer.play(AssetSource('audio/sample.mp3'));
        } else {
          // Si ya estaba pausado, reanudar
          await _audioPlayer.resume();
        }
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('Error al reproducir audio: $e');
    }
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    });
  }

  Future<void> _seekForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition < _duration) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(_duration);
    }
  }

  Future<void> _seekBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> _changeSpeed() async {
    double newSpeed;
    if (_playbackSpeed == 1.0) {
      newSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      newSpeed = 2.0;
    } else {
      newSpeed = 1.0;
    }

    await _audioPlayer.setPlaybackRate(newSpeed);
    setState(() {
      _playbackSpeed = newSpeed;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Player'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Music Player',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Icono de play/pause grande
            Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_arrow,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              _isPlaying ? 'Playing' : 'Paused',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),

            // Barra de progreso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await _audioPlayer.seek(newPosition);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Controles principales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Retroceder 10 segundos
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.replay_10),
                  onPressed: _seekBackward,
                ),
                const SizedBox(width: 20),

                // Stop
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.stop),
                  onPressed: _stop,
                ),
                const SizedBox(width: 20),

                // Play/Pause
                IconButton(
                  iconSize: 50,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _togglePlayPause,
                ),
                const SizedBox(width: 20),

                // Adelantar 10 segundos
                IconButton(
                  iconSize: 40,
                  icon: const Icon(Icons.forward_10),
                  onPressed: _seekForward,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Velocidad de reproducción
            ElevatedButton.icon(
              onPressed: _changeSpeed,
              icon: const Icon(Icons.speed),
              label: Text('Velocidad: ${_playbackSpeed}x'),
            ),
          ],
        ),
      ),
    );
  }
}
