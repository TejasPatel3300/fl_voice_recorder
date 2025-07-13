import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

class WaveformWidget extends StatelessWidget {
  final Waveform waveform;
  final double progress;

  const WaveformWidget({super.key, required this.waveform, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaveformPainter(
        data: waveform.data,
        progress: progress,
        length: waveform.length,
        samplesPerPixel: waveform.samplesPerPixel,
        resolution: waveform.flags == 1 ? 8 : 16,
        color: Theme.of(context).colorScheme.primary,
      ),
      size: Size.infinite,
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<int> data;
  final double progress; // 0.0 to 1.0 (current audio position / duration)
  final int length;
  final int samplesPerPixel;
  final Color color;
  final int resolution; // 8 or 16 bit

  WaveformPainter({
    required this.data,
    required this.progress,
    required this.length,
    required this.samplesPerPixel,
    required this.resolution,
    required this.color,
  });

  double normalize(int value) {
    return resolution == 8 ? value / 128.0 : value / 32768.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / length;
    final midY = size.height / 2;
    final activePaint = Paint()..color = color;
    final inactivePaint = Paint()..color = Colors.grey.withValues(alpha:0.3);

    for (int i = 0; i < length; i++) {
      int min = data[2 * i];
      int max = data[2 * i + 1];

      double normMin = normalize(min).clamp(-1.0, 1.0);
      double normMax = normalize(max).clamp(-1.0, 1.0);

      double top = midY + (normMin * midY);
      double bottom = midY + (normMax * midY);

      final paint = (i / length) <= progress ? activePaint : inactivePaint;

      canvas.drawLine(
        Offset(i * barWidth, top),
        Offset(i * barWidth, bottom),
        paint..strokeWidth = barWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}
