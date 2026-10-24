import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/utils/format/duration_format.dart';
import '../../../../../core/widgets/glass_card/glass_card.dart';
import '../../../../../core/widgets/waveform/audio_waveform.dart';
import '../../view_model/translator_state.dart';
import 'ai_voice_badge.dart';
import 'playback_controls.dart';
import 'transcript_section.dart';

class TranslatedAudioCard extends StatelessWidget {
  const TranslatedAudioCard({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onReplay,
  });

  final TranslatorState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    const track = AudioTrack.translated;
    final processing = state.isProcessing;
    final language = state.result?.language ?? state.language;
    final block = BoxDecoration(
      color: context.colors.mint,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    );
    return Semantics(
      liveRegion: processing,
      label: processing ? AppStrings.translating.tr() : null,
      child: GlassCard(
        key: Key(
          processing
              ? 'translator_processingCard'
              : 'translator_translatedCard',
        ),
        gradient: context.colors.translatedCard,
        borderColor: context.colors.mint.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  AppStrings.translatedVoiceTitle.tr(),
                  style: context.text.title.copyWith(
                    color: context.colors.mint,
                  ),
                ),
                if (!processing && (state.result?.aiGenerated ?? true))
                  const AiVoiceBadge(),
              ],
            ),
            Text(
              processing
                  ? AppStrings.translatingHint.tr()
                  : AppStrings.translatedInto.tr(args: [language.displayName]),
              style: context.text.caption,
            ),
            SizedBox(height: 14.h),
            if (processing)
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
                          Container(
                            width: 32.r,
                            height: 32.r,
                            decoration: block,
                          ),
                          SizedBox(width: 12.w),
                        ],
                        const Spacer(),
                        Container(width: 72.w, height: 12.h, decoration: block),
                      ],
                    ),
                  ],
                ),
              )
            else ...[
              AudioWaveform(
                levels: state.translatedBars,
                progress: state.progressOf(track),
                activeColor: context.colors.mintBright,
                inactiveColor: context.colors.mint.withValues(alpha: 0.35),
                height: 56,
              ),
              SizedBox(height: 8.h),
              PlaybackControls(
                keyPrefix: 'translator_translated',
                isPlaying: state.isPlayingTrack(track),
                progressLabel: DurationFormat.progress(
                  state.positionOf(track),
                  state.durationOf(track),
                  context.locale.languageCode,
                ),
                color: context.colors.mint,
                onPlay: onPlay,
                onPause: onPause,
                onReplay: onReplay,
              ),
              if (state.result?.originalText case final original?
                  when original.isNotEmpty)
                TranscriptSection(
                  key: const Key('translator_originalText'),
                  label: AppStrings.originalText.tr(),
                  text: original,
                  color: context.colors.textSecondary,
                ),
              if (state.result?.translatedText case final translated?
                  when translated.isNotEmpty)
                TranscriptSection(
                  key: const Key('translator_translatedText'),
                  label: AppStrings.translatedText.tr(),
                  text: translated,
                  color: context.colors.mint,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
