import 'dart:io';
import 'package:path/path.dart' as p;

import 'exceptions.dart';

// TODO: generalize the funtions here:
// - find file(s) by name      (2)
// - find file(s) by extension (2)
// - find directory by name    (1)

/// Get all dart files from the lib directory
Future<List<File>> getAllDartFilesFromLibDirectory(Directory targetDirectory) async {
  final lister = targetDirectory.list(recursive: false);
  late final Directory libDirectory;
  try {
    libDirectory = await lister.where((f) => f is Directory).firstWhere((element) => p.basename(element.path) == 'lib')
        as Directory;
  } on StateError {
    throw LibFolderNotFoundException(targetDirectory.path);
  } catch (e) {
    rethrow;
  }

  return libDirectory
      .listSync(recursive: true)
      .whereType<File>()
      .where((element) => p.extension(element.path) == '.dart')
      .toList();
}

/// Get the pubspec file from a given directory
Future<File> getPubspecYamlFile(Directory directory) async {
  final lister = directory.list(recursive: false);
  try {
    final file =
        await lister.where((f) => f is File).firstWhere((element) => p.basename(element.path) == 'pubspec.yaml');
    return file as File;
  } on StateError {
    throw PubSpecYamlNotFoundError(directory.path);
  } catch (e) {
    rethrow;
  }
}
