import 'package:dfs/src/common/path_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

const _dependenciesPackageNames = <String, String>{
  "test": "import 'package:test/scaffolding.dart';",
  "analyzer": "import 'package:analyzer/dart/ast/ast.dart';",
  "path": "import 'package:path/path.dart as p';",
  "dfs": "import 'package:dfs/src/common/path_utils.dart';",
  "f_1_2_3": "import 'package:f_1_2_3/src/common/path_utils.dart';",
  // TODO: add more edge cases
};

const _nonDependenciesPackageNames = <String>[
  "import 'dart:io';",
  "import 'dart:html';",
  "import '../common/path_utils.dart';",
  "import 'common.dart';",
  "import 'commands/generate_data_classes_command.dart';",
  // TODO: add more edge cases
];

void main() {
  group('get package name', () {
    test('- expect package name', () {
      final packageNames = _dependenciesPackageNames.values.map(extractPackageNameFromImportUri);
      final expectedPackageNames = _dependenciesPackageNames.keys;
      expect(packageNames, orderedEquals(expectedPackageNames));
    });

    test('- expect no package name', () {
      final packageNames = _nonDependenciesPackageNames.map(extractPackageNameFromImportUri);
      expect(packageNames, everyElement(null));
    });
  });
}
