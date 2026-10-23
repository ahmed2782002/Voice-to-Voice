import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_colors.dart';
import '../../../../../core/utils/constants/app_decorations.dart';
import '../../../../../core/utils/constants/app_icons.dart';
import '../../../../../core/utils/constants/app_strings.dart';
import '../../../../../core/utils/constants/app_text.dart';

class LanguageSearchField extends StatelessWidget {
  const LanguageSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('translator_languageSearch'),
      controller: controller,
      onChanged: onChanged,
      style: context.text.body,
      cursorColor: context.colors.cyanBright,
      decoration: InputDecoration(
        hintText: AppStrings.searchLanguages.tr(),
        hintStyle: context.text.label,
        prefixIcon: Icon(AppIcons.search, color: context.colors.textMuted),
        filled: true,
        fillColor: context.colors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
