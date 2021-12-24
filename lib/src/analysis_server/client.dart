// based on analysis_server_client example:
// https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_client/example/example.dart
import 'dart:async';
import 'dart:io';

import 'package:analysis_server_client/handler/connection_handler.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:path/path.dart' as p;

// TODO: make sure there's only one server during the life time of an application
// TODO: make sure the process of the analysis server is closed when the app exits
// TODO: figure out if we can tap into an existing server or if analysis_server_client already does it.
class AnalysisServerClient {
  final void Function(Object error) onServerError;
  late String targetDir;
  final server = Server();
  late _Handler handler;

  static Future<void> forceStop() async {
    if (_server != null) {
      await _server!.stop();
    }
  }

  static AnalysisServerClient? _server;

  // TODO: improve the pattern
  factory AnalysisServerClient(Directory directory, void Function(Object error) onServerError) {
    if (_server == null) {
      _server = AnalysisServerClient._(directory, onServerError);
    } else {
      // TODO:
      // _server.addErrorListener(onServerError)
    }
    return _server!;
  }

  AnalysisServerClient._(
    Directory directory,
    this.onServerError,
  ) {
    if (!directory.existsSync()) {
      throw Exception('Could not find directory $targetDir');
    }
    targetDir = p.normalize(p.absolute(directory.path));
    handler = _Handler(server);
  }

  Future<void> start({String? sdkPath, String? serverPath}) async {
    await server.start(sdkPath: sdkPath, serverPath: serverPath);
    server.listenToOutput(notificationProcessor: handler.handleEvent);
    if (!await handler.serverConnected(timeLimit: const Duration(seconds: 15))) {
      throw TimeoutException('could not connect to the server after 15 seconds');
    }
    await _startSubscription();
  }

  Future<void> _startSubscription() async {
    // Request analysis
    await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS, ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
    // logger.trace('setting subscription for rootTarget $_target');
    await server.send(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS, AnalysisSetAnalysisRootsParams([targetDir], const []).toJson());
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
    absNormPath(filePath);
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
    // remove any results from outside the directory
    return future.where((e) => e.location.file.startsWith(targetRootDir)).toList();
  }
}

String absNormPath(String path) {
  return p.normalize(p.absolute(path));
}
