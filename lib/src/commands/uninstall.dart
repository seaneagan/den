
library den.src.commands.uninstall;

import 'dart:convert';

import 'package:den_api/den_api.dart';
import 'package:unscripted/unscripted.dart';

import '../theme.dart';
import '../util.dart';

class UninstallCommand {
  @SubCommand(help: 'Remove dependencies')
  uninstall(
      @Rest(
          required: true,
          valueHelp: 'package name',
          allowed: getImmediateDependencyNames,
          help: 'Name of dependency to remove')
      List<String> names) => Pubspec.load().then((pubspec) {
    var removedDeps = names.fold({}, (removedDeps, name) {
      var removed = pubspec.undepend(name);
      if(removed != null) removedDeps[name] = removed;
      return removedDeps;
    });

    pubspec.save();

    if (removedDeps.isNotEmpty) {
      var lines = [];
      removedDeps.forEach((name, old) {
        lines.add('${theme.dependency(name)}${theme.info(': ')}${theme.version(JSON.encode(old))}');
      });
      print(block('Uninstalled these dependencies', lines));
    } else {
      print('No (dev_)dependencies removed.');
    }

  });
}
