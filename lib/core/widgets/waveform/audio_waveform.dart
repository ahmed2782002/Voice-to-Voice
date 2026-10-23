import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'waveform_painter.dart';

class AudioWaveform extends StatelessWidget {
  const AudioWaveform({
    super.key,
    required this.levels,
    required this.activeColor,
    required this.inactiveColor,
    this.progress = 0,
    this.height = 48,
  });

  final List<double> levels;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height.h,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: WaveformPainter(
              levels: levels,
              progress: progress,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}
