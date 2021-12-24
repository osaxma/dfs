import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dfs/src/common/ast_utils.dart';
import 'package:dfs/src/common/io_utils.dart';
import 'package:dfs/src/common/path_utils.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

class UnusedPackagesFinder {
  final Logger logger;
  final Directory directory;

  UnusedPackagesFinder({
    required this.directory,
    required this.logger,
  });

  final dartFilesInLibFolder = <File>[];
  final dependencies = <String>[];

  Future<List<String>> find() async {
    final file = await getPubspecYamlFile(directory);
    logger.trace('reading pubspec.yaml');
    getPackagesFromPubSpecYaml(file.readAsStringSync());

    logger.trace('finding all the dart files');
    await getAllPackagesInDartFilesFromLibFolder(directory);

    logger.trace('found the following dart files:');
    dartFilesInLibFolder.forEach((f) => logger.trace(p.relative(f.path, from: directory.path)));
    logger.trace('found the following dependencies:');
    logger.trace(dependencies.reduce((value, element) => value + ' | ' + element));

    final importedPackages = _CollectImportsVisitor.getAllPackages(dartFilesInLibFolder, logger);
    logger.trace('the following are the imported packages');
    importedPackages.forEach(logger.trace);
    logger.trace(importedPackages.reduce((value, element) => value + ' | ' + element));

    final unusedPackages = _findUnusedPackages(importedPackages);
    logger.trace('the following are the unused packages');
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
    final dartFiles = await findAllDartFiles(directory);
    dartFilesInLibFolder.addAll(dartFiles);
  }
}

class _CollectImportsVisitor extends RecursiveAstVisitor {
  final imports = <String>[];
  final Logger logger;
  _CollectImportsVisitor(this.logger);

  static List<String> getAllPackages(List<File> files, Logger logger) {
    // TODO: look how build_runner does it (trace thru Freezed or GQL)
    //       does it read file by file, or load all files?
    final visitor = _CollectImportsVisitor(logger);
    for (var file in files) {
      logger.trace('--> reading ${p.basename(file.path)}');
      final ast = generateASTfromFile(file);
      // TODO: change to visit children and I think we won't need `CollectImportsVisitor` to be `RecursiveAstVisitor`
      ast.accept(visitor);
    }
    return visitor.imports.toSet().toList();
  }

  @override
  visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    logger.trace('IMPORT URI = ${node.uri.stringValue}');
    if (uri != null) {
      final packageName = extractPackageNameFromImportUri(uri);
      if (packageName != null) {
        imports.add(packageName);
        logger.trace('------> found: $packageName package');
      }
    }
    return super.visitImportDirective(node);
  }
}
