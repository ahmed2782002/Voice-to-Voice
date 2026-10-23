import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/routing/fade_route.dart';
import '../../../../../core/utils/constants/app_colors.dart';
import '../../view_model/splash_motion.dart';
import '../widgets/splash_stage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.next});

  final WidgetBuilder next;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: colors.overlayStyle,
      child: Scaffold(
        key: const Key('splash_screen'),
        backgroundColor: colors.backgroundBottom,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: colors.background),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: SplashMotion.duration,
              onEnd: () => Navigator.of(context).pushReplacement(
                FadeRoute<void>(builder: next, duration: SplashMotion.exit),
              ),
              builder: (context, progress, _) =>
                  SplashStage(progress: progress),
            ),
          ),
        ),
      ),
    );
  }
}
