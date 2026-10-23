import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/constants/app_text.dart';

class TranscriptSection extends StatelessWidget {
  const TranscriptSection({
    super.key,
    required this.label,
    required this.text,
    required this.color,
  });

  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.caption.copyWith(color: color)),
          SizedBox(height: 4.h),
          SelectableText(text, style: context.text.body),
        ],
      ),
    );
  }
}
