import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/services/audio/audio_player_service.dart';
import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/widgets/confirm_dialog/confirm_dialog.dart';
import '../../../data/repo/translation_history_store.dart';
import '../../view_model/history_cubit.dart';
import '../../view_model/history_state.dart';
import '../widgets/history_header.dart';
import '../widgets/history_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static Route<void> route(BuildContext context) {
    final store = context.read<TranslationHistoryStore>();
    final createPlayer = context.read<CreateAudioPlayer>();
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) =>
            HistoryCubit(store: store, player: createPlayer())..load(),
        child: const HistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HistoryCubit>();
    final colors = context.colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: colors.overlayStyle,
      child: Scaffold(
        key: const Key('history_screen'),
        backgroundColor: colors.backgroundBottom,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: colors.background),
          child: SafeArea(
            child: BlocConsumer<HistoryCubit, HistoryState>(
              listenWhen: (previous, current) => current.playbackFailed,
              listener: (context, _) => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(AppStrings.errorPlaybackFailed.tr())),
                ),
              builder: (context, state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HistoryHeader(
                    onBack: () => Navigator.of(context).maybePop(),
                    onClear: state.canClear
                        ? () async {
                            final confirmed = await ConfirmDialog.show(
                              context,
                              message: AppStrings.clearHistoryConfirm.tr(),
                              confirmLabel: AppStrings.clearHistory.tr(),
                            );
                            if (confirmed) await cubit.clear();
                          }
                        : null,
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 20.w),
                    child: Text(
                      AppStrings.historyLocalNotice.tr(),
                      style: context.text.caption,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: switch (state.status) {
                      HistoryStatus.loading => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      HistoryStatus.failed => Center(
                        child: Text(
                          AppStrings.historyLoadFailed.tr(),
                          style: context.text.label,
                        ),
                      ),
                      HistoryStatus.ready when state.isEmpty => Center(
                        child: Text(
                          AppStrings.historyEmpty.tr(),
                          key: const Key('history_empty'),
                          style: context.text.label,
                        ),
                      ),
                      HistoryStatus.ready => ListView.separated(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          20.w,
                          0,
                          20.w,
                          20.h,
                        ),
                        itemCount: state.entries.length,
                        separatorBuilder: (_, _) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final entry = state.entries[index];
                          return HistoryTile(
                            key: ValueKey('history_${entry.id}'),
                            entry: entry,
                            isPlaying: state.isPlayingEntry(entry.id),
                            onTogglePlayback: () => cubit.togglePlayback(entry),
                            onDelete: () => cubit.delete(entry),
                          );
                        },
                      ),
                    },
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
