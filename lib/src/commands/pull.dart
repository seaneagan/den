
library den.src.commands.pull;

import '../api/den_api.dart';
import 'package:unscripted/unscripted.dart';

import '../theme.dart';
import '../util.dart';

class PullCommand {
  @SubCommand(help: 'Update any outdated dependencies')
  pull(
      @Rest(
          valueHelp: 'package name',
          allowed: getHostedDependencyNames,
          help: 'Name of dependency to pull.  If omitted, then pulls all dependencies in the pubspec.')
      Iterable<String> names,
      {
      @Flag(negatable: true)
      bool caret
    }) => Pubspec.load().then((pubspec) {
    caret = caret == null ? pubspec.caretAllowed : caret;
    onInvalid(Iterable<String> invalid) {
      print('Can only pull existing hosted dependencies, which do not include: $invalid');
    }
    fetchOrPull(pubspec, names, (pubspec, name) => pubspec.pull(name, caret: caret), onInvalid).then((Map<String, VersionStatus> outdated) {
      if (outdated.isEmpty) {
        print('\nDependencies were already up to date.');
        return;
      }

      var lines = [];
      outdated.forEach((name, status) {
        lines.add('${theme.dependency(name)}${theme.info(' (old: ')}${theme.version(status.constraint.toString())}${theme.info(', new: ')}${theme.version(pubspec.versionConstraints[name].toString())}${theme.info(')')}');
      });

      pubspec.save();

      print(block('Updated dependencies', lines));
    });
  });
}
