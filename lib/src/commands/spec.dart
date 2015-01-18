
library den.src.commands.spec;

import 'dart:async';
import 'dart:mirrors';
import 'dart:io';

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
  final fields = ['name','version','author','homepage','description'];

  List<Question> get questions =>
    fields.map((String field){
      return new Question("$field (${_yamlMap[field]})");
    });

  @SubCommand(help: 'Initiate or edit pubspec.yaml file.')
  spec(

  ) {
    _prompts();
  }

  Future _prompts() {
    var pubspecFile = new File('pubspec.yaml');
    _pubspec = pubspecFile.existsSync() ? Pubspec.load() : Pubspec.init();

    return Future.forEach(
      fields,
      (String field){
        var defaultValue = _yamlMap[field] != null ? _yamlMap[field] : '';

        var question = defaultValue != ''
          ? new Question("${theme.question(field)} (${theme.questionDefault(defaultValue)}):", defaultsTo: defaultValue)
          : new Question(theme.question(field), defaultsTo: '');

        return ask(question)
        .then((String response){
          if(response=='') _pubspecReflection.setField(new Symbol(field), defaultValue);
          else _pubspecReflection.setField(new Symbol(field), response);
        });
      }
    ).whenComplete((){

      var contents = _syntaxHighlighted();
      print("\npubspec.yaml\n============\n$contents\n");
      return ask(new Question.confirm("All correct?", defaultsTo:true))
      .then((bool correct){
        if(!correct) return _prompts();
        else {
          _pubspec.save();
          return close();
        }
      });
    });
  }

  String _syntaxHighlighted() {
    var fieldContents = fields.toSet().intersection(_yamlMap.keys.toSet()).map(
          (String field) {
            return "${theme.field(field)}: ${theme.value(_yamlMap[field])}";
          }
        ).join("\n");

    var envContents = _yamlMap['environment'] != null ? _block('environment') : '';
    var depContents = _yamlMap['dependencies'] != null ? _block('dependencies') : '';
    var devdepContents = _yamlMap['dev_dependencies'] != null ? _block('dev_dependencies') : '';;

    return "$fieldContents$envContents$depContents$devdepContents";
  }

  String _block(String title) {
    var lines = _yamlMap[title].keys
    .map((String key) {
      var value = "'${_yamlMap[title][key]}'";
      return "${theme.dependency(key)}: ${theme.value(value)}";
    }).toList();
    return "\n${theme.field(title + ':')}\n${lines.map((line) => '  $line').join('\n')}";
  }
}