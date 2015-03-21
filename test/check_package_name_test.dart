import 'package:unittest/unittest.dart';
import 'package:den/src/check_package_name.dart' as den;
import 'common.dart';
import 'dart:math';

final random = new Random();

main() {
  group('checkPackageName(String name)', (){
    test('may not be blank', (){
      expect(den.checkPackageName("").first.contains("may not be empty"), isTrue);
    });
    test('may only contain letters, numbers, and underscores', (){
      expect(den.checkPackageName(generateRandomName(useNonAlphaNumeric: true)).first.contains("may only contain letters, numbers, and underscores"), isTrue);
    });
    test('must begin with a letter or underscore', (){
      expect(den.checkPackageName(generateRandomName(beginWithNumber: true)).first.contains("must begin with a letter or underscore"), isTrue) ;
    });
    test('may not be a reserved word in Dart', (){
      expect(den.checkPackageName(generateRandomName(useReservedWords: true)).first.contains("may not be a reserved word in Dart"), isTrue);
    });
    test('should be lower-case', (){
      expect(den.checkPackageName(generateRandomName(useUpperCase: true)).first.contains("should be lower-case"), isTrue);
    });
  });
  group('unCamelCase(String name)', (){
    test('', (){
      var tokens = new List.generate(3, (i) => randomString(1).toUpperCase() + randomString(4).toLowerCase());
      var sb = new StringBuffer();
      for(var token in tokens) sb.write(token);
      var name = sb.toString();
      var nameCamel = den.unCamelCase(name);
      tokens = tokens.map((token) => token.toLowerCase());
      expect(nameCamel.split('_').every((token) => tokens.contains(token)), isTrue);
    });
  });
}

String generateRandomName({bool useReservedWords: false, bool beginWithNumber: false, bool useNonAlphaNumeric: false, bool useUpperCase: false}) {
  var tokens = [];
  if(beginWithNumber) tokens.add(random.nextInt(9));
  if(useUpperCase) tokens.add(randomString(5));
  else tokens.add(randomAlphaNumeric(5));
  var reserved = new List.from(den.RESERVED_WORDS);
  reserved.shuffle();
  if(useNonAlphaNumeric) tokens.add(randomNonAlphaNumeric(1));

  var sb = new StringBuffer();
  for(var token in tokens) sb.write(useUpperCase ? token.toUpperCase() : token);
  if(useReservedWords) return reserved.first;
  else return sb.toString();
}