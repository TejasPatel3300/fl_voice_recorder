import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:voice_recorder/presentation/recorder/sinewave_visualizer.dart';
import 'package:voice_recorder/presentation/recorder/waveform.dart';

class AudioPlayer extends StatefulWidget {
  /// Path from where to play recorded audio
  final String source;

  /// Callback when audio file should be removed
  /// Setting this to null hides the delete button
  final VoidCallback onDelete;

  const AudioPlayer({super.key, required this.source, required this.onDelete});

  @override
  AudioPlayerState createState() => AudioPlayerState();
}

class AudioPlayerState extends State<AudioPlayer> {
  static const double _controlSize = 56;
  static const double _deleteBtnSize = 24;

  final _audioPlayer = ap.AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  late StreamSubscription<void> _playerStateChangedSubscription;
  late StreamSubscription<Duration?> _durationChangedSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
  Duration? _position;
  Duration? _duration;
  double _progress = 0;
  List<double> _visibleAmplitude = []; // sine visualizer
  Waveform? _currentFileWaveForm;

  @override
  void initState() {
    _playerStateChangedSubscription = _audioPlayer.onPlayerComplete.listen((state) async {
      await stop();
    });
    _positionChangedSubscription = _audioPlayer.onPositionChanged.listen(
      (position) => setState(() {
        final currentFileWaveForm = _currentFileWaveForm;
        if (currentFileWaveForm != null) {
          final waveFormDuration = currentFileWaveForm?.duration.inMilliseconds ?? 0;
          if (waveFormDuration > 0) {
            setState(() {
              _progress = position.inMilliseconds / waveFormDuration;
            });
          }
          _visibleAmplitude = getAmplitudeWindow(position);
        }
        _position = position;
      }),
    );
    _durationChangedSubscription = _audioPlayer.onDurationChanged.listen(
      (duration) => setState(() {
        _duration = duration;
      }),
    );

    _audioPlayer.setSource(_source);
    _prepareAudioWaveProcessStream(File(widget.source));

    super.initState();
  }

  List<double> getAmplitudeWindow(Duration pos, {int windowSize = 100}) {
    final waveform = _currentFileWaveForm!;
    final centerPixel = waveform.positionToPixel(pos).round();

    int start = (centerPixel - windowSize ~/ 2).clamp(0, waveform.length - 1);
    int end = (start + windowSize).clamp(0, waveform.length);

    List<double> amplitudes = [];

    for (int i = start; i < end; i++) {
      int min = waveform.getPixelMin(i);
      int max = waveform.getPixelMax(i);
      int diff = (max - min).abs();

      // Normalize based on bit depth
      double norm = waveform.flags == 1 ? diff / 255.0 : diff / 65535.0;

      // Boost amplitude range for visibility
      double boosted = pow(norm, 0.5).toDouble().clamp(0.0, 1.0);

      amplitudes.add(boosted);}
    return amplitudes;
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentFileWaveForm != null) ...[
              // Expanded(child: WaveformWidget(waveform: _currentFileWaveForm!, progress: _progress)), // waveform visualizer
              Expanded(
                child: SmoothWaveformVisualizer(
                  waveform: _currentFileWaveForm!,
                  amplitudes: _visibleAmplitude,
                  progress: _progress,
                ),
              ),
              // sine visualizer
            ],
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildControl(),
                _buildSlider(constraints.maxWidth),
                IconButton(
                  icon: const Icon(Icons.delete, size: _deleteBtnSize),
                  onPressed: () {
                    if (_audioPlayer.state == ap.PlayerState.playing) {
                      stop().then((value) => widget.onDelete());
                    } else {
                      widget.onDelete();
                    }
                  },
                ),
              ],
            ),
            Text('${_duration ?? 0.0}'),
          ],
        );
      },
    );
  }

  Widget _buildControl() {
    Icon icon;
    Color color;

    if (_audioPlayer.state == ap.PlayerState.playing) {
      icon = const Icon(Icons.pause, size: 30);
      color = Colors.red.withValues(alpha: 0.1);
    } else {
      final theme = Theme.of(context);
      icon = Icon(Icons.play_arrow, size: 30);
      color = theme.primaryColor.withValues(alpha: 0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: _controlSize, height: _controlSize, child: icon),
          onTap: () {
            if (_audioPlayer.state == ap.PlayerState.playing) {
              pause();
            } else {
              play();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSlider(double widgetWidth) {
    bool canSetValue = false;
    final duration = _duration;
    final position = _position;

    if (duration != null && position != null) {
      canSetValue = position.inMilliseconds > 0;
      canSetValue &= position.inMilliseconds < duration.inMilliseconds;
    }

    double width = widgetWidth - _controlSize - _deleteBtnSize;
    width -= _deleteBtnSize;

    return SizedBox(
      width: width,
      child: Slider(
        inactiveColor: Theme.of(context).colorScheme.secondary,
        onChanged: (v) {
          if (duration != null) {
            final position = v * duration.inMilliseconds;
            _audioPlayer.seek(Duration(milliseconds: position.round()));
          }
        },
        value:
            canSetValue && duration != null && position != null
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0,
      ),
    );
  }

  Future<void> play() => _audioPlayer.play(_source);

  Future<void> pause() async {
    await _audioPlayer.pause();
    setState(() {});
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    setState(() {});
  }

  Source get _source => kIsWeb ? ap.UrlSource(widget.source) : ap.DeviceFileSource(widget.source);

  Future<void> _prepareAudioWaveProcessStream(File audioFile) async {
    try {
      final waveFile = File(p.join((await getTemporaryDirectory()).path, 'waveform.wave'));
      JustWaveform.extract(audioInFile: audioFile, waveOutFile: waveFile).listen((event) {
        // _progressStream.add(event);
        final progress = (100 * event.progress).toInt();
        if (progress == 100) {
          _currentFileWaveForm = event.waveform;
        }
      });
    } catch (e, st) {
      debugPrint('Error while preparing audio wave form: $e\nStackTrace: $st');
    }
  }
}
