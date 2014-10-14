#!/usr/bin/env dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:den/den.dart';
import 'package:den/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:unscripted/unscripted.dart';

main(arguments) => declare(Den).execute(arguments);
    
class Den {
  
  @Command(
      allowTrailingOptions: true, 
      help: 'Interact with pubspecs', 
      plugins: const [const Completion()])
  Den();
  
  @SubCommand(help: 'Add or modify pubspec dependencies')
  // TODO: Maybe add an --offline flag to prevent any network activity.
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
      
      new File(pubspec.path).writeAsStringSync(pubspec.contents);
      print('Added ${dev ? 'dev_' : ''}dependencies:\n');
      
      var otherDepGroupKey = dev ? 'dependencies' : 'dev_dependencies';
      deps.forEach((PackageDep dep) {
        var buffer = new StringBuffer(dep.name);
        buffer.write(': ');
        buffer.write(dep.source == 'hosted' ?
            "'${dep.constraint}'" :
            dep.description);
        if(movedDependencies.containsKey(dep.name)) buffer.write(' (moved from "$otherDepGroupKey")');
        print(indent(buffer.toString(), 2));
      });
    });
  }
  
  @SubCommand(help: 'Remove pubspec dependencies')
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
    new File(pubspec.path).writeAsStringSync(pubspec.contents);
    
    if(removedDeps.isNotEmpty) {
      print('Removed (dev_)dependencies:\n');
      removedDeps.forEach((name, old) {
        print('  $name: ${JSON.encode(old)}');
      });
    } else {
      print('No (dev_)dependencies removed.');
    }

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
      return new Future(() {
        if(hash != null) return new VersionConstraint.parse(hash);
        return fetchPackage('http://pub.dartlang.org/packages/$body.json').then((package) {
          return getCompatibleVersionRange(package.latest);
        });
      }).then((VersionConstraint constraint) {
        return new PackageDep(body, source, constraint, null);
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

VersionConstraint _parseVersionConstraint(String constraint) {
  if(constraint == null) return null;
  return new VersionConstraint.parse(constraint);
}

VersionRange getCompatibleVersionRange(Version version) {
  var nextBreaking = version.major >= 1 ? version.nextMajor : version.nextMinor;
  return new VersionRange(min: version, max: nextBreaking, includeMin: true);
}

bool nullOrEmpty(String str) => str == null || str.isEmpty; 

List<String> _getImmediateDependencyNames() {
  var pubspec = Pubspec.load();
  return []
      ..addAll(pubspec.dependencies.keys)
      ..addAll(pubspec.devDependencies.keys);
}
