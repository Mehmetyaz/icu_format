// Documentation https://www.unicode.org/cldr/charts/45/supplemental/language_plural_rules.html

enum PluralType {
  zero,
  one,
  two,
  few,
  many,
  other,
}

enum PluralRuleType {
  cardinal,
  ordinal,
}

typedef PluralRule = PluralType Function(num);

// ... existing code ...

final Map<String, Map<PluralRuleType, PluralRule>> pluralRules = {
  "en": {
    PluralRuleType.cardinal: (n) {
      if (n == 0) return PluralType.zero;
      if (n == 1) return PluralType.one;
      if (n == 2) return PluralType.two;
      if (n == 3) return PluralType.few;
      return PluralType.other;
    },
    PluralRuleType.ordinal: (n) {
      if (n % 10 == 1 && n % 100 != 11) return PluralType.one;
      if (n % 10 == 2 && n % 100 != 12) return PluralType.two;
      if (n % 10 == 3 && n % 100 != 13) return PluralType.few;
      return PluralType.other;
    },
  },
  "tr": {
    PluralRuleType.cardinal: (n) {
      if (n == 1) return PluralType.one;
      return PluralType.other;
    },
    PluralRuleType.ordinal: (n) {
      return PluralType.other;
    },
  },
  "ar": {
    PluralRuleType.cardinal: (n) {
      if (n == 0) return PluralType.zero;
      if (n == 1) return PluralType.one;
      if (n == 2) return PluralType.two;
      // n % 100 = 3..10 few
      if (n % 100 >= 3 && n % 100 <= 10) return PluralType.few;
      // n % 100 = 11..99 many
      if (n % 100 >= 11 && n % 100 <= 99) return PluralType.many;
      return PluralType.other;
    },
    PluralRuleType.ordinal: (n) {
      return PluralType.other;
    }
  }
};

// ... existing code ...
