
import 'package:den/den.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:unittest/unittest.dart';
import 'package:yaml/yaml.dart';

main() {
  group('Pubspec', () {
    test('constructor', () {
      var pubspec = new Pubspec(null, pubspecContents, loadYamlNode(pubspecContents));
      expect(pubspec.name, 'foo');
      expect(pubspec.author, 'Jane Doe');
      expect(pubspec.version, '1.2.3');
      expect(pubspec.dependencies, {
        'bar': 'any',
        'baz': '>=1.0.0 <2.0.0'
      });
    });
    
    group('addDependency', () {

      test('should add a dependency', () {
        var pubspec = new Pubspec(null, pubspecContents, loadYamlNode(pubspecContents));
        pubspec.addDependency(new PackageDep('abc', 'hosted', new VersionConstraint.parse('1.0.0'), null));
        expect(pubspec.contents, '''
name: foo
author: Jane Doe
version: 1.2.3
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
  abc: '1.0.0'
dev_dependencies:
  unittest: any
''');
      });

      test('addDevDependency should add a dev dependency', () {
        var pubspec = new Pubspec(null, pubspecContents, loadYamlNode(pubspecContents));
        pubspec.addDevDependency(new PackageDep('abc', 'hosted', new VersionConstraint.parse('1.0.0'), null));
        expect(pubspec.contents, '''
name: foo
author: Jane Doe
version: 1.2.3
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
dev_dependencies:
  unittest: any
  abc: '1.0.0'
''');
      });
      
      test('should replace an existing dependency', () {
        var pubspec = new Pubspec(null, pubspecContents, loadYamlNode(pubspecContents));
        pubspec.addDependency(new PackageDep('baz', 'hosted', new VersionConstraint.parse('2.0.0'), null));
        expect(pubspec.contents, '''
name: foo
author: Jane Doe
version: 1.2.3
dependencies:
  bar: any
  baz: '2.0.0' # Comment
dev_dependencies:
  unittest: any
''');
      });
    });

    test('should add dependencies key if missing', () {
      var pubspec = new Pubspec(null, missingDependencies, loadYamlNode(missingDependencies));
      pubspec.addDependency(new PackageDep('abc', 'hosted', new VersionConstraint.parse('1.0.0'), null));
      expect(pubspec.contents, '''
name: foo
author: Jane Doe
version: 1.2.3
dependencies:
  abc: '1.0.0'
''');
    });
  });
}

var pubspecContents = '''
name: foo
author: Jane Doe
version: 1.2.3
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
dev_dependencies:
  unittest: any
''';

var missingDependencies = '''
name: foo
author: Jane Doe
version: 1.2.3
''';
