class DFSException implements Exception {}

// TODO: change to File Not found
class FileNotFoundError implements DFSException {
  /// The path where the file was not found
  final String path;
  final String fileName;
  const FileNotFoundError({
    required this.path,
    required this.fileName,
  });

  @override
  String toString() {
    // TODO: implement toString
    return 'no `$fileName` files were found in this directory: $path';
  }
}

// TODO: change to Directory not found
class DirectoryNotFoundException implements DFSException {
  /// The path where the directory was not found
  final String path;

  const DirectoryNotFoundException({
    required this.path,
  });

  @override
  String toString() {
    // TODO: implement toString
    return 'The following directory does not exist: $path';
  }
}
