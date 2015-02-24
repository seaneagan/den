
library den.src.commands.install;

import 'dart:async';

import '../api/den_api.dart';
// TODO: Don't depend on private code.
import '../api/src/util.dart';
import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:unscripted/unscripted.dart';

import '../theme.dart';
import '../util.dart';

class InstallCommand {
  @SubCommand(help: 'Add or modify dependencies')
  install(
      @Rest(
          required: true,
          valueHelp: 'endpoint',
          allowed: packageList,
          // TODO: Unindent once the following bugs are fixed:
          //   http://github.com/seaneagan/unscripted/81
          //   http://github.com/seaneagan/unscripted/82
          help: '''Can be any of:

              <name>
              <name>#<version>
              
                     <git url>           -sgit  (Derives <name> from <git url>)
                     <git url>#<git ref> -sgit
              <name>=<git url>#<git ref> -sgit
              
                     <path>              -spath (Derives <name> from <path>)
              <name>=<path>              -spath
              
              Where <name> should match the name: in the corresponding pubspec
              (avoids fetching the pubspec).
              
              For more info on <name>, <git url>, <git ref>, and <path>, see:
                https://www.dartlang.org/tools/pub/dependencies.html 
''')
      List<String> packages,
      {
      @Option(abbr: 's', allowed: const ['hosted', 'git', 'path'], help: 'The source of the package(s).')
      String source: 'hosted',
      @Flag(help: 'Whether this is a dev dependency.')
      bool dev: false,
      @Flag(negatable: true)
      bool caret
  }) => Pubspec.load().then((pubspec) {
    // TODO: Validate existing pubspec, and fail if necessary.
    //       See dartbug.com/21169
    caret = defaultCaret(caret, pubspec);
    new Future(() {
      return Future.wait(packages
          .map(_SplitPackage.parse)
          .map((splitPackage) => splitPackage.getPackageDep(source, caret: caret)));
    }).then((deps) {
      var movedDependencies = {};

      deps.forEach((PackageDep dep) {
        var oldDep = pubspec.addDependency(dep, dev: dev);
        if(oldDep != null) movedDependencies[dep.name] = oldDep;
      });

      pubspec.save();

      var otherDepGroupKey = dev ? 'dependencies' : 'dev_dependencies';
      var lines = [];
      deps.forEach((PackageDep dep) {
        var buffer = new StringBuffer();
        buffer
            ..write('${theme.dependency(dep.name)}: ')
            ..write(theme.version(dep.source == 'hosted' ?
                "'${dep.constraint}'" :
                dep.description));
        if(movedDependencies.containsKey(dep.name)) buffer.write(theme.info(' (moved from "$otherDepGroupKey")'));
        lines.add(buffer.toString());
      });
      print(block('Installed these ${dev ? 'dev_' : ''}dependencies', lines));
    });
  });
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

  Future<PackageDep> getPackageDep(String source, {bool caret}) => new Future(() {
    if(source == 'hosted') {
      // <name>#<version constraint>.
      if(!nullOrEmpty(explicitName)) throw new FormatException('Cannot specify explicit name for hosted dependency', input);
      var name = body;
      return new Future(() {
        if(hash != null) return new VersionConstraint.parse(hash);
        return fetchPrimaryVersion(name).then((version) => caret ?
            new VersionConstraint.compatibleWith(version) :
            getCompatibleVersionRange(version));
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
