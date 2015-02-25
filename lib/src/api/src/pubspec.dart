
library den_api.src.pubspec;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'bump.dart';
import 'git.dart';
import 'github_repo_description.dart';
import 'package_dep.dart';
import 'release_type.dart';
import 'util.dart';
import 'version_status.dart';
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
  set name(String v) {
    contents = setMapKey(_contents, _yamlMap, 'name', v, false);
  }

  String get author => _yamlMap['author'];
  set author(String v) {
    _setValue('author', v);
  }

  Version get version => new Version.parse(_yamlMap['version']);
  set version(Version v) {
    contents = setMapKey(_contents, _yamlMap, 'version', v.toString(), false);
  }

  String get homepage => _yamlMap['homepage'];
  set homepage(String v) => _setValue('homepage', v);

  String get documentation => _yamlMap['documentation'];
  set documentation(String v) => _setValue('documentation', v);

  String get description => _yamlMap['description'];
  set description(String v) {
    _setValue('description', v);
  }

  void _setValue(String key, String value) {
    if (value != null && value != '') {
      contents = setMapKey(_contents, _yamlMap, key, value, false);
    } else {
      contents = deleteMapKey(_contents, _yamlMap, key);
    }
  }

  VersionConstraint get sdkConstraint {
    var env = _yamlMap['environment'];
    if (env == null) return VersionConstraint.any;
    var sdkString = env['sdk'];
    if (sdkString == null) return VersionConstraint.any;
    return new VersionConstraint.parse(sdkString);
  }
  set sdkConstraint(VersionConstraint constraint) {
    var env = _yamlMap['environment'];
    if (constraint == null) {
      if (env is Map) {
        if (env.containsKey('sdk')) {
          if (env.keys.length == 1) {
            contents = deleteMapKey(_contents, _yamlMap, 'environment');
          } else {
            contents = deleteMapKey(_contents, env, 'sdk');
          }
        }
      }
      return;
    }
    if (constraint.toString().contains('^')) throw 'Sdk constraints cannot use ^';
    if(env == null) {
      contents = setMapKey(_contents, _yamlMap, 'environment', "sdk: '$constraint'", true);
    } else {
      contents = setMapKey(_contents, env, 'sdk', "'$constraint'", false);
    }
  }

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

    // TODO: Consider caching this, but then must be sure
    //       to invalidate that cache on dependency changes.
    var _versionConstraints = {};
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
    return _versionConstraints;
  }

  Pubspec(
      this._path,
      this._contents,
      this._yamlMap);

  static Future<Pubspec> init() => new Future(() {
    var packageRoot = p.current;
    var pubspecPath = p.join(packageRoot, basename);
    var exp = new RegExp(r"(-dart|\.dart)$");
    var name = p.basename(packageRoot).replaceAll(exp, "");
    name = new RegExp(r'[_a-zA-Z][_a-zA-Z0-9]*').hasMatch(name) ? name : '';
    var contents = "name: $name";
    var yaml = loadYamlNode(contents, sourceUrl: pubspecPath);
    var pubspec = new Pubspec(pubspecPath, contents, yaml);
    return shouldDoGit(packageRoot).then((shouldGit) {
      dummyAuthor() {
        pubspec.author = '# name <email>';
      }
      dummyHomepage() {
        pubspec.homepage = '# https://github.com/user/repo';
      }
      if (shouldGit) {
        return gitUserName().then((name) => gitUserEmail().then((email) {
          pubspec.author = "$name <$email>";
        })).catchError((_) => dummyAuthor()).then((_) {
          return gitRepoHomepage().then((url) {
            if (url == null) dummyHomepage();
            pubspec.homepage = url;
          }).catchError((_) {
            dummyHomepage();
          }).then((_) {
            return githubRepoDescription().then((description) {
              if (description != '') pubspec.description = description;
            }).catchError((e) {});
          });
        });
      } else {
        dummyAuthor();
        dummyHomepage();
      }
    }).then((_) {
      pubspec.version = new Version.parse('0.1.0');
      var prevMajor = new Version(sdkVersion.major, 0, 0);
      pubspec.sdkConstraint = new VersionRange(
          min: prevMajor,
          includeMin: true,
          max: sdkVersion.nextMajor,
          includeMax: false);
      return pubspec;
    });
  });

  static Future<Pubspec> load([String path]) {
    var packageRoot = _getPackageRoot(path == null ? p.current : path);
    var pubspecPath = p.join(packageRoot, basename);
    return new File(pubspecPath).readAsString().then((contents) {
      var yaml = loadYamlNode(contents, sourceUrl: pubspecPath);
      return new Pubspec(
          pubspecPath,
          contents,
          yaml);
    });
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

    bool addingCaret = false;

    // TODO: Log whether we're replacing an existing dependency or adding a new one, and all dependency metadata.
    String depSourceDescription;
    if(dep.source == 'hosted') {
      depSourceDescription = "'${dep.constraint}'";
      if (dep.constraint.toString().startsWith('^')) addingCaret = true;
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

    if (addingCaret) {
      _ensureSdkConstraintAllowsCaret();
    }

    var location = dev ? 'dev_dependencies' : 'dependencies';
    var containerValue = _yamlMap[location];
    var ownLine = dep.description != null;
    if(containerValue == null) {
      var lineSeparator = ownLine ? '\n  ' : ' ';
      contents = setMapKey(_contents, _yamlMap, location, "${dep.name}:$lineSeparator$depSourceDescription", true);
    } else {
      contents = setMapKey(_contents, _yamlMap[location], dep.name, depSourceDescription, ownLine);
    }
    return old;
  }

  void bump(ReleaseType releaseType, {pre: false}) {
    version = bumpVersion(version, releaseType, pre: pre);
  }

  Future<VersionStatus> fetch(String packageName) {
    var constraint = versionConstraints[packageName];
    var dev = devDependencies.containsKey(packageName);
    return fetchPackage('http://pub.dartlang.org/packages/$packageName.json').then((Package package) {
      return new VersionStatus(package.versions, constraint, dev);
    });
  }

  Future<VersionStatus> pull(String packageName, {bool caret}) {
    return fetch(packageName).then((status) {
      var updatedConstraint = status.getUpdatedConstraint(caret: caret == null ? caretAllowed : caret);
      addDependency(new PackageDep(packageName, 'hosted', updatedConstraint, null), dev: status.dev);
      return status;
    });
  }

  /// Adds/updates [sdkConstraint] as necessary to support carets,
  /// and returns whether or not it was necessary.
  bool _ensureSdkConstraintAllowsCaret() {
    /// Whether the SDK constraint guarantees that `^` version constraints are
    /// safe.
    bool caretAllowed = sdkConstraint.intersect(_preCaretPubVersions).isEmpty;
    if (caretAllowed) return false;

    var newSdkConstraint = sdkConstraint.intersect(_postCaretPubVersions);
    if (newSdkConstraint.isEmpty) newSdkConstraint = _postCaretPubVersions;
    sdkConstraint = newSdkConstraint;
    return true;
  }

  /// Whether [sdkConstraint] guarantees that `^` version constraints are
  /// safe.
  bool get caretAllowed => sdkConstraint.intersect(_preCaretPubVersions).isEmpty;

  /// The range of all pub versions that don't support `^` version constraints.
  final _preCaretPubVersions = new VersionConstraint.parse("<1.8.0-dev.3.0");

  /// The range of all pub versions that do support `^` version constraints.
  final _postCaretPubVersions = new VersionConstraint.parse("^1.8.0");

  void save() {
    new File(path).writeAsStringSync(contents);
  }

  /// The [basename] of a pubpsec file.
  static final String basename = 'pubspec.yaml';

  /// Calculate the root of the package containing path.
  static String _getPackageRoot(String subPath) {
    subPath = p.absolute(subPath);
    var segments = p.split(subPath);
    var testPath = subPath;

    // Walk up directory hierarchy until we find a pubspec.
    for(int i = 0; i < segments.length; i++) {
      var testDir = new Directory(testPath);
      if(testDir.existsSync() && testDir.listSync().any((fse) =>
          p.basename(fse.path) == basename)) {
        return testPath;
      }
      testPath = p.dirname(testPath);
    }

    throw new ArgumentError(
        "No package root (containing pubspec.yaml) "
        "found in hierarchy of path: $subPath");
  }
}
