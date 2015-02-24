
library den.src.cli;

import 'package:unscripted/unscripted.dart';

import 'commands/bump.dart';
import 'commands/fetch.dart';
import 'commands/install.dart';
import 'commands/pull.dart';
import 'commands/spec.dart';
import 'commands/uninstall.dart';

class Den extends Object with
    BumpCommand,
    FetchCommand,
    InstallCommand,
    PullCommand,
    SpecCommand,
    UninstallCommand {

  @Command(
      allowTrailingOptions: true,
      help: 'A pubspec authoring tool',
      plugins: const [const Completion()])
  Den();
}
