import 'dart:async';

import 'package:analysis_server_client/protocol.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dfs/src/analysis_server/client.dart';

import 'dart:io';

// TODO: [flutter] create an exemption list: e.g. `generated_plugin_registrant.dart`
// TODO: [flutter] find a way to identify stubs (i.e. io vs html) and ignore them
// TODO: [both] ignore extensions (maybe check for the methods in them?)
class UnusedTopLevelFinder {
  final Logger logger;
  final Directory directory;
  final AnalysisServerClient server;

  UnusedTopLevelFinder({
    required this.directory,
    required this.logger,
    required this.server,
  });

  Future<List<SearchResult>> find() async {
    logger.trace('finding top level declarations');
    final topleveldeclaration = await server.handler.findTopLevel(targetRootDir: directory.path);
    // remove main() functions:
    // "kind":"FUNCTION","name":"main"
    logger.trace('removing main function');
    topleveldeclaration.removeWhere(
      (element) => element.path.any((element) => element.kind.name == "FUNCTION" && element.name == "main"),
    );

    final unusedTopLevel = <SearchResult>[];

    Future<void> addIfNoRef(SearchResult result) async {
      final references = await server.handler.findReferences(
        filePath: result.location.file,
        offset: result.location.offset,
      );

      if (references.isEmpty) {
        logger.trace('found unused reference: ${result.location.file}:${result.location.startLine}:${result.location.startColumn}');
        unusedTopLevel.add(result);
      }
    }

    logger.trace('finding references for the top level declarations');
    final futures = topleveldeclaration.map(addIfNoRef).toList();

    await Future.wait(futures).onError((error, stackTrace) {
     logger.stderr('error getting the results: $error');
      throw Exception('error getting the results');
    });

    return unusedTopLevel;
  }
}
