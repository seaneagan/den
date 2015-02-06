
library den.util;

import 'dart:async';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:quiver/async.dart';

import 'pub.dart';

bool nullOrEmpty(String str) => str == null || str.isEmpty;

String indent(String str, int indent) {
  return str.splitMapJoin('\n', onNonMatch: (String line) => ' ' * indent + line);
}

Future<Map<String, VersionStatus>> fetch(Pubspec pubspec, Iterable<String> names, onInvalid(Iterable<String> invalid)) => new Future(() {
  if(names.isEmpty) {
    names = pubspec.versionConstraints.keys;
    if(names.isEmpty) {
      return {};
    }
  } else {
    var bogusDependencyNames = names.where((packageName) => !pubspec.versionConstraints.containsKey(packageName)).toList();
    if(bogusDependencyNames.isNotEmpty) {
      onInvalid(bogusDependencyNames);
      return {};
    }
  }

  return reduceAsync(names, {}, (outdated, name) {
    return VersionStatus.fetch(pubspec, name).then((VersionStatus status) {
      if(status.isOutdated) outdated[name] = status;
      return outdated;
    });
  });
});

bool defaultCaret(bool caret, Pubspec pubspec) {
  if (caret != null) return caret;
  return pubspec.caretAllowed;
}

List<String> getHostedDependencyNames() => Pubspec.load().versionConstraints.keys.toList();

String enumName(enumValue) {
  var s = enumValue.toString();
  return s.substring(s.indexOf('.') + 1);
}

Version get sdkVersion {
  var sdkString = new RegExp(r'^[^ ]+').stringMatch(Platform.version);
  return new Version.parse(sdkString);
}
