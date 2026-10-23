import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/widgets/app_logo/app_logo.dart';
import '../../../../../core/widgets/pulse_rings/pulse_rings_painter.dart';
import '../../../../../core/widgets/waveform/audio_waveform.dart';
import '../../view_model/splash_motion.dart';

class SplashStage extends StatelessWidget {
  const SplashStage({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = progress;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240.r,
          height: 240.r,
          child: CustomPaint(
            painter: PulseRingsPainter(
              phases: SplashMotion.ringPhases(t),
              opacity: SplashMotion.ringsOpacity(t),
              color: colors.cyanBright,
              innerRadius: 52.r,
            ),
            child: Center(
              child: Opacity(
                opacity: SplashMotion.logoOpacity(t),
                child: Transform.rotate(
                  angle: SplashMotion.logoTurn(t),
                  child: Transform.scale(
                    scale: SplashMotion.logoScale(t),
                    child: const AppLogo(size: 104, glow: true),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Opacity(
          opacity: SplashMotion.titleOpacity(t),
          child: Transform.translate(
            offset: Offset(0, SplashMotion.titleOffset(t)),
            child: ShaderMask(
              shaderCallback: colors.action.createShader,
              child: Text(
                AppStrings.appName.tr(),
                style: context.text.display.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Opacity(
          opacity: SplashMotion.taglineOpacity(t),
          child: Transform.translate(
            offset: Offset(0, SplashMotion.taglineOffset(t)),
            child: Text(
              AppStrings.splashTagline.tr(),
              style: context.text.label,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 28.h),
        SizedBox(
          width: 180.w,
          child: AudioWaveform(
            levels: SplashMotion.bars(t),
            activeColor: colors.mintBright,
            inactiveColor: colors.cyanBright.withValues(alpha: 0.6),
            progress: t,
            height: 36,
          ),
        ),
      ],
    );
  }
}
