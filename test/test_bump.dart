
library den.test.bump;

import 'package:den/src/bump.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:unittest/unittest.dart';

main() {
  group('bumpVersion', () {
    test('bumps major', () {
      testBump('1.2.3', ReleaseType.major, false, '2.0.0');
    });

    test('bumps minor', () {
      testBump('1.2.3', ReleaseType.minor, false, '1.3.0');
    });

    test('bumps patch', () {
      testBump('1.2.3', ReleaseType.patch, false, '1.2.4');
    });

    test('bumps breaking', () {
      testBump('0.7.2', ReleaseType.breaking, false, '0.8.0');
      testBump('1.2.3', ReleaseType.breaking, false, '2.0.0');
    });

    test('bumps pre-release', () {
      testBump('1.2.3-0', ReleaseType.release, true, '1.2.3-1');
      testBump('1.2.3-pre', ReleaseType.release, true, '1.2.3-pre.0');
      testBump('1.2.3-pre', ReleaseType.release, 'pre', '1.2.3-pre.0');
      testBump('1.2.3-pre', ReleaseType.release, 'dev', '1.2.3-dev.0');
      testBump('1.2.3-dev.1', ReleaseType.release, true, '1.2.3-dev.2');
      testBump('1.2.3-dev.1', ReleaseType.release, 'dev', '1.2.3-dev.2');
      testBump('1.2.3-dev.1', ReleaseType.release, 'alpha', '1.2.3-alpha.0');
    });

    test('bumps build', () {
      testBump('1.2.3', ReleaseType.build, false, '1.2.3+1');
      testBump('1.2.3-beta', ReleaseType.build, false, '1.2.3-beta+1');
      testBump('1.2.3-beta+1', ReleaseType.build, false, '1.2.3-beta+2');
    });

    test('bumps to pre-release of "0" when pre is true', () {
      testBump('1.2.3', ReleaseType.major, true, '2.0.0-0');
      testBump('1.2.3', ReleaseType.minor, true, '1.3.0-0');
      testBump('1.2.3', ReleaseType.patch, true, '1.2.4-0');
    });

    test(r'bumps to pre-release of "${pre}.0" when pre is String', () {
      testBump('1.2.3', ReleaseType.major, 'alpha', '2.0.0-alpha.0');
      testBump('1.2.3', ReleaseType.minor, 'alpha', '1.3.0-alpha.0');
      testBump('1.2.3', ReleaseType.patch, 'alpha', '1.2.4-alpha.0');
    });

    test('throws when trying to bump pre-release of a non-pre-release', () {
      expect(() => bumpVersion(new Version.parse('1.2.3'), ReleaseType.release, pre: true), throwsArgumentError);
    });

    test('throws when trying to bump to a pre-release of a build bump', () {
      expect(() => bumpVersion(new Version.parse('1.2.3'), ReleaseType.build, pre: true), throwsArgumentError);
    });
  });
}

testBump(String v1, ReleaseType releaseType, pre, String v2) {
  var initial = new Version.parse(v1);
  var bumped = bumpVersion(initial, releaseType, pre: pre);
  expect(bumped, new Version.parse(v2));
}