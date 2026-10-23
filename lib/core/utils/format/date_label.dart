import 'package:easy_localization/easy_localization.dart';

import 'duration_format.dart';

abstract final class DateLabel {
  static String of(DateTime value, String languageCode) {
    final formatted = DateFormat.yMMMd(languageCode).add_jm().format(value);
    return DurationFormat.localizeDigits(formatted, languageCode);
  }
}
