// based on analysis_server_client example:
// https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_client/example/example.dart
import 'dart:async';
import 'dart:io';

import 'package:analysis_server_client/handler/connection_handler.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

// TODO: make sure there's only one server during the life time of an application
// TODO: make sure the process of the analysis server is closed when the app exits
// TODO: figure out if we can tap into an existing server or if analysis_server_client already does it.
// TODO: provide the correct dartBinary to support executable (see: https://github.com/dart-lang/sdk/pull/48016)
class AnalysisServerClient {
  final void Function(Object error) onServerError;
  late String targetDir;
  final server = Server();
  late _Handler handler;
  final Logger logger;

  static Future<void> forceStop() async {
    if (_server != null) {
      await _server!.stop();
    }
  }

  static AnalysisServerClient? _server;

  // TODO: improve the pattern
  factory AnalysisServerClient(Directory directory, void Function(Object error) onServerError, Logger logger) {
    if (_server == null) {
      _server = AnalysisServerClient._(directory, onServerError, logger);
    } else {
      // TODO:
      // _server.addErrorListener(onServerError)
    }
    return _server!;
  }

  AnalysisServerClient._(
    Directory directory,
    this.onServerError,
    this.logger,
  ) {
    if (!directory.existsSync()) {
      throw Exception('Could not find directory $targetDir');
    }
    targetDir = p.normalize(p.absolute(directory.path));
    handler = _Handler(server);
  }

  Future<void> start({String? sdkPath, String? serverPath}) async {
    logger.trace('starting the server and the dart sdk path is: ${Platform.executable}');
    // this will throw if the server has already started
    await server.start(sdkPath: sdkPath, serverPath: serverPath);
    logger.trace('start listening to the server');
    server.listenToOutput(notificationProcessor: handler.handleEvent);
    if (!await handler.serverConnected(timeLimit: const Duration(seconds: 15))) {
      logger.stderr('could not connect to the server after 15 seconds');
      throw TimeoutException('could not connect to the server after 15 seconds');
    }
    logger.trace('starting subscriptions');
    await _startSubscription();
  }

  Future<void> _startSubscription() async {
    await server.send(
      SERVER_REQUEST_SET_SUBSCRIPTIONS,
      ServerSetSubscriptionsParams([ServerService.STATUS]).toJson(),
    );

    await server.send(
      ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
      AnalysisSetAnalysisRootsParams(
        [targetDir], // included: this seems the only to specify the root directory.
        [targetDir], // excluded: we are not interested in analysis errors so exclude all files from being analyzed.
      ).toJson(),
    );
  }

  Future<int> stop() async {
    return server.stop();
  }
}

/// handle server notifications and connection
class _Handler with NotificationHandler, ConnectionHandler {
  @override
  final Server server;
  int errorCount = 0;

  _Handler(this.server);

  @override
  void onFailedToConnect() {
    print('Failed to connect to server');
  }

  @override
  void onProtocolNotSupported(Object version) {
    print('Expected protocol version $PROTOCOL_VERSION, but found $version');
  }

  @override
  void onServerError(ServerErrorParams params) {
    if (params.isFatal) {
      print('Fatal Server Error: ${params.message}');
    } else {
      print('Server Error: ${params.message}');
    }
    print(params.stackTrace);
    super.onServerError(params);
  }

  /// map of search result request id and search results listeners and
  final _searchResultsCompleter = <String, Completer<List<SearchResult>>>{};
  final _searchResults = <SearchResultsParams>[];

  @override
  void onSearchResults(SearchResultsParams params) {
    if (params.isLast) {
      final completer = _searchResultsCompleter.remove(params.id);
      if (completer != null) {
        final results = [
          ..._searchResults.where((element) => element.id == params.id),
          params,
        ].map((e) => e.results).expand((element) => element).toList();
        completer.complete(results);
        // remove results that we held for this search id.
        _searchResults.removeWhere((search) => search.id == params.id);
      }
    } else {
      _searchResults.add(params);
    }
  }

  Future<List<SearchResult>> findReferences({
    required String filePath,
    required int offset,
    // True if potential matches are to be included in the results.
    bool includePotential = true,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    final params = SearchFindElementReferencesParams(filePath, offset, includePotential).toJson();
    final response = await server.send(SEARCH_REQUEST_FIND_ELEMENT_REFERENCES, params).timeout(
      timeLimit,
      onTimeout: () {
        throw TimeoutException('did not receive confirmation from server after ${timeLimit.inSeconds}-seconds');
      },
    );
    // TODO: check for null
    final id = response!['id'] as String;
    final completer = Completer<List<SearchResult>>();
    _searchResultsCompleter[id] = completer;

    return completer.future.timeout(
      timeLimit,
      onTimeout: () {
        _searchResultsCompleter.remove(id);
        throw TimeoutException('did not receive search results after ${timeLimit.inSeconds}-seconds');
      },
    );
  }

  Future<List<SearchResult>> findTopLevel({
    required String targetRootDir,
    Duration timeLimit = const Duration(seconds: 15),
    List<String> ignoredFiles = const [],
  }) async {
    // This will return results even from outside the directory (packages in .pub_cache)... n
    // not sure how to scope the results to the root directory only..
    final params = SearchFindTopLevelDeclarationsParams('.').toJson();
    final response = await server.send(SEARCH_REQUEST_FIND_TOP_LEVEL_DECLARATIONS, params).timeout(
      timeLimit,
      onTimeout: () {
        throw TimeoutException('did not receive confirmation from server after ${timeLimit.inSeconds}-seconds');
      },
    );
    // TODO: check for null
    final id = response!['id'] as String;
    final completer = Completer<List<SearchResult>>();
    _searchResultsCompleter[id] = completer;

    final future = await completer.future.timeout(
      timeLimit,
      onTimeout: () {
        _searchResultsCompleter.remove(id);
        throw TimeoutException('did not receive search results after ${timeLimit.inSeconds}-seconds');
      },
    );
    return removeIgnoredFiles(future, targetRootDir, ignoredFiles);
  }
}

List<SearchResult> removeIgnoredFiles(List<SearchResult> result, String targetRootDir, List<String> ignoredFiles) {
  // first remove anything outside the target directory (e.g. this is out of our control)
  // follow discussion here: https://groups.google.com/a/dartlang.org/g/analyzer-discuss/c/WgprMl00A18/m/nV12NwZVBgAJ
  result.removeWhere((e) => !e.location.file.startsWith(targetRootDir));
  if (ignoredFiles.isEmpty) {
    return result;
  }

  final globs = ignoredFiles.map((e) => Glob(e));

  result.removeWhere((res) => globs.any((glob) => glob.matches(p.relative(res.location.file, from: targetRootDir))));

  return result;
}

String absNormPath(String path) {
  return p.normalize(p.absolute(path));
}
