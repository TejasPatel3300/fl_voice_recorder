import 'package:flutter/material.dart';
import 'package:voice_recorder/presentation/recorder/voice_recorder_screen.dart';
import 'package:provider/provider.dart';
import 'package:voice_recorder/provider/settings_provider.dart';

void main() =>
    runApp(MultiProvider(providers: [ChangeNotifierProvider(create: (_) => SettingsProvider())], child: const MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
    home: VoiceRecorderScreen(),
  );
}
