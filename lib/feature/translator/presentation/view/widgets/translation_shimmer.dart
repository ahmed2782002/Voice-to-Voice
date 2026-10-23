import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/widgets/glass_card/glass_card.dart';

class TranslationShimmer extends StatelessWidget {
  const TranslationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final block = BoxDecoration(
      color: context.colors.mint,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    );
    return Semantics(
      liveRegion: true,
      label: AppStrings.translating.tr(),
      child: GlassCard(
        key: const Key('translator_processingCard'),
        gradient: context.colors.translatedCard,
        borderColor: context.colors.mint.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.translatedVoiceTitle.tr(),
              style: context.text.title.copyWith(color: context.colors.mint),
            ),
            Text(AppStrings.translatingHint.tr(), style: context.text.caption),
            SizedBox(height: 14.h),
            Shimmer.fromColors(
              baseColor: context.colors.mint.withValues(alpha: 0.18),
              highlightColor: context.colors.mint.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 56.h, decoration: block),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      for (var index = 0; index < 3; index++) ...[
                        Container(width: 32.r, height: 32.r, decoration: block),
                        SizedBox(width: 12.w),
                      ],
                      const Spacer(),
                      Container(width: 72.w, height: 12.h, decoration: block),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
