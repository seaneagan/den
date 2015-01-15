
library den.src.bump;

import 'package:pub_semver/pub_semver.dart';

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

Version withPreRelease(Version version, List preRelease) =>
    new Version(version.major, version.minor, version.patch,
        pre: preRelease == null ? null : preRelease.join('.'));

List createPreRelease(pre) => false == pre ? null : pre is String ? _preReleaseWithId(pre, 0) : [0];

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
          return _preReleaseWithId(newId, 0);
        }
        break;
      }
      continue two;
    two: case 2:
      if (preRelease.first is String && preRelease.last is int) {
        var newId = pre is! String ? preRelease.first : pre;
        if (newId == preRelease.first) {
          return _preReleaseWithId(newId, preRelease.last + 1);
        }
        break;
      }
      continue def;
    def: default:
      throw 'Cannot increment unrecognized pre-release "${preRelease.join('.')}".';
  }
  return createPreRelease(pre);
}

_preReleaseWithId(String id, int index) => [id, index];

withBuild(Version v, List build) =>
    new Version(v.major, v.minor, v.patch,
        pre: v.preRelease.isEmpty ? null : v.preRelease.join('.'),
        build: build.isEmpty ? null : build.join('.'));

List updateBuild(List build) {
  if (build.isEmpty) return [1];
  if (build.length == 1) return [build.single + 1];
  throw 'Cannot increment unrecognized build "${build.join('.')}';
}

class ReleaseType {
  final String _name;

  const ReleaseType._(this._name);

  static const ReleaseType major = const ReleaseType._('major');
  static const ReleaseType minor = const ReleaseType._('minor');
  static const ReleaseType patch = const ReleaseType._('patch');
  static const ReleaseType breaking = const ReleaseType._('breaking');
  static const ReleaseType release = const ReleaseType._('release');
  static const ReleaseType build = const ReleaseType._('build');

  static List<ReleaseType> values = [major, minor, patch, breaking, release, build];

  String toString() => 'ReleaseType.$_name';
}
