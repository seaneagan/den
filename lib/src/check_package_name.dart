
// TODO: This code was copied with minor changes from:
//   https://code.google.com/p/dart/source/browse/branches/bleeding_edge/dart/sdk/lib/_internal/pub/lib/src/validator/name.dart
// Reuse that if it gets released via https://dartbug.com/21169.
library den.src.check_package_name;

List checkPackageName(String name) {
  var description = 'Package name "$name"';
  var messages = [];

  if (name == "") {
    messages.add("$description may not be empty.");
  } else if (!new RegExp(r"^[a-zA-Z0-9_]*$").hasMatch(name)) {
    messages.add("$description may only contain letters, numbers, and "
        "underscores.\n"
        "Using a valid Dart identifier makes the name usable in Dart code.");
  } else if (!new RegExp(r"^[a-zA-Z_]").hasMatch(name)) {
    messages.add("$description must begin with a letter or underscore.\n"
        "Using a valid Dart identifier makes the name usable in Dart code.");
  } else if (RESERVED_WORDS.contains(name.toLowerCase())) {
    messages.add("$description may not be a reserved word in Dart.\n"
        "Using a valid Dart identifier makes the name usable in Dart code.");
  } else if (new RegExp(r"[A-Z]").hasMatch(name)) {
    messages.add('$description should be lower-case. Maybe use '
        '"${unCamelCase(name)}"?');
  }

  return messages;
}

/// Dart reserved words, from the Dart spec.
final RESERVED_WORDS = [
"assert", "break", "case", "catch", "class", "const", "continue", "default",
"do", "else", "extends", "false", "final", "finally", "for", "if", "in", "is",
"new", "null", "return", "super", "switch", "this", "throw", "true", "try",
"var", "void", "while", "with"
];

String unCamelCase(String source) {
  var builder = new StringBuffer();
  var lastMatchEnd = 0;
  for (var match in new RegExp(r"[a-z]([A-Z])").allMatches(source)) {
    builder
      ..write(source.substring(lastMatchEnd, match.start + 1))
      ..write("_")
      ..write(match.group(1).toLowerCase());
    lastMatchEnd = match.end;
  }
  builder.write(source.substring(lastMatchEnd));
  return builder.toString().toLowerCase();
}
