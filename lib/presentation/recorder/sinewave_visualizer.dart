import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:just_waveform/just_waveform.dart';


class SmoothWaveformVisualizer extends StatelessWidget{
  final Waveform waveform;
  final List<double> amplitudes; // normalized between -1 and 1
  final double progress; // Optional: for syncing or scrolling

  const SmoothWaveformVisualizer({
    super.key,

    required this.waveform, required this.amplitudes, required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SmoothWaveformPainter(
        amplitudes: amplitudes,
        color: Theme.of(context).colorScheme.primary,
        progress: progress, // optional
      ),
      size: Size.infinite,
    );
  }
}


class SmoothWaveformPainter extends CustomPainter {
  final List<double> amplitudes; // normalized between -1 and 1
  final double progress; // Optional: for syncing or scrolling
  final Color color;

  SmoothWaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final midY = size.height / 2;
    final spacing = size.width / (amplitudes.length - 1);

    // === Layer settings ===
    final List<Color> layerColors = [
      color.withValues(alpha: 0.8), // primary wave
      color.withValues(alpha: 0.3), // shadow 1
      color.withValues(alpha: 0.15), // shadow 2
    ];

    final List<double> amplitudeMultipliers = [1.0, 0.6, 0.3];
    final List<double> frequencyOffsets = [0.1, 0.08, 0.06];
    final List<double> phaseOffsets = [0, 0.5, 1.0];

    for (int layer = 0; layer < layerColors.length; layer++) {
      final paint = Paint()
        ..color = layerColors[layer]
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final path = Path();

      // First point
      double x0 = 0;
      double y0 = midY -
          amplitudes[0] *
              sin(x0 * frequencyOffsets[layer] + progress + phaseOffsets[layer]) *
              midY *
              0.8 *
              amplitudeMultipliers[layer];

      path.moveTo(x0, y0);

      for (int i = 1; i < amplitudes.length - 1; i++) {
        double x1 = (i - 1) * spacing;
        double y1 = midY -
            amplitudes[i - 1] *
                sin(x1 * frequencyOffsets[layer] + progress + phaseOffsets[layer]) *
                midY *
                0.8 *
                amplitudeMultipliers[layer];

        double x2 = i * spacing;
        double y2 = midY -
            amplitudes[i] *
                sin(x2 * frequencyOffsets[layer] + progress + phaseOffsets[layer]) *
                midY *
                0.8 *
                amplitudeMultipliers[layer];

        double cx = (x1 + x2) / 2;
        double cy = (y1 + y2) / 2;

        path.quadraticBezierTo(x1, y1, cx, cy);
      }

      canvas.drawPath(path, paint);
    }

    // === Optional dynamic highlight at peak loudness ===
    double peakAmp = amplitudes.reduce((a, b) => a > b ? a : b);
    final glowPaint = Paint()
      ..color = color.withOpacity((peakAmp * 0.7).clamp(0.1, 0.6))
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);

    final glowPath = Path();

    // Recreate main path for glow
    double x0 = 0;
    double y0 = midY - amplitudes[0] * sin(x0 * 0.1 + progress) * midY * 0.8;
    glowPath.moveTo(x0, y0);

    for (int i = 1; i < amplitudes.length - 1; i++) {
      double x1 = (i - 1) * spacing;
      double y1 = midY -
          amplitudes[i - 1] *
              sin(x1 * 0.1 + progress) *
              midY *
              0.8;

      double x2 = i * spacing;
      double y2 = midY -
          amplitudes[i] *
              sin(x2 * 0.1 + progress) *
              midY *
              0.8;

      double cx = (x1 + x2) / 2;
      double cy = (y1 + y2) / 2;

      glowPath.quadraticBezierTo(x1, y1, cx, cy);
    }

    canvas.drawPath(glowPath, glowPaint);
  }

  // @override
  // void paint(Canvas canvas, Size size) {
  //   if (amplitudes.isEmpty) return;
  //
  //   final midY = size.height / 2;
  //   final spacing = size.width / (amplitudes.length - 1);
  //
  //   // === Frequency modulation settings ===
  //   const double baseFreq = 0.06;
  //   const double freqScale = 0.1;
  //
  //   // === Layer settings ===
  //   final List<Color> layerColors = [
  //     color.withOpacity(0.8), // primary wave
  //     color.withOpacity(0.3), // shadow 1
  //     color.withOpacity(0.15), // shadow 2
  //   ];
  //
  //   final List<double> amplitudeMultipliers = [1.0, 0.6, 0.3];
  //   final List<double> phaseOffsets = [0, 0.5, 1.0];
  //
  //   for (int layer = 0; layer < layerColors.length; layer++) {
  //     final paint = Paint()
  //       ..color = layerColors[layer]
  //       ..strokeWidth = 2.5
  //       ..style = PaintingStyle.stroke;
  //
  //     final path = Path();
  //
  //     double x0 = 0;
  //     double amp0 = amplitudes[0];
  //     double freq0 = baseFreq + amp0 * freqScale;
  //     double y0 = midY - amp0 * sin(x0 * freq0 + progress + phaseOffsets[layer]) * midY * 0.8 * amplitudeMultipliers[layer];
  //
  //     path.moveTo(x0, y0);
  //
  //     for (int i = 1; i < amplitudes.length - 1; i++) {
  //       double x1 = (i - 1) * spacing;
  //       double a1 = amplitudes[i - 1];
  //       double f1 = baseFreq + a1 * freqScale;
  //       double y1 = midY - a1 * sin(x1 * f1 + progress + phaseOffsets[layer]) * midY * 0.8 * amplitudeMultipliers[layer];
  //
  //       double x2 = i * spacing;
  //       double a2 = amplitudes[i];
  //       double f2 = baseFreq + a2 * freqScale;
  //       double y2 = midY - a2 * sin(x2 * f2 + progress + phaseOffsets[layer]) * midY * 0.8 * amplitudeMultipliers[layer];
  //
  //       double cx = (x1 + x2) / 2;
  //       double cy = (y1 + y2) / 2;
  //
  //       path.quadraticBezierTo(x1, y1, cx, cy);
  //     }
  //
  //     canvas.drawPath(path, paint);
  //   }
  //
  //   // === Optional dynamic highlight at peak loudness ===
  //   double peakAmp = amplitudes.reduce((a, b) => a > b ? a : b);
  //   final glowPaint = Paint()
  //     ..color = color.withOpacity((peakAmp * 0.7).clamp(0.1, 0.6))
  //     ..strokeWidth = 5
  //     ..style = PaintingStyle.stroke
  //     ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
  //
  //   final glowPath = Path();
  //
  //   double x0 = 0;
  //   double amp0 = amplitudes[0];
  //   double freq0 = baseFreq + amp0 * freqScale;
  //   double y0 = midY - amp0 * sin(x0 * freq0 + progress) * midY * 0.8;
  //   glowPath.moveTo(x0, y0);
  //
  //   for (int i = 1; i < amplitudes.length - 1; i++) {
  //     double x1 = (i - 1) * spacing;
  //     double a1 = amplitudes[i - 1];
  //     double f1 = baseFreq + a1 * freqScale;
  //     double y1 = midY - a1 * sin(x1 * f1 + progress) * midY * 0.8;
  //
  //     double x2 = i * spacing;
  //     double a2 = amplitudes[i];
  //     double f2 = baseFreq + a2 * freqScale;
  //     double y2 = midY - a2 * sin(x2 * f2 + progress) * midY * 0.8;
  //
  //     double cx = (x1 + x2) / 2;
  //     double cy = (y1 + y2) / 2;
  //
  //     glowPath.quadraticBezierTo(x1, y1, cx, cy);
  //   }
  //
  //   canvas.drawPath(glowPath, glowPaint);
  // }

  @override
  bool shouldRepaint(covariant SmoothWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes;
  }
}
