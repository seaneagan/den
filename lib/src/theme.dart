
library den.src.theme;

import 'package:ansicolor/ansicolor.dart';

import 'yaml_highlighter.dart';

class DenTheme {
  final AnsiPen title = new AnsiPen()..white(bold: true);
  final AnsiPen dependency = new AnsiPen()..green(bold: true);
  final AnsiPen version = new AnsiPen()..blue(bold: true);
  final AnsiPen info = new AnsiPen()..white();
  final AnsiPen warning = new AnsiPen()..yellow();
  final AnsiPen error = new AnsiPen()..red(bold: true);
  final AnsiPen question = new AnsiPen()..white();
  final AnsiPen questionDefault = new AnsiPen()..green(bold: true);
  final AnsiPen yamlKey = new AnsiPen()..green(bold: true);
  final AnsiPen yamlScalar = new AnsiPen()..blue(bold:true);
}

final theme = new DenTheme();

String block(String title, Iterable<String> lines) => '''

${theme.title(title + ':')}

${lines.map((line) => '  $line').join('\n')}
''';

class DenYamlHighlighterTheme implements YamlHighlighterTheme {
  String formatKey(String key) => theme.yamlKey(key);
  String formatScalar(String scalar) => theme.yamlScalar(scalar);
}

final YamlHighlighterTheme yamlHighlighterTheme = new DenYamlHighlighterTheme();
