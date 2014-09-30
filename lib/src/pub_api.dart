
library pub_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';

/**
 * Execute `pub install` at the `workingDirectory`
 */
int pubInstall(String workingDirectory) {
  List<String> args = ['install'];
  ProcessResult processResult = Process.runSync('pub', args, workingDirectory:
      workingDirectory, runInShell: true);
  // Logger.root.finest(processResult.stdout);
  // Logger.root.severe(processResult.stderr);
  return processResult.exitCode;
}

/**
 * Class prepresentation of `<package>.json` file.
 */
class Package {
  List<String> uploaders;
  String name;
  List<Version> versions;
  
  Version get latest => Version.primary(versions);

  Package(this.name, this.versions, {this.uploaders});

  Package.fromJson(Map data) {
    uploaders = new List<String>();
    if (data.containsKey('uploaders')) {
      for (var u in data['uploaders']) {
        uploaders.add(u);
      }
    }

    if (data.containsKey('name')) {
      name = data['name'];
    }

    versions = new List<Version>();
    if (data.containsKey('versions')) {
      versions.addAll(data['versions'].map((v)=>new Version.parse(v)).toList());
    }
  }

  Map toJson() {
    Map map = {};
    map['name'] = name;
    map['versions'] = versions.map((e)=>e.toString()).toList();
    map['uploaders'] = uploaders;
    return map;
  }

  String toString() => JSON.encode(toJson());

}

/**
 * Class prepresentation of `packages.json` file.
 */
class PackagePage {
  String prev;
  List<String> packages;
  int pages;
  String next;
  PackagePage.fromJson(Map data) {
    if (data.containsKey('prev')) {
      prev = data['prev'];
    }

    if (data.containsKey('pages')) {
      pages = data['pages'];
    }

    if (data.containsKey('next')) {
      next = data['next'];
    }

    packages = new List<String>();
    if (data.containsKey('packages')) {
      for (var p in data['packages']) {
        packages.add(p);
      }
    }
  }
}

/**
 * Fetch packages.json file and return PubPackages
 */
Future<PackagePage> fetchPackagePage([int page]) {
  String uri = PACKAGES_DATA_URI + (page != null ? "?page=${page}":"");
  return http.get(uri).then((response) {
    if (response.statusCode != 200) {
      // Logger.root.warning("Not able to fetch packages: ${response.statusCode}:${response.body}");
      return null;
    }

    var data = JSON.decode(response.body);
    PackagePage pubPackages = new PackagePage.fromJson(data);
    return pubPackages;
  });
}

/**
 * Fetch all pages of packages.json file and return as `List` of
 * `PubPackages` objects.
 */
Future<List<PackagePage>> fetchAllPackagePages() {
  Completer completer = new Completer();
  List pubPackages = [];
  int pageCount = 1;

  void callback() {
    fetchPackagePage(pageCount).then((PackagePage p) {
      Logger.root.finest("pageCount = ${pageCount}");
      if (p.packages.length == 0) {
        completer.complete(pubPackages);
        return;
      }

      pageCount++;
      pubPackages.add(p);
      Timer.run(callback);
    });
  }

  Timer.run(callback);
  return completer.future;
}

/**
 * Fetch a particular `<package>.json` file and return `Package`
 */
Future<Package> fetchPackage(String packageJsonUri) {
  return http.get(packageJsonUri).then((response) {
    if (response.statusCode != 200) {
      // Logger.root.warning("Not able to fetch packages: ${response.statusCode}:${response.body}");
      return null;
    }

    var data = JSON.decode(response.body);
    Package package = new Package.fromJson(data);
    return package;
  });
}

/**
 * Fetches all the packages and puts them into `Package` objects
 */
Future<List<Package>> fetchAllPackages() {
  return fetchAllPackagePages().then((List<PackagePage> pubPackages) {
   Completer completer = new Completer();
   List<String> packagesUris = new List<String>();
   pubPackages.forEach((PackagePage pubPackages) =>
       packagesUris.addAll(pubPackages.packages));

   List<Package> packages = new List<Package>();
   void callback() {
     if (packagesUris.isEmpty) {
       completer.complete(packages);
       return;
     }

     print("fetching ${packagesUris.last}");
     fetchPackage(packagesUris.removeLast()).then((Package package) {
       packages.add(package);
       Timer.run(callback);
     });
   }

   Timer.run(callback);
   return completer.future;
  });
}

final String PACKAGES_DATA_URI = "http://pub.dartlang.org/packages.json";