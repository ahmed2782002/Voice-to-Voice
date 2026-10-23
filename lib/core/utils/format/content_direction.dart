import 'package:easy_localization/easy_localization.dart' show Bidi;
import 'package:flutter/widgets.dart';

abstract final class ContentDirection {
  static TextDirection of(String text) => Bidi.detectRtlDirectionality(text)
      ? TextDirection.rtl
      : TextDirection.ltr;
}
