import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_recorder/constants/constants.dart';
import 'package:voice_recorder/provider/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final selected = settings.visualizer;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Visualizer Type", style: TextStyle(fontSize: 18)),
          ),
          RadioListTile<VisualizerType>(
            title: const Text('Waveform'),
            value: VisualizerType.waveform,
            groupValue: selected,
            onChanged: (visualizerType) {
              _onChangeVisualizer(visualizerType, settings);
            },
          ),
          RadioListTile<VisualizerType>(
            title: const Text('Sine Wave (Bezier)'),
            value: VisualizerType.sinewave,
            groupValue: selected,
            onChanged: (visualizerType) {
              _onChangeVisualizer(visualizerType, settings);
            },
          ),
        ],
      ),
    );
  }

  void _onChangeVisualizer(VisualizerType? visualizerType, SettingsProvider settings) {
     if (visualizerType != null) {
      settings.setVisualizer(visualizerType);
    }
  }
}
