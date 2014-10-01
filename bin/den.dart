#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:den/den.dart';
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';

main(arguments) => declare(Den).execute(arguments);
    
class Den {
  
  @Command(help: 'Interact with pubspecs', plugins: const [const Completion()])
  Den();
  
  @SubCommand(help: 'Add or modify pubspec dependencies')
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
      @Option(parser: _parseVersionConstraint, help: 'The version constraint of the package(s), only applicable when --source=hosted.')
      VersionConstraint constraint,
      @Flag(help: 'Whether this is a dev dependency.')
      bool dev: false
  }) {

    new Future(() {
      if(source == 'hosted' && constraint == null) {

        VersionRange getCompatibleVersionRange(Version version) {
          var nextBreaking = version.major >= 1 ? version.nextMajor : version.nextMinor;
          return new VersionRange(min: version, max: nextBreaking, includeMin: true);
        }
        
        return Future.wait(packages.map((package) => fetchPackage('http://pub.dartlang.org/packages/$package.json'))).then((packages) {
          return packages.map((package) => new PackageDep(package.name, source, getCompatibleVersionRange(package.latest), null));
        });
      }
      
      return packages
          .map((package) => new PackageDep(package, source, constraint, null));
    }).then((deps) {
      var pubspec = Pubspec.load();
      deps.forEach(dev ? pubspec.addDevDependency : pubspec.addDependency);
      new File(pubspec.path).writeAsStringSync(pubspec.contents);
    });
  }
}

VersionConstraint _parseVersionConstraint(String constraint) {
  if(constraint == null) return null;
  return new VersionConstraint.parse(constraint);
}
