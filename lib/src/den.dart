
library den;

import 'package:unscripted/unscripted.dart';

import 'commands/bump.dart';
import 'commands/fetch.dart';
import 'commands/init.dart';
import 'commands/install.dart';
import 'commands/pull.dart';
import 'commands/uninstall.dart';

class Den extends Object with BumpCommand, FetchCommand, InitCommand, InstallCommand, PullCommand , UninstallCommand {

  @Command(
      allowTrailingOptions: true,
      help: 'A pubspec authoring tool',
      plugins: const [const Completion()])
  Den();

}
