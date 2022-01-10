import 'dart:async';
import 'dart:io';

import 'package:dfs/src/analysis_server/client.dart';
import 'package:dfs/src/find_unused_top_level/find_unused_top_level.dart';

import 'base.dart';

class FindUnusedTopLevelCommand extends DFSCommand {
  FindUnusedTopLevelCommand();

  @override
  final String name = 'find-unused-top-level';

  @override
  final List<String> aliases = ['futl'];

  @override
  final String description = 'Find unused top level declarations within a dart or flutter projects';

  @override
  FutureOr<void>? run() async {
    print('listening in directory ${Directory.current}');
    final server = AnalysisServerClient(Directory.current, (e) {
      print('listening to server errors: $e');
    });
    await server.start();
    final progress = logger.progress('finding unused top level declarations');
    // ignore: unused_local_variable
    final unusedTopLevel = await UnusedTopLevelFinder(
            directory: Directory.current, logger: logger, server: server)
        .find();
    progress.cancel();
    logger.trace('finding unused top level declaration took ${progress.elapsed.inMilliseconds}-ms ');
    logger.stdout('The following top level declarations are not used anywhere ');
    unusedTopLevel.forEach((unused) {
      logger.stdout(' - ${unused.location.file}:${unused.location.startLine}:${unused.location.startColumn}');
    });
  }
}
