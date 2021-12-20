import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dfs/src/common/ast_utils.dart';
import 'package:dfs/src/common/io_utils.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

class UnusedPackagesFinder {
  final Logger logger;
  final Directory directory;
  UnusedPackagesFinder(this.directory, this.logger);

  final dartFilesInLibFolder = <File>[];
  final dependencies = <String>[];

  Future<List<String>> findUnusedPackages() async {
    final file = await getPubspecYamlFile(directory);
    logger.trace('reading pubspec.yaml');
    getPackagesFromPubSpecYaml(file.readAsStringSync());

    logger.trace('finding all the dart files');
    await getAllPackagesInDartFilesFromLibFolder(directory);

    logger.trace('found the following dart files:');
    dartFilesInLibFolder.forEach((f) => logger.trace(p.relative(f.path)));
    logger.trace('found the following dependencies:');
    logger.trace(dependencies.reduce((value, element) => value + ' | ' + element));

    final importedPackages = CollectImportsVisitor.getAllPackages(dartFilesInLibFolder, logger);
    logger.trace('the following are the imported packages');
    importedPackages.forEach(logger.trace);
    final unusedPackages = _findUnusedPackages(importedPackages);
    unusedPackages.forEach((val) => logger.trace(' - $val'));
    return unusedPackages;
  }

  List<String> _findUnusedPackages(List<String> importedPackages) {
    final unusedPackages = <String>[];
    for (var dep in dependencies) {
      if (importedPackages.contains(dep)) {
        continue;
      } else {
        unusedPackages.add(dep);
      }
    }
    return unusedPackages;
  }

  void getPackagesFromPubSpecYaml(String yaml) {
    final parsedPubSpec = Pubspec.parse(yaml);
    dependencies.addAll(parsedPubSpec.dependencies.keys);
  }

  Future<void> getAllPackagesInDartFilesFromLibFolder(Directory directory) async {
    final dartFiles = await getAllDartFilesFromLibDirectory(directory);
    dartFilesInLibFolder.addAll(dartFiles);
  }
}

class CollectImportsVisitor extends RecursiveAstVisitor {
  final imports = <String>[];
  final Logger logger;
  CollectImportsVisitor(this.logger);

  static List<String> getAllPackages(List<File> files, Logger logger) {
    // TODO: look how build_runner does it (trace thru Freezed or GQL)
    //       does it read file by file, or load all files?
    final visitor = CollectImportsVisitor(logger);
    for (var file in files) {
      logger.trace('reading ${p.relative(file.path)}');
      final ast = generateASTfromFile(file);
      ast.accept(visitor);
    }
    return visitor.imports;
  }

  @override
  visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri != null) {
      final packageName = getPackageName(uri);
      if (packageName != null) {
        imports.add(packageName);
        logger.trace('found import for package name: $packageName');
      }
    }
    return super.visitImportDirective(node);
  }

  String? getPackageName(String string) {
    final match = packageCapture.firstMatch(string);
    try {
      return match?.group(0)?.split(':')[1];
    } catch (e) {
      logger.trace('failed to parse package name: $string}. Received the following error $e');
      return null;
    }
  }
}

// finds `package:package_name_123`
final packageCapture = RegExp(r'package:\w+(?=\/)');
