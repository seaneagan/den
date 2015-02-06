
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:which/which.dart';

Future<ProcessResult> runGit(args, {String workingDirectory}) => Process.run('git', args, workingDirectory: workingDirectory);

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

Future<List<String>> gitStatus() => runGit(['status', '--porcelain']).then((processResult) {
  var lines = processResult.stdout.trim().split("\n")
      .where((String line) => line.trim().isNotEmpty && !line.startsWith('?? '))
      .map((line) => line.trim());
  return lines;
});

Future<String> gitUserName() => gitConfig('user.name');
Future<String> gitUserEmail() => gitConfig('user.email');
Future<String> githubUrl() => gitConfig('remote.origin.url').then(repoUrlToHomepage);

String repoUrlToHomepage(String repo) {
  var uri = Uri.parse(repo);
  // TODO: Support other git hosts such as bitbucket.
  if (uri.origin == 'github.com') {
    p.Context context = p.Style.url.context;
    var newPath = context.join(context.dirname(uri.path), context.basenameWithoutExtension(uri.path));
    return uri.replace(scheme: 'https', path: newPath).toString();
  }
  return null;
}

Future<String> gitConfig(String property) =>
    runGit(['config', property]).then((processResult) => processResult.stdout.trim());