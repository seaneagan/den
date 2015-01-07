
library den.src.commands.bump;

import 'package:pub_semver/pub_semver.dart';
import 'package:unscripted/unscripted.dart';

import '../bump.dart';
import '../pub.dart';
import '../theme.dart';
import '../util.dart';

class BumpCommand {
  @ArgExample('patch', help: '1.2.3 -> 1.2.4')
  @ArgExample('minor --pre', help: '1.2.3 -> 1.3.0-0')
  @ArgExample('major --pre-id beta', help: '1.2.3 -> 2.0.0-beta.0')
  @ArgExample('breaking', help: '0.4.3 -> 0.5.0 or 1.2.3 -> 2.0.0')
  @ArgExample('release --pre', help: '1.0.0-dev.2 -> 1.0.0-dev.3')
  @ArgExample('release', help: '1.0.0-dev.2 -> 1.0.0')
  @SubCommand(help: '''Bump the pubspec version.''')
  bump(
      @Positional(help: '''
    The release type.

  [major]             Major release.
  [minor]             Minor release.
  [patch]             Patch release.
  [breaking]          Breaking release. ([minor] if <1.0.0, [major] otherwise)
  [release]           Remove or increment (when using --pre or --pre-id) a pre-release.
                      (Same as [patch], but fails if not currently on a pre-release.)
  [build]             Increment or initialize (to 1) the build number.
                      (Cannot be used with --pre or --pre-id)

  Use --pre or --pre-id to do a pre-release of this type.

  [major], [minor], and [patch], if currently on a pre-release of that 
  type, are equivalent to [release] (removes or increments (when using --pre 
  or --pre-id) the pre-release).
''', allowed: _getAllowedReleaseTypes, parser: _parseReleaseType)
      ReleaseType releaseType,
      {@Flag(help: """
Do a pre-release.  If currently on a pre-relase of form <n> or <id>.<n> 
where <n> is an integer and <id> is a String, increments <n>.  Fails if 
on a pre-release of an unrecognized form.  Sets pre-release to 0 if not 
currently on a pre-release.""")
       bool pre: false,
       @Option(valueHelp: "pre id", help: """
Do a pre-release with an id e.g. "beta".  If currently on a pre-relase 
of form <id>.<n> where <n> is an integer and <id> equals <pre id>, 
increments <n>.  Otherwise sets the pre-release to <pre id>.0.""")
       String preId
  }) {

    var pubspec = Pubspec.load();
    var version = pubspec.version;

    Version newVersion = bumpVersion(version, releaseType, pre: preId == null ? pre : preId);

    pubspec.version = newVersion;
    pubspec.save();

    print('${theme.info('Bumped version from ')}${theme.version(version.toString())}${theme.info(' to ')}${theme.version(newVersion.toString())}');
  }
}

_getAllowedReleaseTypes() => new Map.fromIterables(
    _allowedReleaseTypes.keys.map(enumName), _allowedReleaseTypes.values);

var _allowedReleaseTypes = {
  ReleaseType.major: '',
  ReleaseType.minor: '',
  ReleaseType.patch: '',
  ReleaseType.release: 'Releases a pre-release, or increments it when --pre is specified',
  ReleaseType.build: 'Adds or increments a build number',
};

ReleaseType _parseReleaseType(String releaseTypeText) =>
    ReleaseType.values.firstWhere((releaseType) =>
        enumName(releaseType) == releaseTypeText, orElse: () =>
            throw 'Invalid release type "$releaseTypeText"');
