import 'package:unittest/unittest.dart';
import 'package:den/src/check_package_author.dart' as den;

main() {
  group('checkAuthor(String author)', () {
    var correctAuthor = "Foo Bar <foo@example.com>";
    var noNameAuthor = "foo@example.com";
    var noEmailAuthor = "Foo Bar";
    test('correct author results messages empty', () {
      List messages = den.checkAuthor(correctAuthor);
      expect(messages, isEmpty);
    });
    test('name only author results Author should have an email message', () {
      List messages = den.checkAuthor(noNameAuthor);
      expect(
        messages.first.contains('Author "$noNameAuthor" should have an email address'),
        isTrue
      );
    });
    test('email only author results Author should have name', () {
      List messages = den.checkAuthor(noEmailAuthor);
      expect(
        messages.first.contains('Author "$noEmailAuthor" should have an email address'),
        isTrue
      );
    });
  });
}
