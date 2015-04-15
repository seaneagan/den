library den.test.common;

import 'dart:math';

String randomString(int length,
    {String allow: "ABCDEFGHIJKLMNSTOPQRSTUVWXYZabcdefghijklmnstopqrstuvwxyz"}) {
  var rand = new Random();
  var candidates = allow.split('');
  return new List.generate(
      length, (index) => candidates[rand.nextInt(candidates.length)]).join("");
}

String randomAlpha(int length) => randomString(length);

String randomAlphaNumeric(int length) => randomString(length,
    allow: "0123456789ABCDEFGHIJKLMNSTOPQRSTUVWXYZabcdefghijklmnstopqrstuvwxyz");

String randomNonAlphaNumeric(int length) {
  var allow = "`~!@#\$%^&*()-+={}[]|<>,.:;";
  return randomString(length, allow: allow);
}
