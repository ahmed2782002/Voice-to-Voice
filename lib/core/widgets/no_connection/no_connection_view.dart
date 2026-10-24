import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_decorations.dart';
import '../../utils/constants/app_strings.dart';
import '../../utils/constants/app_text.dart';
import '../pulse_rings/pulse_rings_painter.dart';
import 'no_connection_painter.dart';

class NoConnectionView extends StatelessWidget {
  const NoConnectionView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  static const Curve _popCurve = Interval(0, 0.35, curve: Curves.easeOutBack);
  static const Curve _textCurve = Interval(
    0.45,
    0.85,
    curve: Curves.easeOutCubic,
  );

  static List<double> ringPhases(double progress) => [
    for (final delay in const [0.0, 0.25, 0.5])
      Interval(delay, (delay + 0.5).clamp(0, 1)).transform(progress),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.symmetric(horizontal: 28.w),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2000),
            builder: (context, progress, _) {
              final text = _textCurve.transform(progress);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220.r,
                    height: 220.r,
                    child: CustomPaint(
                      painter: PulseRingsPainter(
                        phases: ringPhases(progress),
                        opacity: 1,
                        color: colors.error,
                        innerRadius: 60.r,
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale: 0.5 + 0.5 * _popCurve.transform(progress),
                          child: Container(
                            width: 120.r,
                            height: 120.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.errorSurface,
                              border: Border.all(
                                color: colors.error.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: ExcludeSemantics(
                              child: CustomPaint(
                                size: Size.square(64.r),
                                painter: NoConnectionPainter(
                                  progress: progress,
                                  waveColor: colors.textPrimary,
                                  slashColor: colors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Opacity(
                    opacity: text,
                    child: Transform.translate(
                      offset: Offset(0, 16.h * (1 - text)),
                      child: Column(
                        children: [
                          Text(
                            AppStrings.noInternetTitle.tr(),
                            style: context.text.brand,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            AppStrings.noInternetHint.tr(),
                            style: context.text.body.copyWith(
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: colors.action,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              boxShadow: colors.actionGlow,
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                key: const Key('noConnection_retry'),
                                onTap: onRetry,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.symmetric(
                                    horizontal: 36.w,
                                    vertical: 14.h,
                                  ),
                                  child: Text(
                                    AppStrings.tryAgain.tr(),
                                    style: context.text.button,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
