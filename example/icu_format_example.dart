import 'package:icu_format/icu_format.dart';

void testParsePlaceholder() {
  var result;

  // Test simple case
  result = PlaceholderMatch.parsePlaceholders("{name}");
  print("Simple: Key: ${result?.key}, Type: ${result?.type}");

  // Test plural case
  result = PlaceholderMatch.parsePlaceholders(
      "{count, plural, =0{No items} =1{One item} other{# items}}");
  print(
      "Plural: Key: ${result?.key}, Type: ${result?.type}, Options: ${result?.options}");

  result = PlaceholderMatch.parsePlaceholders(
    "{count, plural, zero{No items} one{One item} few{# items} many{# items} other{# items}}",
  );
  print(
      "Plural 2: Key: ${result?.key}, Type: ${result?.type}, Options: ${result?.options}");

  // Test select case
  result = PlaceholderMatch.parsePlaceholders(
      "{gender, select, male{Mr. {name}} female{Ms. {name}} other{Dear {name}}}");
  print(
      "Select: Key: ${result?.key}, Type: ${result?.type}, Options: ${result?.options}");
}

void main() {
  testParsePlaceholder();
}
