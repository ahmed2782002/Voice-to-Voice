abstract final class DurationFormat {
  static const List<String> _arabicDigits = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  static String clock(Duration duration, String languageCode) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return localizeDigits('$minutes:$seconds', languageCode);
  }

  static String progress(
    Duration position,
    Duration total,
    String languageCode,
  ) {
    final shown = position > total ? total : position;
    return '${clock(shown, languageCode)} / ${clock(total, languageCode)}';
  }

  static String localizeDigits(String value, String languageCode) {
    if (languageCode != 'ar') return value;
    return value.replaceAllMapped(
      RegExp('[0-9]'),
      (match) => _arabicDigits[int.parse(match[0]!)],
    );
  }
}
