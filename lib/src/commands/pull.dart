
library den.src.commands.pull;

import 'package:unscripted/unscripted.dart';

import '../pub.dart';
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
    }) {
    var pubspec = Pubspec.load();
    caret = defaultCaret(caret, pubspec);
    onInvalid(Iterable<String> invalid) {
      print('Can only pull existing hosted dependencies, which do not include: $invalid');
    }
    fetch(pubspec, names, onInvalid).then((Map<String, VersionStatus> outdated) {
      if (outdated.isEmpty) {
        print('\nDependencies were already up to date.');
        return;
      }

      var lines = [];
      outdated.forEach((name, status) {
        var updatedConstraint = status.getUpdatedConstraint(caret: caret);
        pubspec.addDependency(new PackageDep(name, 'hosted', updatedConstraint, null), dev: status.dev);
        lines.add('${theme.dependency(name)}${theme.info(' (old: ')}${theme.version(status.constraint.toString())}${theme.info(', new: ')}${theme.version(updatedConstraint.toString())}${theme.info(')')}');
      });

      pubspec.save();

      print(block('Updated dependencies', lines));
    });
  }
}

List<String> _getImmediateDependencyNames() => Pubspec.load().immediateDependencyNames;
