import 'package:flutter/material.dart';
import 'package:voice_recorder/presentation/recorder/voice_recorder_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.black54, brightness: Brightness.dark),
    home: VoiceRecorderScreen(),
  );
}
