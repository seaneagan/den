
library den_api.src.github_repo_description;

import 'dart:async';

import 'package:github/server.dart';
import 'package:path/path.dart' as p;

import 'git.dart';

Future<String> githubRepoDescription() => new Future(() {
  return gitConfig('remote.origin.url').then((remoteOriginUrl) {
    var uri = Uri.parse(remoteOriginUrl);
    if (uri.host != 'github.com') return '';
    var pathSegments = uri.pathSegments;
    if (pathSegments.length != 2) return '';
    var slug = new RepositorySlug(pathSegments.first, p.basenameWithoutExtension(pathSegments.last));
    var github = createGitHubClient();
    return github.repositories.getRepository(slug).then((Repository repo) {
      return repo.description;
    });
  });
});
