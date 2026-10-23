import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/utils/format/content_direction.dart';
import '../../../../../core/utils/format/date_label.dart';
import '../../../../../core/widgets/audio_control_button/audio_control_button.dart';
import '../../../../../core/widgets/glass_card/glass_card.dart';
import '../../../data/model/translation_history_entry.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.entry,
    required this.isPlaying,
    required this.onTogglePlayback,
    required this.onDelete,
  });

  final TranslationHistoryEntry entry;
  final bool isPlaying;
  final VoidCallback onTogglePlayback;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final language = context.locale.languageCode;
    return GlassCard(
      padding: EdgeInsetsDirectional.fromSTEB(14.w, 12.h, 8.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.historyLanguagePair.tr(
              args: [entry.sourceName, entry.targetName],
            ),
            style: context.text.label.copyWith(color: colors.mint),
          ),
          Text(
            DateLabel.of(entry.createdAt, language),
            style: context.text.caption,
          ),
          if (entry.translatedText.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              entry.translatedText,
              style: context.text.body,
              textDirection: ContentDirection.of(entry.translatedText),
            ),
          ],
          if (entry.originalText.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              entry.originalText,
              style: context.text.caption,
              textDirection: ContentDirection.of(entry.originalText),
            ),
          ],
          Row(
            children: [
              AudioControlButton(
                key: Key('history_play_${entry.id}'),
                icon: isPlaying ? AppIcons.pause : AppIcons.play,
                semanticLabel: isPlaying
                    ? AppStrings.pause.tr()
                    : AppStrings.play.tr(),
                color: colors.mint,
                onPressed: onTogglePlayback,
              ),
              const Spacer(),
              AudioControlButton(
                key: Key('history_delete_${entry.id}'),
                icon: AppIcons.delete,
                semanticLabel: AppStrings.deleteEntry.tr(),
                size: 22,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
