import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:dfs/src/generate_data_classes/generate_data_classes.dart';

import 'base.dart';

class GenerateDataClassesCommand extends DFSCommand {
  GenerateDataClassesCommand();

  @override
  final String name = 'generate-data-classes';

  @override
  final List<String> aliases = ['gdc'];

  @override
  final String description = 'Generate Data Classes for specified directory where file name ends with `_data.dart';

  @override
  FutureOr<void>? run() async {
    // ignore: unused_local_variable
    final results = await DataClassGenerator(
      directory: Directory.current,
      logger: logger,
    ).generate();

    if (results.succeeded.isNotEmpty) {
      logger.stdout('Data classes were generated for the following files:');
      results.succeeded.forEach((element) {
        logger.stdout('   - ${p.basename(element.path)}');
      });
    } else {
      logger.stdout('No data classes were generated');
    }

    if (results.failed.isNotEmpty) {
      // TODO: test this
      logger.stdout('Something went wrong with these files:');
      for (var i = 0; i < results.failed.length; i++) {
        logger.stdout('   - file: ${p.basename(results.failed[i].path)}');
        logger.stdout('   - file: ${results.errors[i]}');
      }
      results.failed.forEach((element) {});
    }
  }
}
