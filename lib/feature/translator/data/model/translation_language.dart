import 'package:equatable/equatable.dart';

class TranslationLanguage extends Equatable {
  const TranslationLanguage({
    required this.code,
    required this.name,
    String? nativeName,
    this.input = true,
    this.output = true,
  }) : nativeName = nativeName ?? name;

  final String code;
  final String name;
  final String nativeName;
  final bool input;
  final bool output;

  String get displayName => name == nativeName ? name : '$name - $nativeName';

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        nativeName.toLowerCase().contains(normalized) ||
        code.toLowerCase() == normalized;
  }

  static const TranslationLanguage arabic = TranslationLanguage(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
  );

  static TranslationLanguage? fromJson(Object? json) {
    if (json is String) {
      final code = json.trim();
      return code.isEmpty ? null : TranslationLanguage(code: code, name: code);
    }
    if (json is! Map<String, dynamic>) return null;
    final code = _text(json['code']);
    if (code == null) return null;
    final name = _text(json['name']) ?? _text(json['englishName']) ?? code;
    return TranslationLanguage(
      code: code,
      name: name,
      nativeName:
          _text(json['native']) ??
          _text(json['nativeName']) ??
          _text(json['native_name']),
      input: json['input'] is bool ? json['input'] as bool : true,
      output: json['output'] is bool ? json['output'] as bool : true,
    );
  }

  static const List<String> _listKeys = [
    'target',
    'targets',
    'output',
    'source',
    'sources',
    'input',
    'languages',
    'data',
  ];

  static List<TranslationLanguage> listFromJson(Object? json) {
    final seen = <String>{};
    return [
      for (final item in _items(json))
        if (fromJson(item) case final language? when seen.add(language.code))
          language,
    ];
  }

  static List<dynamic> _items(Object? json) {
    if (json is List<dynamic>) return json;
    if (json is Map<String, dynamic>) {
      if (json['data'] case final Map<String, dynamic> nested) {
        return _items(nested);
      }
      final items = [
        for (final key in _listKeys)
          if (json[key] case final List<dynamic> list) ...list,
      ];
      if (items.isNotEmpty) return items;
    }
    throw FormatException('Unexpected languages response', json);
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [code];
}
