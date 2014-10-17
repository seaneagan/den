
library den.theme;

import 'package:ansicolor/ansicolor.dart';

class DenTheme {
  final AnsiPen title = new AnsiPen()..white(bold: true);
  final AnsiPen dependency = new AnsiPen()..green(bold: true);
  final AnsiPen version = new AnsiPen()..blue(bold: true);
  final AnsiPen info = new AnsiPen()..white();
  final AnsiPen warning = new AnsiPen()..yellow();
  final AnsiPen error = new AnsiPen()..red(bold: true);
}

final theme = new DenTheme();

String block(String title, String body) => '''

${theme.title(title)}

$body
''';
