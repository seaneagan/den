library den.src.commands.spec;

import 'dart:async';
import 'dart:mirrors';
import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:prompt/prompt.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pub_semver/src/patterns.dart' as patterns;
import 'package:yaml/yaml.dart';

import '../pub.dart';
import '../theme.dart';

class SpecCommand {
  final fields = ['name', 'author', 'version', 'homepage', 'description'];
  final validators = {
    'name': new RegExp(r'[_a-zA-Z][_a-zA-Z0-9]*'),
    'version': patterns.COMPLETE_VERSION,
    'homepage': new RegExp(r'^https?:')
    // TODO: author(s) validation.
  };

  @SubCommand(help: 'Initialize or edit a pubspec file.')
  spec() {
    new File('pubspec.yaml')
    ..exists().then((exists) {
      (exists ? new Future.value(Pubspec.load()) : Pubspec.init())
      .then((pubspec) {
        InstanceMirror pubspecReflection = reflect(pubspec);
        YamlMap yamlMap = pubspec.yamlMap;
        Future.forEach(
          fields,
          (String field) {
            var defaultValue = yamlMap[field] != null ? yamlMap[field] : '';
            var parser = (response) {
              if(response == '') return defaultValue;
              else {
                return
                  (validators.containsKey(field) ? validators[field].hasMatch(response) : true)
                  ? response
                  : throw new FormatException("Invalid input requires: ${validators[field].pattern}");
              }
            };

            var question = defaultValue != ''
              ? new Question("${theme.question(field)} (${theme.questionDefault(defaultValue)})", defaultsTo: defaultValue, parser: parser)
              : new Question(theme.question(field), defaultsTo: defaultValue, parser: parser);

            return ask(question).then((String response) {
              if (response=='') pubspecReflection.setField(new Symbol(field), defaultValue);
              else pubspecReflection.setField(new Symbol(field), response);
            });
        }).then((_) {
          print(_contentValidation(pubspec));
          ask(new Question.confirm("All correct")).then((bool correct) {
            if (correct) {
              pubspec.save();
              close();
              print("\npubspec.yaml ${theme.warning('saved')}.\n");
            } else {
              close();
              print("\npubspec.yaml ${theme.warning('not')} saved.\n");
            }
          });
        });
      });
    });
  }

// TODO: Make contents syntax highlighted.
String _contentValidation(Pubspec pubspec) => '''

pubspec.yaml
============
${pubspec.contents}''';

}
