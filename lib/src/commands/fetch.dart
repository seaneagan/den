
library den.src.commands.fetch;

import 'package:unscripted/unscripted.dart';

import '../pub.dart';
import '../theme.dart';
import '../util.dart' as util;

class FetchCommand {
  @SubCommand(help: 'Show any outdated dependencies')
  fetch(
      @Rest(
          valueHelp: 'package name',
          allowed: util.getHostedDependencyNames,
          help: 'Name of dependency to fetch.  If omitted, then fetches all dependencies in the pubspec.')
      Iterable<String> names) => Pubspec.load().then((pubspec) {
    onInvalid(Iterable<String> invalid) {
      print('Can only fetch existing hosted dependencies, which do not include: $invalid');
    }
    util.fetch(pubspec, names, onInvalid).then((Map<String, VersionStatus> outdated) {
      if (outdated.isEmpty) {
        print('\nDependencies are up to date.');
        return;
      }

      var lines = [];
      outdated.forEach((name, status) {
        lines.add('${theme.dependency(name)}${theme.info(' (constraint: ')}${theme.version(status.constraint.toString())}${theme.info(', latest: ')}${theme.version(status.primary.toString())}${theme.info(')')}');
      });
      print(block('Outdated dependencies', lines));
    });
  });
}
