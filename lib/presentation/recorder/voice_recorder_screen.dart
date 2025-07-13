import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:voice_recorder/presentation/recorder/widget/audio_player.dart';
import 'package:voice_recorder/presentation/recorder/widget/recorder.dart';
import 'package:voice_recorder/presentation/settings/settings.dart';

class VoiceRecorderScreen extends StatefulWidget {
  const VoiceRecorderScreen({super.key});

  @override
  State<VoiceRecorderScreen> createState() => _VoiceRecorderScreenState();
}

class _VoiceRecorderScreenState extends State<VoiceRecorderScreen> {
  bool showPlayer = false;
  String? audioPath;

  @override
  void initState() {
    showPlayer = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(
        child:
            showPlayer
                ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: AudioPlayer(source: audioPath!, onDelete: () => setState(() => showPlayer = false)),
                )
                : Recorder(onStop: _onRecorderStop),
      ),
    );
  }

  void _onRecorderStop(String path) {
    if (kDebugMode) print('Recorded file path: $path');
    setState(() {
      audioPath = path;
      showPlayer = true;
    });
  }
}
