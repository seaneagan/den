
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:which/which.dart';

Future<ProcessResult> runGit(args, {String workingDirectory}) => Process.run('git', args, workingDirectory: workingDirectory);
ProcessResult runGitSync(args, {String workingDirectory}) => Process.runSync('git', args, workingDirectory: workingDirectory);

const String _versionTemplate = 'v{v}';

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

Future<bool> shouldDoGit(String packagePath) => new Future(() {
  return FileStat.stat(p.join(packagePath, '.git')).then((stat) {
    var isDir = FileSystemEntityType.DIRECTORY == stat.type;

    if (!isDir) return false;

    return checkHasGit().then((hasGit) {
      if (!hasGit) {
            print('''
This is a Git checkout, but the git command was not found.
Could not create a Git tag for this release!''');
        return false;
      }

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
  });
});

Future<bool> checkHasGit() =>
    which('git', orElse: () => null).then((git) => git != null);

bool checkHasGitSync() => whichSync('git', orElse: () => null) != null;

Future<List<String>> gitStatus() => runGit(['status', '--porcelain']).then((processResult) {
  var lines = processResult.stdout.trim().split("\n")
      .where((String line) => line.trim().isNotEmpty && !line.startsWith('?? '))
      .map((line) => line.trim());
  return lines;
});

String gitConfigUserNameSync() => runGitSync(['config', 'user.name']).stdout.trim();
String gitConfigUserEmailSync() => runGitSync(['config', 'user.email']).stdout.trim();