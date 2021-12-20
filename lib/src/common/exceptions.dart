class DFSException implements Exception {}

// TODO: change to File Not found
class PubSpecYamlNotFoundError implements DFSException {
  final String directoryPath;
  const PubSpecYamlNotFoundError(this.directoryPath);

  @override
  String toString() {
    // TODO: implement toString
    return 'no pubspec.yaml files were found in this directory: $directoryPath';
  }
}


// TODO: change to Directory not found
class LibFolderNotFoundException implements DFSException {
  final String directoryPath;
  const LibFolderNotFoundException(this.directoryPath);

  @override
  String toString() {
    // TODO: implement toString
    return 'no lib folder was found in this directory: $directoryPath';
  }
}
