
library den_api.src.package_dep;

import 'package:pub_semver/pub_semver.dart';

/// This is the private base class of [PackageRef], [PackageID], and
/// [PackageDep].
///
/// It contains functionality and state that those classes share but is private
/// so that from outside of this library, there is no type relationship between
/// those three types.
class _PackageName {
  _PackageName(this.name, this.source, this.description);

  /// The name of the package being identified.
  final String name;

  /// The name of the [Source] used to look up this package given its
  /// [description].
  ///
  /// If this is a root package, this will be `null`.
  final String source;

  /// The metadata used by the package's [source] to identify and locate it.
  ///
  /// It contains whatever [Source]-specific data it needs to be able to get
  /// the package. For example, the description of a git sourced package might
  /// by the URL "git://github.com/dart/uilib.git".
  final description;

  /// Whether this package is the root package.
  bool get isRoot => source == null;

  String toString() {
    if (isRoot) return "$name (root)";
    return "$name from $source";
  }

  /// Returns a [PackageDep] for this package with the given version constraint.
  PackageDep withConstraint(VersionConstraint constraint) =>
    new PackageDep(name, source, constraint, description);
}

/// A reference to a constrained range of versions of one package.
class PackageDep extends _PackageName {
  /// The allowed package versions.
  final VersionConstraint constraint;

  PackageDep(String name, String source, this.constraint, description)
      : super(name, source, description);

  String toString() {
    if (isRoot) return "$name $constraint (root)";
    return "$name $constraint from $source ($description)";
  }

  int get hashCode => name.hashCode ^ source.hashCode;

  bool operator ==(other) {
    // TODO(rnystrom): We're assuming here that we don't need to delve into the
    // description.
    return other is PackageDep &&
           other.name == name &&
           other.source == source &&
           other.constraint == constraint;
  }
}

