
library den_api.src.util;

import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

String indent(String str, int width) =>
    str.splitMapJoin('\n', onNonMatch: (String line) => ' ' * width + line);

Version get sdkVersion {
  var sdkString = new RegExp(r'^[^ ]+').stringMatch(Platform.version);
  return new Version.parse(sdkString);
}

List createPreRelease(pre) => false == pre ? null : pre is String
    ? preReleaseWithId(pre, 0) : [0];

Version withPreRelease(Version version, List preRelease) =>
    new Version(version.major, version.minor, version.patch,
        pre: preRelease == null ? null : preRelease.join('.'));

List preReleaseWithId(String id, int index) => [id, index];
