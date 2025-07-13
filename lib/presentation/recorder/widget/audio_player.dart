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
import 'package:provider/provider.dart';
import 'package:voice_recorder/constants/constants.dart';
import 'package:voice_recorder/presentation/recorder/widget/sinewave_visualizer.dart';
import 'package:voice_recorder/presentation/recorder/widget/waveform.dart';
import 'package:voice_recorder/provider/settings_provider.dart';
import 'package:voice_recorder/utils/date_time_utils.dart';

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

  double _progress = 0;
  List<double> _visibleAmplitude = []; // sine visualizer

  Duration? _position;
  Duration? _duration;
  Waveform? _currentFileWaveForm;

  @override
  void initState() {
    _initializePlayerListeners();
    _audioPlayer.setSource(_source);
    _prepareAudioWaveProcessStream(File(widget.source));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final visualizer = context.watch<SettingsProvider>().visualizer;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: _currentFileWaveForm != null ? _buildVisualizer(visualizer): const SizedBox()),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildControl(),
                _buildSlider(constraints.maxWidth),
                IconButton(
                  icon: Icon(Icons.delete, size: _deleteBtnSize, color: Theme.of(context).colorScheme.primary),
                  onPressed: () {
                    if (_audioPlayer.state == ap.PlayerState.playing) {
                      _stop().then((value) => widget.onDelete());
                    } else {
                      widget.onDelete();
                    }
                  },
                ),
              ],
            ),
            Text(getDurationText(_duration?.inSeconds ?? 0)),
            SizedBox(height: 30),
          ],
        );
      },
    );
  }

  List<double> _getAmplitudeWindow(Duration pos, {int windowSize = 100}) {
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

      amplitudes.add(boosted);
    }
    return amplitudes;
  }

  Widget _buildControl() {
    Icon icon;
    Color color;

    if (_audioPlayer.state == ap.PlayerState.playing) {
      icon = const Icon(Icons.pause, size: 30);
      color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    } else {
      icon = Icon(Icons.play_arrow, size: 30);
      color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    }

    return ClipOval(
      child: Material(
        color: color,
        child: InkWell(
          child: SizedBox(width: _controlSize, height: _controlSize, child: icon),
          onTap: () {
            if (_audioPlayer.state == ap.PlayerState.playing) {
              _pause();
            } else {
              _play();
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

  Widget _buildVisualizer(VisualizerType visualizer) {
    switch (visualizer) {
      case VisualizerType.waveform:
        return WaveformWidget(waveform: _currentFileWaveForm!, progress: _progress);
      case VisualizerType.sinewave:
        return SmoothWaveformVisualizer(
          waveform: _currentFileWaveForm!,
          amplitudes: _visibleAmplitude,
          progress: _progress,
        );
    }
  }

  Future<void> _play() => _audioPlayer.play(_source);

  Future<void> _pause() async {
    await _audioPlayer.pause();
    setState(() {});
  }

  Future<void> _stop() async {
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
          setState(() {});
        }
      });
    } catch (e, st) {
      debugPrint('Error while preparing audio wave form: $e\nStackTrace: $st');
    }
  }

  void _initializePlayerListeners() {
    _playerStateChangedSubscription = _audioPlayer.onPlayerComplete.listen((_) async => await _stop());

    _positionChangedSubscription = _audioPlayer.onPositionChanged.listen(_handlePositionChanged);

    _durationChangedSubscription = _audioPlayer.onDurationChanged.listen(
      (duration) => setState(() {
        _duration = duration;
      }),
    );
  }

  void _handlePositionChanged(Duration position) {
    final waveform = _currentFileWaveForm;
    double progress = 0.0;
    List<double> visibleAmp = [];

    if (waveform != null) {
      final durationMs = waveform.duration.inMilliseconds;
      if (durationMs > 0) {
        progress = position.inMilliseconds / durationMs;
      }
      visibleAmp = _getAmplitudeWindow(position);
    }

    setState(() {
      _position = position;
      _progress = progress;
      _visibleAmplitude = visibleAmp;
    });
  }

  @override
  void dispose() {
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
