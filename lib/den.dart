
library den;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:den/src/pub.dart';
import 'package:den/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:quiver/async.dart';
import 'package:unscripted/unscripted.dart';

import 'src/theme.dart';

/// Interact with pubspecs. 
class Den {
  
  @Command(
      allowTrailingOptions: true, 
      help: 'Interact with pubspecs', 
      plugins: const [const Completion()])
  Den();
  
  @SubCommand(help: 'Add or modify pubspec dependencies')
  /// Add or modify pubspec dependencies.
  install(
      @Rest(
          required: true, 
          valueHelp: 'endpoint', 
          allowed: packageList, 
          help: '''  Can be any of:

       <name>
       <name>#<version>

-sgit         <git url>
-sgit         <git url>#<git ref> (Derives <name> from <git url>)
-sgit  <name>=<git url>#<git ref>

-spath        <path>
-spath <name>=<path>

Where <name> should match the name: in the corresponding pubspec (avoids fetching the pubspec).

For more info on <name>, <git url>, <git ref>, and <path> at:
  https://www.dartlang.org/tools/pub/dependencies.html 
''')
      List<String> packages,
      {
      @Option(abbr: 's', allowed: const ['hosted', 'git', 'path'], help: 'The source of the package(s).')
      String source: 'hosted',
      @Flag(help: 'Whether this is a dev dependency.')
      bool dev: false
  }) {

    new Future(() {
      return Future.wait(packages
          .map(_SplitPackage.parse)
          .map((splitPackage) => splitPackage.getPackageDep(source)));
    }).then((deps) {
      // TODO: Validate existing pubspec, and fail if necessary.
      //       See dartbug.com/21169
      var pubspec = Pubspec.load();
      var movedDependencies = {};
      
      deps.forEach((PackageDep dep) {
        var oldDep = dev ? pubspec.addDevDependency(dep) : pubspec.addDependency(dep);
        if(oldDep != null) movedDependencies[dep.name] = oldDep;
      });
      
      pubspec.save();
      
      var otherDepGroupKey = dev ? 'dependencies' : 'dev_dependencies';
      var buffer = new StringBuffer();
      deps.forEach((PackageDep dep) {
        buffer
            ..write('  ${theme.dependency(dep.name)}: ')
            ..write(theme.version(dep.source == 'hosted' ?
                "'${dep.constraint}'" :
                dep.description));
        if(movedDependencies.containsKey(dep.name)) buffer.write(' (moved from "$otherDepGroupKey")');
        buffer.write('\n');
      });
      print(block('Installed these ${dev ? 'dev_' : ''}dependencies', buffer.toString()));
    });
    
  }
  
  @SubCommand(help: 'Remove pubspec dependencies')
  /// Remove pubspec dependencies.
  uninstall(
      @Rest(
          required: true, 
          valueHelp: 'package name', 
          allowed: _getImmediateDependencyNames, 
          help: 'Name of dependency to remove')
      List<String> names) {
    var pubspec = Pubspec.load();
    var removedDeps = names.fold({}, (removedDeps, name) {
      var removed = pubspec.undepend(name);
      if(removed != null) removedDeps[name] = removed;
      return removedDeps;
    });

    pubspec.save();
    
    if(removedDeps.isNotEmpty) {
      var buffer = new StringBuffer();
      removedDeps.forEach((name, old) {
        buffer.writeln('  ${theme.dependency(name)}${theme.info(': ')}${theme.version(JSON.encode(old))}');
      });
      print(block('Uninstalled these dependencies', buffer.toString()));
    } else {
      print('No (dev_)dependencies removed.');
    }

  }

  @SubCommand(help: 'Fetch and display the latest versions of some or all of your dependencies')
  /// Fetch and display the latest versions of some or all of your dependencies.
  fetch(
      @Rest(
          valueHelp: 'package name', 
          allowed: _getHostedDependencyNames, 
          help: 'Name of dependency to fetch')
      Iterable<String> names) {
    var pubspec = Pubspec.load();
    if(names.isEmpty) {
      names = pubspec.versionConstraints.keys;
      if(names.isEmpty) {
        print('There are no dependencies to fetch.');
        return;
      }
    } else {
      var bogusDependencyNames = names.where((packageName) => !pubspec.versionConstraints.containsKey(packageName)).toList();
      if(bogusDependencyNames.isNotEmpty) {
        print('Error: Can only fetch existing hosted dependencies, which do not include: $bogusDependencyNames');
        return;
      }
    }
    
    reduceAsync(names, {}, (outdated, name) {
      return VersionStatus.fetch(pubspec, name).then((VersionStatus status) {
        if(status.isOutdated) outdated[name] = status;
        return outdated;
      });
    }).then((Map<String, VersionStatus> outdated) {
      if (outdated.isEmpty) {
        print('\nDependencies up-to-date.');
        return;
      }
      
      var buffer = new StringBuffer();
      outdated.forEach((name, status) {
        buffer.writeln('${theme.dependency(name)}${theme.info(' (constraint: ')}${theme.version(status.constraint.toString())}${theme.info(', latest: ')}${theme.version(status.primary.toString())}${theme.info(')')}');
      });
      print(block('Outdated dependencies', buffer.toString()));
    });
  }
}

class _SplitPackage {
  final String input, explicitName, body, hash;
  
  static var packagePattern = new RegExp(r'^(([a-zA-Z0-9_]+)=)?([^#]+)(#([^#]+))?');

  static _SplitPackage parse(String package) {
    var match = packagePattern.firstMatch(package);
    if(match == null) throw new FormatException('Invalid package argument', package);
    return new _SplitPackage(match.input, match.group(2), match.group(3), match.group(5));
  }
  
  _SplitPackage(this.input, this.explicitName, this.body, this.hash);
  
  Future<PackageDep> getPackageDep(String source) => new Future(() {
    if(source == 'hosted') {
      // <name>#<version constraint>.
      if(!nullOrEmpty(explicitName)) throw new FormatException('Cannot specify explicit name for hosted dependency', input);
      var name = body;
      return new Future(() {
        if(hash != null) return new VersionConstraint.parse(hash);
        return fetchPrimaryVersion(name).then(getCompatibleVersionRange);
      }).then((VersionConstraint constraint) {
        return new PackageDep(name, source, constraint, null);
      });
    };
    
    if(source == 'path') {
      // <name>=<path>.
      if(!nullOrEmpty(hash)) throw new FormatException('Cannot specify hash fragment for path dependency', input);
      var path = body;
      var name = explicitName;
      if(name == null) {
      // TODO: Get the name from the pubspec once the "files" package is ready.
//            try {
//              var depPubspec = Pubspec.load(path);
//              name = depPubspec.name;
//            } catch (e) { }
        // Fallback to just using the basename.
        if(name == null) name = p.basename(path);
      } else {
        // TODO: Check for valid path.
      }
      return new PackageDep(name, source, null, body);
    }
    if(source == 'git') {
      // <name>=<git uri>#<ref>.
      var ref = hash;
      var gitUri = body;
      var name = explicitName;
      // TODO: Check for valid git uri.
      // TODO: Actually do the git clone, add to pub cache, and use the name from the pubspec.yaml?
      if(name == null) {
        name = p.basenameWithoutExtension(Uri.parse(gitUri).pathSegments.last);
      }
      var description = ref == null ?
          gitUri : 
          {
            'url': gitUri,
            'ref': ref
          };
      return new PackageDep(name, source, null, description);
    }
  });
}

List<String> _getImmediateDependencyNames() => Pubspec.load().immediateDependencyNames;
List<String> _getHostedDependencyNames() => Pubspec.load().versionConstraints.keys.toList();
