
library den.src.commands.install;

import 'dart:async';
import 'dart:mirrors';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:unscripted/unscripted.dart';
import 'package:prompt/prompt.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../pub.dart';

class InitCommand {

  Pubspec _pubspec;
  InstanceMirror get _pubspecReflection => reflect(_pubspec);
  YamlMap get _yamlMap => _pubspec.yamlMap;
  final fields = ['name','version','description','author','homepage'];

  List<Question> get questions =>
    fields.map((String field){
      return new Question("$field (${_yamlMap[field]})");
    });

  @SubCommand(help: 'Initiate pubspec.yaml file.')
  init(

  ) {

    var pubspecFile = new File('pubspec.yaml');
    if(pubspecFile.existsSync()) {
      // TODO: Maybe prompt to delete?
      print("Pubspec file exists.  Delete before proceeding.");
      exit(0);
    }

    _pubspec = Pubspec.init();
    Future.forEach(
      fields,
      (String field){
        var defaultValue =
          !_yamlMap.containsKey(field)
            ? '' :
              _yamlMap[field] != null
                ? _yamlMap[field] : '';


        var question = defaultValue != ''
          ? new Question("$field ($defaultValue)", defaultsTo: defaultValue)
          : new Question(field, defaultsTo: '');

        return ask(question)
        .then((String response){
          if(defaultValue!='') {
            if(response!='') {
              _pubspecReflection.setField(new Symbol(field), response);
            }
          } else {
            _pubspecReflection.setField(new Symbol(field), response);
          }
        });
      }
    ).whenComplete((){
      close();
      _pubspec.save();
    });
  }
}

class BasePrompt {
  String field;
  Pubspec pubspec;
  BasePrompt(this.field, this.pubspec);
  Future run() {
    return ask()
    InstanceMirror pubspecReflection = reflect(pubspec);
    pubspecReflection.setField(new Symbol(this.field), 'testme');
    return new Future.value();
  }
}