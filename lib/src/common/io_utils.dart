import 'dart:io';
import 'package:path/path.dart' as p;

import 'exceptions.dart';

// TODO: generalize the funtions here:
// - find file(s) by name      (2)
// - find file(s) by extension (2)
// - find directory by name    (1)

/// Get all dart files from the lib directory
Future<List<File>> findAllDartFiles(
  Directory targetDirectory, {
  String subDirectory = 'lib',
  String? endsWith,
}) async {
  final lister = targetDirectory.list(recursive: false);
  late final Directory libDirectory;
  try {
    libDirectory = await lister
        .where((f) => f is Directory)
        .firstWhere((element) => p.basename(element.path) == subDirectory) as Directory;
  } on StateError {
    throw DirectoryNotFoundException(
      path: targetDirectory.path,
      notFoundDirectory: subDirectory,
    );
  } catch (e) {
    rethrow;
  }

  return libDirectory
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
    final file =
        await lister.where((f) => f is File).firstWhere((element) => p.basename(element.path) == fileName);
    return file as File;
  } on StateError {
    throw FileNotFoundError(path: directory.path, fileName: fileName);
  } catch (e) {
    rethrow;
  }
}
