import 'package:icu_format/src/number.dart';

/// Dynamic ICU Message Format
class ICUFormat {
  Map<String, dynamic> arb;

  ICUFormat(this.arb);

  static Map<String, dynamic>? _placeholders(
      String key, Map<String, dynamic> arb) {
    return (arb["@$key"] as Map<String, dynamic>?)?["placeholders"];
  }

  static (int, int)? findOuterMostBraces(String input) {
    int openCount = 0;
    int? startIndex;

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '{' && (i == 0 || input[i - 1] != "'")) {
        if (openCount == 0) {
          startIndex = i;
        }
        openCount++;
      } else if (input[i] == '}' &&
          (i == input.length - 1 || input[i + 1] != "'")) {
        openCount--;
        if (openCount == 0 && startIndex != null) {
          return (startIndex, i + 1);
        }
      }
    }

    return null;
  }

  static List<(int, int)> findAllOuterMostBraces(String input) {
    int openCount = 0;
    int? startIndex;
    List<(int, int)> matches = [];
    for (int i = 0; i < input.length; i++) {
      if (input[i] == '{' && (i == 0 || input[i - 1] != "'")) {
        if (openCount == 0) {
          startIndex = i;
        }
        openCount++;
      } else if (input[i] == '}' &&
          (i == input.length - 1 || input[i + 1] != "'")) {
        openCount--;
        if (openCount == 0 && startIndex != null) {
          matches.add((startIndex, i + 1));
          startIndex = null;
        }
      }
    }

    return matches;
  }

  ({String? value, Map<String, dynamic>? placeholders}) lookup(String key) {
    key = key.trim();
    Map<String, dynamic> current = arb;
    if (key.contains('.')) {
      final keys = key.split('.');
      for (var key in keys) {
        if (current[key] is Map<String, dynamic>) {
          current = current[key] as Map<String, dynamic>;
        } else {
          return (
            value: current[key] as String?,
            placeholders: _placeholders(key, current)
          );
        }
      }
    }

    return (value: arb[key] as String?, placeholders: _placeholders(key, arb));
  }

  static String format(String value, Map<String, dynamic>? params,
      Map<String, dynamic>? options, String lang) {
    (int, int)? matches = findOuterMostBraces(value);

    while (matches != null) {
      final placeholder = PlaceholderMatch.parsePlaceholders(
          value.substring(matches.$1, matches.$2));
      if (placeholder == null) continue;
      value = value.replaceRange(matches.$1, matches.$2,
          placeholder.build(params ?? {}, options ?? {}, lang));
      matches = findOuterMostBraces(value);
    }

    return value;
  }

  String translate(String key, String lang, [Map<String, dynamic>? params]) {
    final val = lookup(key);
    if (val.value == null) return key;
    return format(val.value!, params, val.placeholders, lang);
  }
}

abstract class PlaceholderMatch {
  final String key;
  final String raw;
  final PlaceholderType type;

  PlaceholderMatch({required this.key, required this.type, required this.raw});

  static List<(String key, int start, int end)> findOptionsWithKeys(
      String input) {
    List<(String key, int start, int end)> matches = [];
    int openCount = 0;
    int? startIndex;
    String currentKey = '';

    for (int i = 0; i < input.length; i++) {
      if (input[i] == '{' && (i == 0 || input[i - 1] != "'")) {
        if (openCount == 0) {
          startIndex = i;
          // Capture the key before the opening brace
          int keyStart = i - 1;
          while (keyStart >= 0 &&
              input[keyStart] != ' ' &&
              input[keyStart] != ',') {
            keyStart--;
          }
          currentKey = input.substring(keyStart + 1, i).trim();
        }
        openCount++;
      } else if (input[i] == '}' &&
          (i == input.length - 1 || input[i + 1] != "'")) {
        openCount--;
        if (openCount == 0 && startIndex != null) {
          matches.add((currentKey, startIndex, i + 1));
          startIndex = null;
          currentKey = '';
        }
      }
    }

    return matches;
  }

  static PlaceholderMatch? parsePlaceholders(String placeholder) {
    placeholder = placeholder.trim();

    // Simple {param} case
    if (RegExp(r'^\{[^,{}]+\}$').hasMatch(placeholder)) {
      return SimplePlaceholderMatch(
          key: placeholder.substring(1, placeholder.length - 1).trim(),
          type: PlaceholderType.simple,
          raw: placeholder);
    }

    // Complex case: {key, type, options}
    final match =
        RegExp(r'^\{([^,]+),\s*([^,]+),\s*(.+)\}$').firstMatch(placeholder);
    if (match == null) return null;

    final key = match.group(1)!.trim();
    final type = PlaceholderType.fromString(match.group(2)!.trim());
    final optionsString = match.group(3)!;

    final options = <String, String>{};
    final optionsWithKeys = findOptionsWithKeys(optionsString);

    for (var (optionKey, start, end) in optionsWithKeys) {
      options[optionKey] = optionsString.substring(start + 1, end - 1).trim();
    }

    switch (type) {
      case PlaceholderType.plural:
        return PluralPlaceholderMatch(
            key: key, type: type, options: options, raw: placeholder);
      case PlaceholderType.select:
        return SelectPlaceholderMatch(
            key: key, type: type, options: options, raw: placeholder);
      case PlaceholderType.simple:
        return SimplePlaceholderMatch(key: key, type: type, raw: placeholder);
    }
  }

  String build(
      Map<String, dynamic> params, Map<String, dynamic> opts, String lang);
}

class SimplePlaceholderMatch extends PlaceholderMatch {
  SimplePlaceholderMatch(
      {required super.key, required super.type, required super.raw});

  @override
  String build(
      Map<String, dynamic> params, Map<String, dynamic> opts, String lang) {
    return params[key].toString();
  }
}

class PluralPlaceholderMatch extends PlaceholderMatch {
  PluralPlaceholderMatch(
      {required super.key,
      required super.type,
      required this.options,
      required super.raw});

  final Map<String, String> options;

  @override
  String build(
      Map<String, dynamic> params, Map<String, dynamic> opts, String lang) {
    final val = (params[key] as num?);
    String res;

    final format = opts[key]?["format"];

    PluralRuleType plType;

    if (format == "ordinal") {
      plType = PluralRuleType.ordinal;
    } else {
      plType = PluralRuleType.cardinal;
    }

    if (val == null) {
      res = options["other"] ?? "";
      return ICUFormat.format(res, params, options, lang);
    }

    res = options["=${val.toString()}"] ??
        options[
            (pluralRules[lang]?[plType]?.call(val) ?? PluralType.other).name] ??
        options["other"] ??
        "";

    // inner placeholders haricindeki # leri number ile replace et
    final innerMatches = ICUFormat.findAllOuterMostBraces(res);

    if (innerMatches.isEmpty) {
      res = res.replaceAll("#", val.toString());
    } else {
      // # leri number ile replace et
      final reg = RegExp(r'#');
      final matches = reg.allMatches(res);
      for (var match in matches) {
        final index = match.start;
        // between any inner matches
        if (innerMatches.any((e) => e.$1 <= index && e.$2 >= index)) {
          continue;
        }
        res = res.replaceRange(index, index + 1, val.toString());
      }
    }

    return ICUFormat.format(res, params, options, lang);
  }
}

class SelectPlaceholderMatch extends PlaceholderMatch {
  SelectPlaceholderMatch(
      {required super.key,
      required super.type,
      required this.options,
      required super.raw});

  final Map<String, String> options;

  @override
  String build(
      Map<String, dynamic> params, Map<String, dynamic> opts, String lang) {
    final val = params[key] as String?;
    final res = options[val] ?? options["other"] ?? "";
    return ICUFormat.format(res, params, opts, lang);
  }
}

enum PlaceholderType {
  plural,
  select,
  simple;

  static PlaceholderType fromString(String type) {
    return PlaceholderType.values.firstWhere(
        (e) => e.toString().split('.').last == type,
        orElse: () => throw ArgumentError('Invalid placeholder type: $type'));
  }
}
