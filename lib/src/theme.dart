
library den.theme;

import 'package:ansicolor/ansicolor.dart';

class DenTheme {
  final AnsiPen title = new AnsiPen()..white(bold: true);
  final AnsiPen dependency = new AnsiPen()..green(bold: true);
  final AnsiPen version = new AnsiPen()..blue(bold: true);
  final AnsiPen info = new AnsiPen()..white();
  final AnsiPen warning = new AnsiPen()..yellow();
  final AnsiPen error = new AnsiPen()..red(bold: true);
  final AnsiPen question = new AnsiPen()..white();
  final AnsiPen questionDefault = new AnsiPen()..green(bold: true);
  final AnsiPen field = new AnsiPen()..green(bold: true);
  final AnsiPen value = new AnsiPen()..blue(bold:true);
}

final theme = new DenTheme();

String block(String title, Iterable<String> lines) => '''

${theme.title(title + ':')}

${lines.map((line) => '  $line').join('\n')}
''';
