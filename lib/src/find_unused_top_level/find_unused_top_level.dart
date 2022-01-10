import 'dart:async';

import 'package:analysis_server_client/protocol.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dfs/src/analysis_server/client.dart';

import 'dart:io';

const _kTimeLimit = Duration(minutes: 1);

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
    final topleveldeclaration = await server.handler
        .findTopLevel(targetRootDir: directory.path, timeLimit: _kTimeLimit);
    print('found ${topleveldeclaration.length} top level declarations');

    // remove main() functions:
    // "kind":"FUNCTION","name":"main"
    topleveldeclaration.removeWhere(
      (element) => element.path.any((element) =>
          element.kind.name == "FUNCTION" && element.name == "main"),
    );

    final futures = topleveldeclaration.map(_collectNoRef);

    final results = await Future.wait(futures).onError((error, stackTrace) {
      print('error getting the results $error');
      throw Exception('error getting the results');
    });

    return results.flattened;
  }

  Future<List<SearchResult>> _collectNoRef(SearchResult result) async {
    final references = await server.handler.findReferences(
      filePath: result.location.file,
      offset: result.location.offset,
      timeLimit: _kTimeLimit,
    );

    final unusedTopLevel = <SearchResult>[];

    if (references.isEmpty) {
      unusedTopLevel.add(result);
    }

    return unusedTopLevel;
  }
}

extension _ListListExtensions<T> on List<List<T>> {
  List<T> get flattened => fold([], (a, b) => [...a, ...b]);
}
