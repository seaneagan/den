
library den.src.git;

import 'dart:async';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

import 'api/src/git.dart';

const String _versionTemplate = 'v{v}';

Future<bool> shouldDoTaggedVersionCommit(String packagePath) {
  return shouldDoGit(packagePath).then((shouldGit) {
    if (!shouldGit) return false;

    return gitStatus().then((status) {
      if (status.isNotEmpty) {
        print('''
Git working directory not clean.
${status.join("\n")}''');
        exit(1);
      }
      return true;
    });
  });
}

Future taggedVersionCommit(
    Version version,
    String packagePath,
    {String messageTemplate: _versionTemplate}) => new Future(() {

  String replaceVersion(String s) => s.replaceFirst('{v}', version.toString());

  var tag = replaceVersion(_versionTemplate);
  var message = replaceVersion(messageTemplate);

  return Future.forEach([
        ['add', 'pubspec.yaml'],
        ['commit', '-m', message],
        ['tag', tag, '-am', message]
      ],
      (args) => runGit(args, workingDirectory: packagePath));
});

Future<List<String>> gitStatus() => runGit(['status', '--porcelain']).then((processResult) {
  var lines = processResult.stdout.trim().split("\n")
      .where((String line) => line.trim().isNotEmpty && !line.startsWith('?? '))
      .map((line) => line.trim());
  return lines;
});

