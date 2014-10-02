#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

import 'package:den/den.dart';
import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:unscripted/unscripted.dart';

main(arguments) => declare(Den).execute(arguments);
    
class Den {
  
  @Command(help: 'Interact with pubspecs', plugins: const [const Completion()])
  Den();
  
  @SubCommand(help: 'Add or modify pubspec dependencies')
  // TODO: Maybe add an --offline flag to prevent any network activity.
  depend(
      @Rest(
          required: true, 
          valueHelp: 'package ids', 
          allowed: packageList, 
          help: '''
For --source=hosted the name(s) e.g. "foo", for --source=git the url(s) e.g. "git:...", for --source=path the path(s) e.g. "foo/bar/baz".''')
      List<String> packages,
      {
      @Option(abbr: 's', allowed: const ['hosted', 'git', 'path'], help: 'The source of the package(s).')
      String source: 'hosted',
      @Flag(help: 'Whether this is a dev dependency.')
      bool dev: false
  }) {

    new Future(() {
      
      var packagePattern = new RegExp(r'$(([a-zA-Z0-9_]+)=)?([^#]+)(#([^#]+))?');
      
      Iterable<_SplitPackage> splitPackages = packages.map((package) {
        var match = packagePattern.firstMatch(package);
        if(match == null) throw new FormatException('Invalid package argument', package);
        return new _SplitPackage(match.input, match.group(2), match.group(3), match.group(5));
      });
      
      if(source == 'hosted') {
        // <name on host>#<version constraint>.
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
//            try {
//              // Try to get the name from the pubspec.
//              var depPubspec = Pubspec.load(path);
//              name = depPubspec.name;
//            } catch (e) { }
            // Fallback to just using the basename.
            if(name == null) name = p.basename(path);
            print('Could not get name from pubspec at path: $path.');
          } else {
            // TODO: Check for valid path.
          }
          return new PackageDep(name, source, new VersionConstraint.parse(splitPackage.hash), splitPackage.body);
        });
      }
      if(source == 'git') {
        return splitPackages.map((splitPackage) {
          // <name>=<git uri>#<ref>.
          var ref = splitPackage.hash;
          var gitUri = splitPackage.body;
          var name = splitPackage.explicitName;
          // TODO: Check for valid git uri.
          // TODO: Actually do the git clone, add to pub cache, and check the name in the pubspec.yaml?
          if(name == null) {
            name = p.basenameWithoutExtension(Uri.parse(gitUri).pathSegments.last);
          }
          var description = ref == null ?
              gitUri : 
              {
                'url': gitUri,
                'ref': ref
              };
          return packages.map((package) => new PackageDep(name, source, null, description));
        });
      }
    }).then((deps) {
      var pubspec = Pubspec.load();
      deps.forEach((PackageDep dep) {
        // TODO: Implement returning any old dep being replaced, and log it below.
        var oldDep = dev ? pubspec.addDevDependency(dep) : pubspec.addDependency(dep);
      });
      new File(pubspec.path).writeAsStringSync(pubspec.contents);
      print('Added the following pubspec dependencies:');
      deps.forEach(print);
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
