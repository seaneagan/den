
library den.src.util;

import 'dart:async';

import 'package:pub_semver/pub_semver.dart';
import 'package:quiver/async.dart';

import 'package:den_api/den_api.dart';

bool nullOrEmpty(String str) => str == null || str.isEmpty;

Future<Map<String, VersionStatus>> fetchOrPull(Pubspec pubspec, Iterable<String> names, Future<VersionStatus> action(Pubspec pubspec, String name), onInvalid(Iterable<String> invalid)) => new Future(() {
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
    return action(pubspec, name).then((VersionStatus status) {
      if (status.isOutdated) outdated[name] = status;
      return outdated;
    });
  });
});

VersionConstraint removeCaretFromVersionConstraint(VersionRange vr) =>
    new VersionRange(min: vr.min, includeMin: vr.includeMin, max: vr.max,
        includeMax: vr.includeMax);

Future<List<String>> getHostedDependencyNames() =>
    Pubspec.load().then((pubspec) => pubspec.versionConstraints.keys.toList());

Future<List<String>> getImmediateDependencyNames() =>
    Pubspec.load().then((pubspec) => pubspec.immediateDependencyNames);

String enumName(enumValue) {
  var s = enumValue.toString();
  return s.substring(s.indexOf('.') + 1);
}

String upperCaseFirst(String s) => s[0].toUpperCase() + s.substring(1);
