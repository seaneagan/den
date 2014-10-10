#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

import 'package:den/den.dart';
import 'package:den/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:unscripted/unscripted.dart';

import 'pens.dart';

main(arguments) => declare(Den).execute(arguments);
    
class Den {
  
  @Command(
      allowTrailingOptions: true, 
      help: 'Interact with pubspecs', 
      plugins: const [const Completion()])
  Den();
  
  @SubCommand(help: 'Add or modify pubspec dependencies')
  // TODO: Maybe add an --offline flag to prevent any network activity.
  depend(
      @Rest(
          required: true, 
          valueHelp: 'endpoint', 
          allowed: packageList, 
          help: '''  Can be any of:

-shosted <name>
-shosted <name>#<version>

-sgit    <name>=<git url>#<git ref>
-sgit           <git url>#<git ref> (Derives <name> from <git url>)
-sgit           <git url>

-spath   <name>=<path>

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
      
      var packagePattern = new RegExp(r'^(([a-zA-Z0-9_]+)=)?([^#]+)(#([^#]+))?');
      
      Iterable<_SplitPackage> splitPackages = packages.map((package) {
        var match = packagePattern.firstMatch(package);
        if(match == null) throw new FormatException('Invalid package argument', package);
        return new _SplitPackage(match.input, match.group(2), match.group(3), match.group(5));
      });
      
      if(source == 'hosted') {
        // <name>#<version constraint>.
        return Future.wait(splitPackages.map((splitPackage) => new Future(() {
          if(!nullOrEmpty(splitPackage.explicitName)) throw new FormatException('Cannot specify explicit name for hosted dependency', splitPackage.input);
          return new Future(() {
            if(splitPackage.hash != null) return new VersionConstraint.parse(splitPackage.hash);
            return fetchPackage('http://pub.dartlang.org/packages/${splitPackage.body}.json').then((package) {
              return getCompatibleVersionRange(package.latest);
            });
          }).then((VersionConstraint constraint) {
            return new PackageDep(splitPackage.body, source, constraint, null);
          });
        })));
      }
      
      if(source == 'path') {
        return splitPackages.map((splitPackage) {
          // <name>=<path>.
          if(!nullOrEmpty(splitPackage.hash)) throw new FormatException('Cannot specify hash fragment for path dependency', splitPackage.input);
          var path = splitPackage.body;
          var name = splitPackage.explicitName;
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
          return new PackageDep(name, source, null, splitPackage.body);
        });
      }
      if(source == 'git') {
        return splitPackages.map((splitPackage) {
          // <name>=<git uri>#<ref>.
          var ref = splitPackage.hash;
          var gitUri = splitPackage.body;
          var name = splitPackage.explicitName;
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
        });
      }
    }).then((deps) {
      // TODO: Validate existing pubspec, and fail if necessary.
      //       See dartbug.com/21169
      var pubspec = Pubspec.load();
      var otherDepGroup = dev ? pubspec.dependencies : pubspec.devDependencies;
      var otherDepGroupKey = dev ? 'dependencies' : 'dev_dependencies';
      var movedDependencies = [];
      
      deps.forEach((PackageDep dep) {
        if(otherDepGroup.containsKey(dep.name)) {
          movedDependencies.add(dep.name);
          pubspec.undepend(dep.name, dev: !dev);
        }
        // TODO: Implement returning any old dep being replaced, and log it below.
        var oldDep = dev ? pubspec.addDevDependency(dep) : pubspec.addDependency(dep);
      });
      new File(pubspec.path).writeAsStringSync(pubspec.contents);
      print('Added ${dev ? titlePen('dev_') : ''}dependencies:\n');
      
      deps.forEach((PackageDep dep) {
        var buffer = new StringBuffer(namePen(dep.name));
        buffer.write(': ');
        buffer.write(dep.source == 'hosted' ?
            "'${dep.constraint}'" :
            dep.description);
        if(movedDependencies.contains(dep.name)) buffer.write(' (moved from "$otherDepGroupKey")');
        print(indent(buffer.toString(), 2));
      });
    });
  }
}

class _SplitPackage {
  final String input, explicitName, body, hash;
  
  _SplitPackage(this.input, this.explicitName, this.body, this.hash);
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
