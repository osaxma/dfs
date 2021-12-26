import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;

import 'package:dfs/src/generate_data_classes/generate_data_classes.dart';

import 'base.dart';

// TODO: consider changing this to `Convert` since we are doing this in place.
class GenerateDataClassesCommand extends DFSCommand {
  GenerateDataClassesCommand() {
    argParser.addOption(
      'directory',
      abbr: 'd',
      defaultsTo: 'lib',
      help: 'Choose a specific directory (relative to the project root) to generate data classes from',
    );

    argParser.addOption(
      'endsWith',
      abbr: 'e',
      defaultsTo: '_data.dart',
      help: 'Choose a specific file name ending to generate data classes from',
    );

    argParser.addFlag(
      'serialization',
      abbr: 's',
      defaultsTo: true,
      help: 'Include serialization -- (flag is not effective yet)',
    );

    argParser.addFlag(
      'copyWith',
      abbr: 'c',
      defaultsTo: true,
      help: 'Include copyWith -- (flag is not effective yet)',
    );

    argParser.addFlag(
      'yes',
      abbr: 'y',
      defaultsTo: false,
      help: 'answer yes to any prompts (e.g. checking uncommited changes, etc.)',
    );

    argParser.addFlag(
      'keep',
      abbr: 'k',
      defaultsTo: false,
      help: 'keep the old file (it will be modified to filename.old.dart) -- (flag is not effective yet)',
    );

    // for debugging purposes
    argParser.addFlag(
      'separate',
      abbr: 'g',
      defaultsTo: false,
      hide: true,
      help: 'generate the data class in a separate file with `g.dart` ending',
    );
  }

  @override
  String get usage => super.usage;

  @override
  String? get usageFooter => super.usageFooter;

  @override
  final String name = 'generate-data-classes';

  @override
  final List<String> aliases = ['gdc'];

  @override
  final String description = '''Generate Data Classes for a specific directory and specific file name ending
  
Examples: 
  # generate data classes in the lib/src/data folder
  dfs gdc -d lib/src/data
  ''';

  @override
  FutureOr<void>? run() async {
    final yes = argResults!['yes'] as bool;
    if (!yes && !await shouldContinue(Directory.current)) {
      return;
    }
    final dataClassesDirectory = argResults!['directory'] as String;
    final fileEndings = argResults!['endsWith'] as String;

    final results = await DataClassGenerator(
      targetDirectory: Directory(p.join(Directory.current.path, dataClassesDirectory)),
      logger: logger,
      filesEndsWith: fileEndings,
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
      results.failed.forEach((element) {
        logger.stdout('   - ${p.basename(element.path)}');
      });
    }
  }
}

Future<bool> shouldContinue(Directory dir) async {
  // check if it's a git repo
  final isGit = await isGitDir(dir);

  if (!isGit) {
    return askUserToIfTheyWantToContinue(
        message: "WARNING: This does not look like a git repoistory. Are you sure you want to continue?");
  }

  // check if there are uncommited changes
  if (!await hasUncomittedChanges(dir)) {
    return true;
  } else {
    return askUserToIfTheyWantToContinue(
        message: "WARNING: You have uncommmited changes in this repository. Are you sure you want to continue?");
  }
}

Future<bool> isGitDir(Directory dir) async {
  return await GitDir.isGitDir(dir.path);
}

Future<bool> hasUncomittedChanges(Directory dir) async {
  final gitDir = await GitDir.fromExisting(dir.path);
  final changes = await gitDir.runCommand(['status', '--porcelain']);
  final hasChanges = (changes.stdout as String).trim().isNotEmpty;
  return hasChanges;
}

bool askUserToIfTheyWantToContinue({required String message, bool defaultsTo = false}) {
  final options = defaultsTo ? '[Yn]' : '[yN]';
  stdout.write('$message $options: ');
  var input = stdin.readLineSync(encoding: utf8);
  input ??= defaultsTo ? 'y' : 'n';
  return input.toLowerCase().trim() == 'y' ? true : false;
}
