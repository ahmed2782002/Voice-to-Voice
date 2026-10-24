import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/widgets/app_logo/app_logo.dart';
import '../../../../../core/widgets/settings_sheet/language_sheet.dart';
import '../../../../../core/widgets/settings_sheet/theme_sheet.dart';
import '../../../../history/presentation/view/screen/history_screen.dart';
import '../../view_model/translator_cubit.dart';
import '../../view_model/translator_state.dart';

class TranslatorHeader extends StatelessWidget {
  const TranslatorHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 12.h, 8.w, 8.h),
      child: Row(
        children: [
          const AppLogo(size: 34),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(AppStrings.appName.tr(), style: context.text.brand),
          ),
          PopupMenuButton<TranslatorMenuAction>(
            key: const Key('translator_menuButton'),
            tooltip: AppStrings.moreOptions.tr(),
            icon: Icon(AppIcons.more, size: 26.r, color: colors.textPrimary),
            offset: Offset(0, 44.h),
            onSelected: (action) => switch (action) {
              TranslatorMenuAction.history => _openHistory(context),
              TranslatorMenuAction.language => LanguageSheet.show(context),
              TranslatorMenuAction.theme => ThemeSheet.show(context),
            },
            itemBuilder: (context) => [
              for (final (action, icon, label) in const [
                (
                  TranslatorMenuAction.history,
                  AppIcons.history,
                  AppStrings.history,
                ),
                (
                  TranslatorMenuAction.language,
                  AppIcons.language,
                  AppStrings.appLanguage,
                ),
                (
                  TranslatorMenuAction.theme,
                  AppIcons.theme,
                  AppStrings.appTheme,
                ),
              ])
                PopupMenuItem(
                  key: Key('translator_menu_${action.name}'),
                  value: action,
                  child: Row(
                    children: [
                      Icon(icon, size: 20.r, color: colors.cyanBright),
                      SizedBox(width: 12.w),
                      Flexible(
                        child: Text(label.tr(), style: context.text.body),
                      ),
                    ],
                  ),
                ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.field.r),
              side: BorderSide(color: colors.border),
            ),
            color: colors.surfaceRaised,
          ),
        ],
      ),
    );
  }

  Future<void> _openHistory(BuildContext context) async {
    final route = HistoryScreen.route(context);
    final navigator = Navigator.of(context);
    await context.read<TranslatorCubit>().pauseEverything();
    await navigator.push(route);
  }
}
