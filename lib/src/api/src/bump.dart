
library den_api.src.bump;

import 'package:pub_semver/pub_semver.dart';

import 'release_type.dart';
import 'util.dart';

Version bumpVersion(Version version, ReleaseType releaseType, {pre: false}) {
  if (releaseType == ReleaseType.release && !version.isPreRelease) {
    throw new ArgumentError('Cannot ' +
        (pre ? 'increment the pre-release of' : 'release') +
        ' a non-pre-release version.');
  }

  if (ReleaseType.build == releaseType && false != pre) {
    throw new ArgumentError('Cannot pre-release of a build release.');
  }

  Version newRelease;
  List newPreRelease = false == pre ? null : createPreRelease(pre);

  switch (releaseType) {
    case ReleaseType.major: newRelease = version.nextMajor; break;
    case ReleaseType.minor: newRelease = version.nextMinor; break;
    case ReleaseType.patch: newRelease = version.nextPatch; break;
    case ReleaseType.breaking: newRelease = version.major == 0 ? version.nextMinor : version.nextMajor; break;
    case ReleaseType.release:
      newRelease = version;
      newPreRelease = updatePreRelease(version.preRelease, pre);
      break;
    case ReleaseType.build: return withBuild(version, updateBuild(version.build));
  }

  return withPreRelease(newRelease, newPreRelease);
}

List updatePreRelease(List preRelease, pre) {
  if (false == pre) return [];
  switch (preRelease.length) {
    case 0: break;
    case 1:
      if (preRelease.single is int && pre is! String) return [preRelease.single + 1];
      if (preRelease.single is String) {
        var oldId = preRelease.single;
        var newId = pre is! String ? oldId : pre;
        if (newId == oldId) {
          return preReleaseWithId(newId, 0);
        }
        break;
      }
      continue two;
    two: case 2:
      if (preRelease.first is String && preRelease.last is int) {
        var newId = pre is! String ? preRelease.first : pre;
        if (newId == preRelease.first) {
          return preReleaseWithId(newId, preRelease.last + 1);
        }
        break;
      }
      continue def;
    def: default:
      throw 'Cannot increment unrecognized pre-release "${preRelease.join('.')}".';
  }
  return createPreRelease(pre);
}

withBuild(Version v, List build) =>
    new Version(v.major, v.minor, v.patch,
        pre: v.preRelease.isEmpty ? null : v.preRelease.join('.'),
        build: build.isEmpty ? null : build.join('.'));

List updateBuild(List build) {
  if (build.isEmpty) return [1];
  if (build.length == 1) return [build.single + 1];
  throw 'Cannot increment unrecognized build "${build.join('.')}';
}
