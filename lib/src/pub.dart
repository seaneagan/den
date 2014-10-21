
library den.pub;

import 'dart:async';
import 'dart:io';

import 'package:contrast/contrast.dart';
import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'yaml_edit.dart';

class Pubspec {
  
  String get contents => _contents;
  set contents(String contents) {
    _contents = contents;
    _yamlMap = loadYamlNode(_contents, sourceUrl: _yamlMap.span.sourceUrl);
  }
  String _contents;
  YamlMap get yamlMap => _yamlMap;
  YamlMap _yamlMap;
  String get path => _path;
  final String _path;
  String get name => _yamlMap['name'];
  String get author => _yamlMap['author'];
  String get version => _yamlMap['version'];
  String get homepage => _yamlMap['homepage'];
  String get documentation => _yamlMap['documentation'];
  String get description => _yamlMap['description'];
  Map<String, dynamic> get dependencies => 
      _yamlMap.containsKey('dependencies') ? 
          _yamlMap['dependencies'] : const {};
  Map<String, dynamic> get devDependencies => 
      _yamlMap.containsKey('dev_dependencies') ? 
          _yamlMap['dev_dependencies'] : const {};
  Map<String, dynamic> get dependencyOverrides => 
      _yamlMap.containsKey('dependency_overrides') ? 
          _yamlMap['dependency_overrides'] : const {};
  List<String> get immediateDependencyNames => []
      ..addAll(dependencies.keys)
      ..addAll(devDependencies.keys);
  
  Map<String, VersionConstraint> get versionConstraints {
    if (_versionConstraints == null) {
      _versionConstraints = {};
      addGroup(Map<String, dynamic> group) {
        group.forEach((name, description) {
          VersionConstraint constraint;
          if(description is String) constraint = parseVersionConstraint(description);
          if(description is Map && description.length == 1 && description.containsKey('hosted')) {
            constraint = description['hosted']['version'];
          }
          if(constraint != null) _versionConstraints[name] = constraint;
        });
      }
      addGroup(dependencies);
      addGroup(devDependencies);
      addGroup(dependencyOverrides);
    }
    return _versionConstraints;
  }
  Map<String, VersionConstraint> _versionConstraints;

  Pubspec(
      this._path,
      this._contents, 
      this._yamlMap);
  
  static Pubspec load([String path]) {
    var packageRoot = _getPackageRoot(path == null ? p.current : path);
    var pubspecPath = p.join(packageRoot, _PUBSPEC);
    var contents = new File(pubspecPath).readAsStringSync();
    var yaml = loadYamlNode(contents, sourceUrl: pubspecPath);
    return new Pubspec(
        pubspecPath,
        contents,
        yaml);
  }
  
  undepend(String packageName) {
    removeFromGroup(bool dev) {
      var old;
      var depGroup = dev ? devDependencies : dependencies;
      if(depGroup is Map) {
        if(depGroup.containsKey(packageName)) {
          // Remove parent node if it will be empty after this operation.
          var isLast = depGroup.length == 1;
          var deleteFrom = isLast ? yamlMap : depGroup;
          var deleteKey = isLast ? (dev ? 'dev_dependencies' : 'dependencies') : packageName;
          old = depGroup[packageName];
          contents = deleteMapKey(_contents, deleteFrom, deleteKey);
        }
      }
      return old;
    }
    var old = removeFromGroup(false);
    if(old == null) old = removeFromGroup(true);
    return old;
  }
  
  addDependency(PackageDep dep, {bool dev: false}) {
    
    var otherDepGroup = dev ? dependencies : devDependencies;
    var old;
    if(otherDepGroup.containsKey(dep.name)) {
      old = undepend(dep.name);
    }

    // TODO: Log whether we're replacing an existing dependency or adding a new one, and all dependency metadata.
    String depSourceDescription;
    if(dep.source == 'hosted') {
      depSourceDescription = "'${dep.constraint}'";
      if(dep.description is Map) {
        // TODO: Implement for hosted dep map descriptions as well.
        throw new UnimplementedError('Description maps are not yet implemented for adding deps from source "${dep.source}".');
      }
    } else {
      String description;
      if(dep.description is Map) {
        var descMap = dep.description;
        if(dep.source == 'git') {
          description = ['url', 'ref'].where(descMap.containsKey).map((descKey) => '\n  $descKey: ${descMap[descKey]}').join();
        } else {
          throw new ArgumentError('Description maps are not valid for deps with source "${dep.source}".');
        }
      } else {
        description = ' ${dep.description}';
      }
      depSourceDescription = "${dep.source}:$description";
    }
    
    var location = dev ? 'dev_dependencies' : 'dependencies';
    var containerValue = _yamlMap[location];
    if(containerValue == null) {
      contents = setMapKey(_contents, _yamlMap, location, "${dep.name}: $depSourceDescription", true);
    } else {
      var ownLine = dep.description != null;
      contents = setMapKey(_contents, _yamlMap[location], dep.name, depSourceDescription, ownLine);
    }
    return old;
  }
  
  void save() {
    new File(path).writeAsStringSync(contents);
  }
  
  /// The [basename] of a pubpsec file.
  static final String _PUBSPEC = "pubspec.yaml";
  
  /// Calculate the root of the package containing path.
  static String _getPackageRoot(String subPath) {
    subPath = p.absolute(subPath);
    var segments = p.split(subPath);
    var testPath = subPath;

    // Walk up directory hierarchy until we find a pubspec.
    for(int i = 0; i < segments.length; i++) {
      var testDir = new Directory(testPath);
      if(testDir.existsSync() && testDir.listSync().any((fse) =>
          p.basename(fse.path) == _PUBSPEC)) {
        return testPath;
      }
      testPath = p.dirname(testPath);
    }

    throw new ArgumentError(
        "No package root (containing pubspec.yaml) "
        "found in hierarchy of path: $subPath");
  }
}

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

class VersionStatus {
  
  final VersionConstraint constraint;
  final bool dev;
  final List<Version> _versions;
  Version get primary => Version.primary(_versions);
  Version get latest => maxOf(_versions);
  bool get isOutdated => !constraint.allows(primary);
  
  VersionConstraint getUpdatedConstraint({bool unstable: false, bool keepMin: false}) {
    var updateTo = unstable ? latest : primary;
    if(constraint.allows(updateTo)) return constraint;
    var min = keepMin ? 
        (constraint is VersionRange ? 
            (constraint as VersionRange).min :
            constraint) :
        updateTo;
    var includeMin = constraint is VersionRange ?
        (constraint as VersionRange).includeMin :
        true;
    return new VersionRange(min: min, max: getNextBreakingVersion(updateTo), includeMin: includeMin);
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

Version getNextBreakingVersion(Version version) => 
    version.major >= 1 ? version.nextMajor : version.nextMinor;

VersionRange getCompatibleVersionRange(Version version) => 
    new VersionRange(min: version, max: getNextBreakingVersion(version), includeMin: true);

Future<Version> fetchPrimaryVersion(String packageName) {
  return fetchPackage('http://pub.dartlang.org/packages/$packageName.json').then((Package package) {
    return Version.primary(package.versions);
  });
}

VersionConstraint parseVersionConstraint(String constraint) {
  if(constraint == null) return null;
  return new VersionConstraint.parse(constraint);
}
