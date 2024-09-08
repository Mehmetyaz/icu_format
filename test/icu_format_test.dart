import 'package:icu_format/icu_format.dart';
import 'package:test/test.dart';

(int, int) matchIndex(String input, String pattern) {
  final match = RegExp(pattern).firstMatch(input);
  return (match!.start, match.end);
}

void main() {
  group("Utils", () {
    test("most outer braces should be found", () {
      final t1 = "{a}";
      expect(ICUFormat.findAllOuterMostBraces(t1)[0], matchIndex(t1, "{a}"));
      final t2 = "bc {a}";
      expect(ICUFormat.findAllOuterMostBraces(t2)[0], matchIndex(t2, "{a}"));
      final t3 = "bc {a} def";
      expect(ICUFormat.findAllOuterMostBraces(t3)[0], matchIndex(t3, "{a}"));
      final t4 = "{a {b} c}";
      expect(
          ICUFormat.findAllOuterMostBraces(t4)[0], matchIndex(t4, "{a {b} c}"));
      final t5 = "{a {b {c}} d}";
      expect(ICUFormat.findAllOuterMostBraces(t5)[0],
          matchIndex(t5, "{a {b {c}} d}"));
      final t6 = "'{ {a {b {c} d} e}";
      expect(ICUFormat.findAllOuterMostBraces(t6)[0],
          matchIndex(t6, "{a {b {c} d} e}"));
      final t7 = "{a {b {c} d} e} }'";
      expect(ICUFormat.findAllOuterMostBraces(t7)[0],
          matchIndex(t7, "{a {b {c} d} e}"));
      final t8 = "{a {b {c} d} e} {second}";
      expect(ICUFormat.findAllOuterMostBraces(t8)[0],
          matchIndex(t8, "{a {b {c} d} e}"));
      expect(
          ICUFormat.findAllOuterMostBraces(t8)[1], matchIndex(t8, "{second}"));
    });
  });

  group("Translation", () {
    final arb = ICUFormat({
      "hello": "Hello, {name}",
      "select":
          "Hello {gender, select, male{Mr. {name}} female{Ms. {name}} other{Dear {name}}}",
      "plural": "{count, plural, =0{No items} =1{One item} other{# items}}",
      "plural2": "{count, plural, zero{No items} one{One item} other{# items}}",
      "nested":
          "You have {count, plural, =0{no messages} =1{one message} other{{count} messages}} from {gender, select, male{Mr. {name}} female{Ms. {name}} other{Dear {name}}}",
    });

    group('hello translation', () {
      test("with name", () {
        expect(arb.translate("hello", "en", {"name": "John"}), "Hello, John");
        expect(arb.translate("hello", "en", {"name": "Alice"}), "Hello, Alice");
      });

      test("with empty name", () {
        expect(arb.translate("hello", "en", {"name": ""}), "Hello, ");
      });
    });

    group('select translation', () {
      test("male gender", () {
        expect(
            arb.translate("select", "en", {"name": "John", "gender": "male"}),
            "Hello Mr. John");
      });

      test("female gender", () {
        expect(
            arb.translate(
                "select", "en", {"name": "Alice", "gender": "female"}),
            "Hello Ms. Alice");
      });

      test("other gender", () {
        expect(
            arb.translate("select", "en", {"name": "Sam", "gender": "other"}),
            "Hello Dear Sam");
      });

      test("unspecified gender", () {
        expect(
            arb.translate("select", "en", {"name": "Alex"}), "Hello Dear Alex");
      });
    });

    group('plural translation', () {
      test("zero items", () {
        expect(arb.translate("plural", "en", {"count": 0}), "No items");
      });

      test("one item", () {
        expect(arb.translate("plural", "en", {"count": 1}), "One item");
      });

      test("multiple items", () {
        expect(arb.translate("plural", "en", {"count": 2}), "2 items");
        expect(arb.translate("plural", "en", {"count": 10}), "10 items");
      });
    });

    group('plural2 translation', () {
      test("zero items", () {
        expect(arb.translate("plural2", "en", {"count": 0}), "No items");
      });

      test("one item", () {
        expect(arb.translate("plural2", "en", {"count": 1}), "One item");
      });

      test("other items", () {
        expect(arb.translate("plural2", "en", {"count": 2}), "2 items");
        expect(arb.translate("plural2", "en", {"count": 3}), "3 items");
        expect(arb.translate("plural2", "en", {"count": 4}), "4 items");
        expect(arb.translate("plural2", "en", {"count": 10000}), "10000 items");
      });
    });

    group('nested translation', () {
      test("no messages, male", () {
        expect(
            arb.translate(
                "nested", "en", {"count": 0, "name": "John", "gender": "male"}),
            "You have no messages from Mr. John");
      });

      test("one message, female", () {
        expect(
            arb.translate("nested", "en",
                {"count": 1, "name": "Alice", "gender": "female"}),
            "You have one message from Ms. Alice");
      });

      test("multiple messages, other gender", () {
        expect(
            arb.translate(
                "nested", "en", {"count": 5, "name": "Sam", "gender": "other"}),
            "You have 5 messages from Dear Sam");
      });
    });
  });
}
