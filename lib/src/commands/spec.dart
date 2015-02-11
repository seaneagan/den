library den.src.commands.spec;

import 'dart:async';
import 'dart:mirrors';
import 'dart:io';

import 'package:unscripted/unscripted.dart';
import 'package:prompt/prompt.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../check_package_author.dart';
import '../check_package_name.dart';
import '../pub.dart';
import '../theme.dart';
import '../util.dart';
import '../yaml_highlighter.dart';

class SpecCommand {

  @SubCommand(help: '''
Guides you through creating a pubspec by prompting for field values using 
defaults based on your local git info etc.

To use only defaults, and avoid the prompts, pass --force.

If there is already an existing pubspec, the prompts will default to the
existing field values instead.''')
  spec({
      @Flag(abbr: 'f', help: 'Use only defaults, do not prompt')
      bool force: false}) {
    new File(Pubspec.basename).exists().then((exists) =>
      new Future(() => exists ? Pubspec.load() : Pubspec.init())
      .then((pubspec) {
        var action = exists ? 'update' : 'create';
        save(bool shouldSave) {
          if (shouldSave) pubspec.save();
          var negation = shouldSave ? '' : ' ${theme.warning('not')}';
          var sendOff = "\nPubspec$negation ${action}d.";
          if (shouldSave && !exists) {
            sendOff += '  You can now add dependencies to it with `den install`.';
          }
          print(sendOff);
        }

        if (force) {
          if (exists) {
            print('Can\'t use --force to $action a pubspec.');
            exit(1);
          }
          save(true);
          return;
        }

        print('''

Please answer the prompts below to $action ${exists ? 'the local' : 'a'} pubspec.
(Defaults are based on ${exists ? 'existing field values' : 'your local git info etc.'})
''');

        InstanceMirror pubspecMirror = reflect(pubspec);
        YamlMap yamlMap = pubspec.yamlMap;
        Future.forEach(
          fields,
          (Symbol field) {
            var question;
            if (field == #description) {
              question = getFieldQuestion(pubspec, field, defaultDefaultsTo: '');
            } else {
              question = getFieldQuestion(pubspec, field);
            }
            return ask(question).then((answer) {
              pubspecMirror.setField(field, answer);
            });
        })
        .then((_) => promptSdkConstraint(pubspec))
        .then((_) {
          print(contentValidation(pubspec));
          return ask(new Question.confirm("${upperCaseFirst(action)} pubspec as above", defaultsTo: exists ? null : true)).then((bool correct) {
            save(correct);
          });
        }).whenComplete(close);
      })
    );
  }
}

Question getFieldQuestion(Pubspec pubspec, Symbol field, { defaultDefaultsTo }) {
  var parser = parsers[field];
  var defaultsTo = reflect(pubspec).getField(field).reflectee;
  if (defaultsTo == null) defaultsTo = defaultDefaultsTo;
  var message = MirrorSystem.getName(field);
  return new Question(message, defaultsTo: defaultsTo, parser: parser);
}

// TODO: Add sdk constraint.
final fields = [#name, #author, #version, #homepage, #description];
final parsers = {
  #name: (String name) {
    var errors = checkPackageName(name);
    if (errors.isEmpty) return name;
    throw errors.first;
  },
  #version: (String version) {
    try {
      return new Version.parse(version);
    } catch (e) {
      throw 'Version "$version" must be a valid semver version.';
    }
  },
  #homepage: (String homepage) {
    var uri = Uri.parse(homepage);
    // TODO: Throw on relative uri's like 'foo'.
    if (!uri.isAbsolute) throw 'Homepage "$homepage" must be an absolute uri.';
    if (!new RegExp(r'^https?$').hasMatch(uri.scheme)) throw 'Homepage "$homepage" must be an http(s) uri.';
    return homepage;
  },
  #author: (String author) {
    var errors = checkAuthor(author);
    if (errors.isEmpty) return author;
    throw errors.first;
  }
};

String contentValidation(Pubspec pubspec) => '''

${indent(new YamlHighlighter(pubspec.contents, pubspec.yamlMap, yamlHighlighterTheme).toString(), 2)}''';

Future<VersionConstraint> promptSdkConstraint(Pubspec pubspec) => new Future(() {
  var prevMajor = new Version(sdkVersion.major, 0, 0);
  var prevMinor = new Version(sdkVersion.major, sdkVersion.minor, 0);
  var nextMajor = sdkVersion.nextMajor;
  // Can't use [VersionConstraint.compatibleWith] directly since the [toString] will use `^`.
  VersionConstraint compatibleWith(Version version) {
    var comp = new VersionConstraint.compatibleWith(version);
    return removeCaretFromVersionConstraint(comp);
  }
  var custom = 'custom...';
  var none = 'none';
  var allowed = [prevMajor, prevMinor, sdkVersion]
      .map(compatibleWith)
      .toList()
      ..add(custom)
      ..add(none);
  var currentConstraint = pubspec.sdkConstraint;
  if (VersionConstraint.any == currentConstraint) {
    currentConstraint = none;
  }
  // Remove any existing instance of current constraint.
  allowed.remove(currentConstraint);
  // Re-insert as first (default) option.
  allowed.insert(0, currentConstraint);
  // Remove duplicates.
  allowed = new Set.from(allowed).toList();
  var defaultsTo = allowed.first;
  var sdkConstraintQuestion = new Question(
      'Sdk constraint',
      allowed: allowed,
      defaultsTo: defaultsTo);

  return ask(sdkConstraintQuestion).then((answer) {
    if (answer == none) return null;
    if (answer == custom) {
      return ask(new Question(
          'Custom sdk constraint',
          parser: (v) {
            var constraint = new VersionConstraint.parse(v);
            if (constraint.toString().contains('^')) {
              var fixed = removeCaretFromVersionConstraint(constraint);
              print('Sdk constraints cannot use ^, using "$fixed" instead.');
              return fixed;
            }
            return constraint;
          }));
    }
    return answer;
  }).then((sdkConstraint) {
      pubspec.sdkConstraint = sdkConstraint;
  });
});
