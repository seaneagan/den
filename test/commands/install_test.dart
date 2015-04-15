import 'package:unittest/unittest.dart';
import 'package:den/src/commands/install.dart' as den;
import 'package:path/path.dart' as p;
import 'package:pub_package_data/pub_package_data.dart';
import 'package:yaml/yaml.dart';

import 'dart:io';
import 'dart:async';

main() {
  var installCommandTest = new InstallCommandTest();
  Directory.current = installCommandTest.workingDir;
  List packages;
  group('install', () {
    setUp(() => installCommandTest.loadPackages());
    test('setup ok', () {
      packages = installCommandTest.packages;
      expect(packages, isNotNull);
      expect(packages, isNotEmpty);
    });
    group('<name>', () {
      test('', () {
        Future.forEach([
          installCommandTest.run([packages[0].name]),
          installCommandTest.run([packages[0].name, packages[1].name]),
          installCommandTest.run([
            packages[0].name, packages[1].name, packages[2].name
          ]),
          installCommandTest.run([
            packages[0].name,
            packages[1].name,
            packages[2].name,
            packages[3].name
          ]),
          installCommandTest.run([
            packages[0].name,
            packages[1].name,
            packages[2].name,
            packages[3].name,
            packages[4].name
          ]),
          installCommandTest.run([packages[0].name], dev: true),
          installCommandTest.run([
            packages[0].name, packages[1].name],
            dev: true),
          installCommandTest.run([
            packages[0].name, packages[1].name, packages[2].name
          ], dev: true),
          installCommandTest.run([
            packages[0].name,
            packages[1].name,
            packages[2].name,
            packages[3].name
          ], dev: true),
          installCommandTest.run([
            packages[0].name,
            packages[1].name,
            packages[2].name,
            packages[3].name,
            packages[4].name
          ], dev: true)
        ], (e) {});
      });
    });
  });
}

class InstallCommandTest {
  String _pubspec = "name: foo";
  String get workingDirPath => p.dirname(Platform.script.path);
  Directory get workingDir => new Directory(workingDirPath);

  File get pubspec => new File(p.join(workingDirPath, "pubspec.yaml"));

  final command = new den.InstallCommand();

  List packages;

  Future loadPackages() => new Future(() {
    var baseUrl = "https://pub.dartlang.org/packages/";
    var randomPackageList = new List.from(packageList);
    randomPackageList.shuffle();
    var urlList =
        randomPackageList.sublist(0, 5).map((name) => "$baseUrl$name.json");
    return Future
        .wait(urlList.map((url) => fetchPackage(url)))
        .then((_packages) {
      packages = _packages;
      return packages;
    });
  });

  Future run(
    List packageListArgs,
    {
      String source: 'hosted', bool dev: false}
    ) => new Future(() {
      return pubspec.writeAsString(_pubspec).then((_) {
        StreamSubscription subscription;
        subscription = pubspec.watch().listen((e) {
          var doc = loadYaml(pubspec.readAsStringSync());
          var dependencies = doc['dependencies'];
          if (source == 'hosted') {
            packageListArgs.forEach((arg) {
              if (arg.contains('#')) {
                expect(1, 1);
              } else {
                expect(dependencies.containsKey(arg), isTrue);
              }
            });
          } else {
            expect(1, 1);
          }
          return subscription.cancel();
        });

      command.install(packageListArgs);
    });
  });
}
