
library den.test.bump;

import 'package:den/src/bump.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:unittest/unittest.dart';

main() {
  group('bumpVersion', () {
    test('bumps major', () {
      testBump('1.2.3', VersionPart.major, false, '2.0.0');
    });

    test('bumps minor', () {
      testBump('1.2.3', VersionPart.minor, false, '1.3.0');
    });

    test('bumps patch', () {
      testBump('1.2.3', VersionPart.patch, false, '1.2.4');
    });

    test('bumps pre-release', () {
      testBump('1.2.3-0', VersionPart.preRelease, true, '1.2.3-1');
      testBump('1.2.3-pre', VersionPart.preRelease, true, '1.2.3-pre.0');
      testBump('1.2.3-pre', VersionPart.preRelease, 'pre', '1.2.3-pre.0');
      testBump('1.2.3-pre', VersionPart.preRelease, 'dev', '1.2.3-dev.0');
      testBump('1.2.3-dev.1', VersionPart.preRelease, true, '1.2.3-dev.2');
      testBump('1.2.3-dev.1', VersionPart.preRelease, 'dev', '1.2.3-dev.2');
      testBump('1.2.3-dev.1', VersionPart.preRelease, 'alpha', '1.2.3-alpha.0');
    });

    test('bumps build', () {
      testBump('1.2.3', VersionPart.build, false, '1.2.3+1');
      testBump('1.2.3-beta', VersionPart.build, false, '1.2.3-beta+1');
      testBump('1.2.3-beta+1', VersionPart.build, false, '1.2.3-beta+2');
    });

    test('bumps pre-release of pre-release by default', () {
      testBump('1.2.3-beta.0', null, false, '1.2.3-beta.1');
    });

    test('bumps patch of non-pre-release by default', () {
      testBump('1.2.3', null, false, '1.2.4');
    });

    test('bumps to pre-release of "0" when pre is true', () {
      testBump('1.2.3', VersionPart.major, true, '2.0.0-0');
      testBump('1.2.3', VersionPart.minor, true, '1.3.0-0');
      testBump('1.2.3', VersionPart.patch, true, '1.2.4-0');
    });

    test(r'bumps to pre-release of "${pre}.0" when pre is String', () {
      testBump('1.2.3', VersionPart.major, 'alpha', '2.0.0-alpha.0');
      testBump('1.2.3', VersionPart.minor, 'alpha', '1.3.0-alpha.0');
      testBump('1.2.3', VersionPart.patch, 'alpha', '1.2.4-alpha.0');
    });

    test('throws when trying to bump pre-release of a non-pre-release', () {
      expect(() => bumpVersion(new Version.parse('1.2.3'), part: VersionPart.preRelease), throwsArgumentError);
    });

    test('throws when trying to bump to a pre-release of a build bump', () {
      expect(() => bumpVersion(new Version.parse('1.2.3'), part: VersionPart.build, pre: true), throwsArgumentError);
    });
  });
}

testBump(String v1, VersionPart part, pre, String v2) {
  var initial = new Version.parse(v1);
  var bumped = bumpVersion(initial, part: part, pre: pre);
  expect(bumped, new Version.parse(v2));
}