import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_decorations.dart';
import '../../utils/constants/app_strings.dart';
import '../../utils/constants/app_text.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.message,
    required this.confirmLabel,
  });

  final String message;
  final String confirmLabel;

  static Future<bool> show(
    BuildContext context, {
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          ConfirmDialog(message: message, confirmLabel: confirmLabel),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card.r),
        side: BorderSide(color: colors.border),
      ),
      content: Text(message, style: context.text.body),
      actions: [
        TextButton(
          key: const Key('confirm_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppStrings.cancel.tr(), style: context.text.label),
        ),
        TextButton(
          key: const Key('confirm_accept'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: context.text.label.copyWith(color: colors.error),
          ),
        ),
      ],
    );
  }
}
