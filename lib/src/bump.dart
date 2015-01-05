
library den.src.bump;

import 'package:pub_semver/pub_semver.dart';

Version bumpVersion(Version version, {VersionPart part, pre: false}) {
  if (part == VersionPart.preRelease && !version.isPreRelease) {
    throw new ArgumentError('Cannot increment the pre-release of a non-pre-release version.');
  }

  if (VersionPart.build == part && false != pre) {
    throw new ArgumentError('Cannot create a pre-release of a pre-release or build version.');
  }

  Version newRelease;
  List newPreRelease = true == pre || pre is String ? createPreRelease(pre) : null;

  if (part == null) part = version.isPreRelease ? VersionPart.preRelease : VersionPart.patch;

  switch (part) {
    case VersionPart.major: newRelease = version.nextMajor; break;
    case VersionPart.minor: newRelease = version.nextMinor; break;
    case VersionPart.patch: newRelease = version.nextPatch; break;
    case VersionPart.preRelease:
      newRelease = version;
      newPreRelease = updatePreRelease(version.preRelease, pre);
      break;
    case VersionPart.build: return withBuild(version, updateBuild(version.build));
  }

  return withPreRelease(newRelease, newPreRelease);
}

Version withPreRelease(Version version, List preRelease) =>
    new Version(version.major, version.minor, version.patch, pre: preRelease == null ? null : preRelease.join('.'));

List createPreRelease(pre) => pre is! String ? [0] : _preReleaseWithId(pre, 0);

List updatePreRelease(List preRelease, pre) {
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
    new Version(v.major, v.minor, v.patch, pre: v.preRelease.isEmpty ? null : v.preRelease.join('.'),
    build: build.isEmpty ? null : build.join('.'));

List updateBuild(List build) {
  if (build.isEmpty) return [1];
  if (build.length == 1) return [build.single + 1];
  throw 'Cannot increment unrecognized build "${build.join('.')}';
}

class VersionPart {
  final String _name;

  const VersionPart._(this._name);

  static const VersionPart major = const VersionPart._('major');
  static const VersionPart minor = const VersionPart._('minor');
  static const VersionPart patch = const VersionPart._('patch');
  static const VersionPart preRelease = const VersionPart._('preRelease');
  static const VersionPart build = const VersionPart._('build');

  static List<VersionPart> values = [major, minor, patch, preRelease, build];

  String toString() => 'VersionPart.$_name';
}
