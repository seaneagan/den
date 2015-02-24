
library den_api.src.git;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:which/which.dart';

Future<ProcessResult> runGit(args, {String workingDirectory}) => Process.run('git', args, workingDirectory: workingDirectory);

Future<bool> shouldDoGit(String gitDir) => new Future(() {
  return FileStat.stat(p.join(gitDir, '.git')).then((stat) {
    var isDir = FileSystemEntityType.DIRECTORY == stat.type;

    if (!isDir) return false;

    return checkHasGit();
  });
});

Future<bool> checkHasGit() =>
    which('git', orElse: () => null).then((git) => git != null);

Future<String> gitUserName() => gitConfig('user.name');
Future<String> gitUserEmail() => gitConfig('user.email');
Future<String> gitRepoHomepage() => gitConfig('remote.origin.url').then(repoUrlToHomepage);

String repoUrlToHomepage(String repo) {
  var uri = Uri.parse(repo);
  p.Context context = p.Style.url.context;
  // Remove '.git' suffix.
  // TODO: This works for github and bitbucket repos, and if there are other repo hosts
  //       that use a different convention, this should still get us close.
  var newPath = context.join(context.dirname(uri.path), context.basenameWithoutExtension(uri.path));
  return uri.replace(scheme: 'https', path: newPath).toString();
}

Future<String> gitConfig(String property) =>
    runGit(['config', property]).then((processResult) => processResult.stdout.trim());
