
library den.src.commands.bump;

import 'package:pub_semver/pub_semver.dart';
import 'package:unscripted/unscripted.dart';

import '../bump.dart';
import '../pub.dart';
import '../theme.dart';
import '../util.dart';

class BumpCommand {
  @SubCommand(help: 'Bump the version')
  bump({
      @Option(help: "Pre-release identifier e.g. 'beta'.  Use --pre instead if you don't want to specify an id")
      String preId,
      @Flag(help: 'Bump to a pre-release.  Use --pre-id instead of you want to specify an id')
      bool major: false,
      bool minor: false,
      bool patch: false,
      bool pre: false,
      bool build: false,
      bool breaking: false
  }) {

    var pubspec = Pubspec.load();
    var version = pubspec.version;

    var partFlags = {
      'major': major,
      'minor': minor,
      'patch': patch,
      'build': build,
      'breaking': breaking
    };
    var truePartFlags = partFlags.keys.where((name) => partFlags[name]);

    VersionPart part;
    switch (truePartFlags.length) {
      case 0: if (pre) part = VersionPart.preRelease; break;
      case 1:
        if (breaking) {
          part = version.major < 1 ? VersionPart.minor : VersionPart.major;
          break;
        }

        var partName = truePartFlags.single;
        part = VersionPart.values.firstWhere((part) => enumName(part) == partName);
        break;
      default:
        var flagList = truePartFlags.map((name) => '--$name').join(' ');
        throw 'Cannot bump multiple version parts ($flagList).';
    }

    Version newVersion = bumpVersion(version, part: part, pre: preId == null ? pre : preId);

    pubspec.version = newVersion;
    pubspec.save();

    print('${theme.info('Bumped version from ')}${theme.version(version.toString())}${theme.info(' to ')}${theme.version(newVersion.toString())}');
  }
}
