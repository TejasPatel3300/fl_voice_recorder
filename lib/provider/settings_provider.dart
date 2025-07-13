import 'package:flutter/material.dart';

import '../../constants/constants.dart';

class SettingsProvider with ChangeNotifier {
  VisualizerType _visualizer = VisualizerType.sinewave;

  VisualizerType get visualizer => _visualizer;

  void setVisualizer(VisualizerType type) {
    _visualizer = type;
    notifyListeners();
  }
}
