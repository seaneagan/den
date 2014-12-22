
library den.util;

import 'dart:async';

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
