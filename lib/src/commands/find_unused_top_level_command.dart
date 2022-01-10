import 'dart:async';
import 'dart:io';

import 'package:dfs/src/analysis_server/client.dart';
import 'package:dfs/src/find_unused_top_level/find_unused_top_level.dart';

import 'base.dart';

const _kIgnoredFilesGlobsByDefault = [
  '.dart_tools/**',
  'lib/**.g.dart',
  'lib/**.freezed.dart',
  '**/genl10n/*.dart',
  'lib/generated_plugin_registrant.dart',
];

class FindUnusedTopLevelCommand extends DFSCommand {
  FindUnusedTopLevelCommand() {
    argParser.addOption(
      'timelimit',
      abbr: 't',
      defaultsTo: '1',
      help: 'Specify a timeout in minutes (note: for large projects with many packges, the command can take sometime)',
    );
    argParser.addMultiOption(
      'ignore',
      valueHelp: 'glob',
      help: 'Exclude files with names matching the given glob. This option can be repeated.'
              '\nThe following are ignored by default:\n"' +
          _kIgnoredFilesGlobsByDefault.reduce((value, element) => value + '"' + ',' + '"' + element) +
          '"\npass your globs to override',
    );

    // dart run bin/dfs.dart futl --ignore="lib/**.g.dart","lib/**.freezed.dart","**/genl10n/*.dart"
  }

  @override
  final String description = '''Find Unused Top Level Declarations within a project
  
Examples: 
  # ignore specific globs (make sure no spaces between the comma separated values or the equal sign)
  dfs find-unused-top-level --ignore="lib/**.g.dart","lib/**.freezed.dart","**/genl10n/*.dart"

  # specify a timeout limit and ignore generated files:
  dfs find-unused-top-level -t 10 --ignore="lib/**.g.dart"
  ''';

  @override
  final String name = 'find-unused-top-level';

  @override
  final List<String> aliases = ['futl'];

  @override
  // final String description = 'Find unused top level declarations within a dart or flutter projects';

  @override
  FutureOr<void>? run() async {
    final ignoreArgResult = argResults!['ignore'] as List<String>? ?? const [];
    final ignoredFiles = ignoreArgResult.isEmpty ? _kIgnoredFilesGlobsByDefault : ignoreArgResult;
    logger.trace('ignoring the following globs: $ignoredFiles');

    final timelimit = int.tryParse(argResults!['timelimit']);

    logger.trace('timelimit = $timelimit-min');

    final directory = Directory.current;
    logger.stdout('listening in directory $directory');

    final server = AnalysisServerClient(directory, (e) {
      logger.stderr('listening to server errors: $e');
    }, logger);

    await server.start();

    final watch = Stopwatch()..start();
    final unusedTopLevel = await UnusedTopLevelFinder(
      directory: directory,
      logger: logger,
      server: server,
      ignoredFiles: ignoredFiles,
      timeLimit: timelimit != null ? Duration(minutes: timelimit) : null,
    ).find();

    logger.trace('finding unused top level declaration took ${watch.elapsed.inMilliseconds}-ms');
    if (unusedTopLevel.isEmpty) {
      logger.stdout('All top level declarations are in use!');
    } else {
      logger.stdout('The following top level declarations are not used anywhere:');
      unusedTopLevel.forEach((unused) {
        logger.stdout(' - ${unused.location.file}:${unused.location.startLine}:${unused.location.startColumn}');
      });
    }
  }
}
