// input: `import 'package:package_name_123/src/something.dart'`
// output: `package:package_name_123`
final _packageNameRegExp = RegExp(r'package:\w+(?=\/)');

/// This is meant to extract the package name from import uri
/// if, and only if, the string `package:` exists in the uri.
String? extractPackageNameFromImportUri(String string) {
  final match = _packageNameRegExp.firstMatch(string);
  if (match == null) return null;
  return match.group(0)?.split(':').last;
}
