import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/widgets/no_connection/no_connection_view.dart';
import '../../view_model/translator_cubit.dart';
import '../../view_model/translator_state.dart';
import '../widgets/ai_notice_banner.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/capture_controls.dart';
import '../widgets/language_selector_field.dart';
import '../widgets/source_audio_card.dart';
import '../widgets/translate_button.dart';
import '../widgets/translated_audio_card.dart';
import '../widgets/translator_error_card.dart';
import '../widgets/translator_header.dart';

class TranslatorScreen extends StatelessWidget {
  const TranslatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TranslatorCubit>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.colors.overlayStyle,
      child: Scaffold(
        backgroundColor: context.colors.backgroundBottom,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: context.colors.background),
          child: SafeArea(
            child: BlocBuilder<TranslatorCubit, TranslatorState>(
              builder: (context, state) => Column(
                children: [
                  const TranslatorHeader(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: state.isOffline
                          ? NoConnectionView(
                              key: const Key('translator_offline'),
                              onRetry: cubit.checkConnectivity,
                            )
                          : Column(
                              key: const Key('translator_content'),
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      20.w,
                                      8.h,
                                      20.w,
                                      16.h,
                                    ),
                                    child: Column(
                                      children: [
                                        AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          alignment:
                                              AlignmentDirectional.topCenter,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            child: state.showAiNotice
                                                ? Padding(
                                                    key: const Key(
                                                      'translator_aiNotice',
                                                    ),
                                                    padding:
                                                        EdgeInsetsDirectional.only(
                                                          bottom: 16.h,
                                                        ),
                                                    child:
                                                        const AiNoticeBanner(),
                                                  )
                                                : const SizedBox(
                                                    width: double.infinity,
                                                  ),
                                          ),
                                        ),
                                        if (state.failureMessage
                                            case final message?) ...[
                                          TranslatorErrorCard(
                                            message: message.tr(),
                                            actionLabel: state.failureAction
                                                .tr(),
                                            onAction: cubit.retry,
                                          ),
                                          SizedBox(height: 16.h),
                                        ],
                                        SourceAudioCard(
                                          state: state,
                                          onPlay: () => cubit.togglePlayback(
                                            AudioTrack.source,
                                          ),
                                          onPause: () => cubit.togglePlayback(
                                            AudioTrack.source,
                                          ),
                                          onReplay: () =>
                                              cubit.replay(AudioTrack.source),
                                          onDiscard: cubit.discardRecording,
                                        ),
                                        SizedBox(height: 18.h),
                                        LanguageSelectorField(
                                          language: state.language,
                                          statusLabel: state.languageStatusLabel
                                              ?.tr(),
                                          onTap: switch (state) {
                                            TranslatorState(
                                              canPickLanguage: true,
                                            ) =>
                                              () => LanguagePickerSheet.show(
                                                context,
                                                cubit,
                                              ),
                                            TranslatorState(
                                              languagesStatus: LanguagesStatus
                                                  .failed,
                                              isProcessing: false,
                                            ) =>
                                              cubit.loadLanguages,
                                            _ => null,
                                          },
                                        ),
                                        SizedBox(height: 20.h),
                                        TranslateButton(
                                          isProcessing: state.isProcessing,
                                          onPressed: state.canTranslate
                                              ? cubit.translate
                                              : null,
                                        ),
                                        SizedBox(height: 18.h),
                                        if (state.isProcessing || state.isReady)
                                          TranslatedAudioCard(
                                            state: state,
                                            onPlay: () => cubit.togglePlayback(
                                              AudioTrack.translated,
                                            ),
                                            onPause: () => cubit.togglePlayback(
                                              AudioTrack.translated,
                                            ),
                                            onReplay: () => cubit.replay(
                                              AudioTrack.translated,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    top: 8.h,
                                    bottom: 20.h,
                                  ),
                                  child: CaptureControls(
                                    isRecording: state.isRecording,
                                    level: state.currentLevel,
                                    onRecord: state.canRecord
                                        ? cubit.toggleRecording
                                        : null,
                                    onImport: state.canImport
                                        ? cubit.importAudio
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
