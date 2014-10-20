
import 'package:den/src/pub.dart';
import 'package:path/path.dart' as p;
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

      test('should add a hosted dependency', () {
        testAddDependency(
            new PackageDep('abc', 'hosted', new VersionConstraint.parse('1.0.0'), null),
            pubspecContents,
            '''
$preamble
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
  abc: '1.0.0'
dev_dependencies:
  unittest: any
''');
      });

      test('should replace an existing dependency', () {
        testAddDependency(
            new PackageDep('baz', 'hosted', new VersionConstraint.parse('2.0.0'), null),
            pubspecContents,
            '''
$preamble
dependencies:
  bar: any
  baz: '2.0.0' # Comment
dev_dependencies:
  unittest: any
''');
      });
    });

    test('should add dependencies key if missing', () {
      testAddDependency(
          new PackageDep('abc', 'hosted', new VersionConstraint.parse('1.0.0'), null),
          preamble,
          '''
$preamble
dependencies:
  abc: '1.0.0'
''');
    });
  });
  
  test('should add a path dependency', () {
    var path = p.join('foo', 'bar', 'baz');
    testAddDependency(
        new PackageDep('abc', 'path', null, path),
        pubspecContents,
        '''
$preamble
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
  abc:
    path: $path
dev_dependencies:
  unittest: any
''');
  });

  test('should add a git dependency', () {
    testAddDependency(
        new PackageDep('abc', 'git', null, 'git://github.com/foo/bar.git'),
        pubspecContents,
        '''
$preamble
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
  abc:
    git: git://github.com/foo/bar.git
dev_dependencies:
  unittest: any
''');
  });

  test('should add a git dependency with ref', () {
    testAddDependency(
        new PackageDep('abc', 'git', null, {
          'url': 'git://github.com/foo/bar.git',
          'ref': 'foo-branch',
        }),
        pubspecContents,
        '''
$preamble
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
  abc:
    git:
      url: git://github.com/foo/bar.git
      ref: foo-branch
dev_dependencies:
  unittest: any
''');
  });
    
  test('should add a dev dependency when dev is true', () {
    var pubspec = new Pubspec(null, pubspecContents, loadYamlNode(pubspecContents));
    pubspec.addDependency(new PackageDep('abc', 'hosted', new VersionConstraint.parse('1.0.0'), null), dev: true);
    expect(pubspec.contents, '''
$preamble
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
dev_dependencies:
  unittest: any
  abc: '1.0.0'
''');
  });
  
  group('undepend', () {
    
    test('should remove a dependency', () {
      var pubspec = new Pubspec(null, pubspecContents, loadYamlNode(pubspecContents));
      pubspec.undepend('baz');
      expect(pubspec.contents, '''
$preamble
dependencies:
  bar: any
dev_dependencies:
  unittest: any
''');
    });

    test('should error when trying to remove a dependency from a yaml flow mapping', () {
      var flowMapping = '''
$preamble
dependencies: {
  bar: any,
  baz: any
}
dev_dependencies:
  unittest: any
''';
      var pubspec = new Pubspec(null, flowMapping, loadYamlNode(pubspecContents));
      expect(() => pubspec.undepend('bar'), throwsUnimplementedError);
//      expect(pubspec.contents, '''
//$preamble
//dependencies: {
//  bar: any
//}
//dev_dependencies:
//  unittest: any
//''');
    });

    test('should remove the dependency group node when it becomes empty', () {
      var pubspec = new Pubspec(null, pubspecContents, loadYamlNode(pubspecContents));
      pubspec.undepend('unittest');
      expect(pubspec.contents, '''
$preamble
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
''');
    });
  });
}

testAddDependency(PackageDep dependency, String originalContents, String expectedNewContents) {
  var pubspec = new Pubspec(null, originalContents, loadYamlNode(originalContents));
  pubspec.addDependency(dependency);
  expect(pubspec.contents, expectedNewContents);
}

var pubspecContents = '''
$preamble
dependencies:
  bar: any
  baz: '>=1.0.0 <2.0.0' # Comment
dev_dependencies:
  unittest: any
''';

var preamble = '''
name: foo
author: Jane Doe
version: 1.2.3''';
