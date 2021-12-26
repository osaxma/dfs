import 'dart:io';
import 'package:path/path.dart' as p;

import 'exceptions.dart';

/// Get the correct SDK path
///
/// Note:
/// `Platform.executable` or `Platform.resolvedExecutable` returns the path of the executable, not dart-sdk.
/// They'll only return the `dart-sdk` path when running an app using `dart run`.
///
/// On the other hand, when compiling an app to an executable (e.g. dfs.exe), they'll return the `dfs.exe` path.
/// The same applies to `getSdkPath` from `cli_util` package.
///
/// To get the correct path, $PATH form the OS environment vairables will be used to find the dart-sdk.
/// dart-sdk/bin/dart
String findSdkPath() {
  final env = Platform.environment;
  if (Platform.resolvedExecutable.contains('dart-sdk')) {
    return p.normalize(Platform.resolvedExecutable);
  }
  // TODO: make sure the key `PATH` the same in Linux, Windows, and Mac.
  final osPath = env['PATH'];

  try {
    // TODO: make sure the split pattern is the same in Linux (:), Windows (;)?, and Mac (:).
    // get the first dart-sdk in path ()
    final sdkPath = p.join(osPath!.split(':').firstWhere((element) => element.contains('dart-sdk')), 'dart');
    return sdkPath;
  } catch (e) {
    throw DartSdkNotFoundException();
  }
}

// This will look for dart-sdk/bin/dart/analysis_server.dart.snapshot
// In command line it'll be:
// `dart analysis_server.dart.snapshot [arguments]`
// This is similar to calling:
// `dart language-server --protocol=analyzer [arguments]` (lsp is default for `language-server`)
//
// TODO: what if `analysis_server.dart.snapshot` does not exist?
String getServerPath() {
  final sdkPath = findSdkPath();
  // see: sdk/pkg/analysis_server_client/lib/server.dart
  // Look for snapshots/analysis_server.dart.snapshot.
  String possiblePath = p.normalize(p.join(p.dirname(sdkPath), 'snapshots', 'analysis_server.dart.snapshot'));
  if (!FileSystemEntity.isFileSync(possiblePath)) {
    // Look for dart-sdk/bin/snapshots/analysis_server.dart.snapshot.
    possiblePath =
        p.normalize(p.join(p.dirname(sdkPath), 'dart-sdk', 'bin', 'snapshots', 'analysis_server.dart.snapshot'));
  }
  return possiblePath;
}

class DartSdkNotFoundException implements Exception {
  DartSdkNotFoundException();

  @override
  String toString() {
    return 'could not find dart-sdk on path';
  }
}

// TODO: generalize the funtions here:
// - find file(s) by name      (2)
// - find file(s) by extension (2)
// - find directory by name    (1)

/// Get all dart files from the lib directory
Future<List<File>> findAllDartFiles(
  Directory targetDirectory, {
  String? endsWith,
}) async {
  if (!targetDirectory.existsSync()) {
    throw DirectoryNotFoundException(
      path: targetDirectory.path,
    );
  }

  return targetDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((element) => p.extension(element.path) == '.dart')
      .where((element) => endsWith == null ? true : element.path.endsWith(endsWith))
      .toList();
}

/// Get the pubspec file from a given directory
Future<File> getPubspecYamlFile(Directory directory) async {
  return getFileByName(directory, 'pubspec.yaml');
}

/// Get a file by name from a given directory
///
/// This will use the basename to search as defined in [p.basename]
Future<File> getFileByName(Directory directory, String fileName) async {
  final lister = directory.list(recursive: false);
  try {
    final file = await lister.where((f) => f is File).firstWhere((element) => p.basename(element.path) == fileName);
    return file as File;
  } on StateError {
    throw FileNotFoundError(path: directory.path, fileName: fileName);
  } catch (e) {
    rethrow;
  }
}
