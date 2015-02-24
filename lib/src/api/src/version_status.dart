
library den_api.src.version_status;

import 'dart:async';

import 'package:contrast/contrast.dart';
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';

import 'pubspec.dart';

class VersionStatus {

  final VersionConstraint constraint;
  final bool dev;
  final List<Version> _versions;
  Version get primary => Version.primary(_versions);
  Version get latest => maxOf(_versions);
  bool get isOutdated => !constraint.allows(primary);

  VersionConstraint getUpdatedConstraint({bool unstable: false, bool keepMin: false, bool caret}) {
    var updateTo = unstable ? latest : primary;
    if(constraint.allows(updateTo)) return constraint;

    var currentMin = (constraint is VersionRange ?
        (constraint as VersionRange).min :
        constraint);

    var min = keepMin ? currentMin : updateTo;

    var includeMin = !keepMin || constraint is! VersionRange ||
        (constraint as VersionRange).includeMin;

    // Cannot use caret constraint when `keepMin == true` and either of:
    //
    // * The updated version is not compatible with current min.
    // * The current min is not included.
    if (caret && ((keepMin && currentMin.nextBreaking < updateTo) || !includeMin)) {
      return new VersionConstraint.compatibleWith(min);
    }

    return new VersionRange(min: min, max: updateTo.nextBreaking, includeMin: includeMin);
  }

  VersionStatus._(this._versions, this.constraint, this.dev);

  static Future<VersionStatus> fetch(Pubspec pubspec, String packageName) {
    var constraint = pubspec.versionConstraints[packageName];
    var dev = pubspec.devDependencies.containsKey(packageName);
    return fetchPackage('http://pub.dartlang.org/packages/$packageName.json').then((Package package) {
      return new VersionStatus._(package.versions, constraint, dev);
    });
  }
}

