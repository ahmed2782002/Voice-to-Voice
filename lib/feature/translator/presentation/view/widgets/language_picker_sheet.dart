import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';
import '../../../../../core/utils/format/duration_format.dart';
import '../../view_model/translator_cubit.dart';
import '../../view_model/translator_state.dart';
import 'language_search_field.dart';
import 'language_tile.dart';

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  static Future<void> show(BuildContext context, TranslatorCubit cubit) {
    cubit.resetSearch();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet.r),
        ),
      ),
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const LanguagePickerSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TranslatorCubit>();
    final count = DurationFormat.localizeDigits(
      '${cubit.state.languages.length}',
      context.locale.languageCode,
    );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          16.w,
          12.h,
          16.w,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(AppStrings.chooseLanguage.tr(), style: context.text.brand),
            Text(
              AppStrings.supportedLanguagesCount.tr(args: [count]),
              style: context.text.caption,
            ),
            SizedBox(height: 12.h),
            LanguageSearchField(
              controller: cubit.searchController,
              onChanged: cubit.onSearchChanged,
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: BlocBuilder<TranslatorCubit, TranslatorState>(
                buildWhen: (previous, current) =>
                    previous.searchQuery != current.searchQuery ||
                    previous.language != current.language,
                builder: (context, state) {
                  final languages = state.filteredLanguages;
                  if (languages.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.noLanguagesFound.tr(),
                        style: context.text.label,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: languages.length,
                    itemBuilder: (context, index) => LanguageTile(
                      key: ValueKey('language_${languages[index].code}'),
                      language: languages[index],
                      selected: languages[index] == state.language,
                      onTap: () {
                        cubit.selectLanguage(languages[index]);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
