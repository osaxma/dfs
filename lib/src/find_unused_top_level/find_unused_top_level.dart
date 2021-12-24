import 'dart:async';

import 'package:analysis_server_client/protocol.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dfs/src/analysis_server/client.dart';
import 'package:path/path.dart' as p;

import 'dart:io';

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
    // "kind":"FUNCTION","name":"main"
    final topleveldeclaration = await server.handler.findTopLevel(targetRootDir: directory.path);
    // remove main() functions 
    topleveldeclaration.removeWhere(
        (element) => element.path.any((element) => element.kind.name == "FUNCTION" && element.name == "main"));
    final unusedTopLevel = <SearchResult>[];
    Future<void> addIfNoRef(SearchResult result) async {
      final references = await server.handler.findReferences(
        filePath: result.location.file,
        offset: result.location.offset,
      );

      if (references.isEmpty) {
        unusedTopLevel.add(result);
      }
    }

    final futures = topleveldeclaration.map(addIfNoRef).toList();

    await Future.wait(futures).onError((error, stackTrace) {
      print('error getting the results');
      throw Exception('error getting the results');
    });
    
    return unusedTopLevel;
  }
}