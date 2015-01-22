library den.src.commands.spec;

import 'dart:async';
import 'dart:mirrors';
import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:unscripted/unscripted.dart';
import 'package:prompt/prompt.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../pub.dart';
import '../theme.dart';

class SpecCommand {

  Pubspec _pubspec;
  InstanceMirror get _pubspecReflection => reflect(_pubspec);
  YamlMap get _yamlMap => _pubspec.yamlMap;
  final fields = ['name', 'author', 'version', 'homepage', 'description'];

  @SubCommand(help: 'Initialize or edit a pubspec file.')
  spec() {
    new File('pubspec.yaml')
    ..exists().then((exists) {
      (exists ? new Future.value(Pubspec.load()) : Pubspec.init())
      .then((_pubspec) {
        this._pubspec = _pubspec;
        Future.forEach(
          fields,
          (String field) {
            var defaultValue = _yamlMap[field] != null ? _yamlMap[field] : '';

            var question = defaultValue != ''
              ? new Question("${theme.question(field)} (${theme.questionDefault(defaultValue)})", defaultsTo: defaultValue)
              : new Question(theme.question(field), defaultsTo: '');

            return ask(question).then((String response) {
              if (response=='') _pubspecReflection.setField(new Symbol(field), defaultValue);
              else _pubspecReflection.setField(new Symbol(field), response);
            });
        }).then((_) {
          print(_contentValidation());
          ask(new Question.confirm("All correct")).then((bool correct) {
            if (correct) {
              _pubspec.save();
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
String _contentValidation() => '''

pubspec.yaml
============
${_pubspec.contents}''';

}
