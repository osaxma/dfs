import 'dart:async';
import 'dart:io';

import 'package:dfs/src/find_unused_packages/find_unused_packages.dart';

import 'base.dart';

class FindUnusedPackagesCommand extends DFSCommand {
  FindUnusedPackagesCommand();

  @override
  final String name = 'find-unused-packages';

  @override
  final List<String> aliases = ['fup'];

  @override
  final String description =
      'Find unused packages within a dart or flutter projects (only those used in lib and defined under dependencies)';

  @override
  FutureOr<void>? run() async {
    // ignore: unused_local_variable
    final unusedPackages = await UnusedPackagesFinder(
      directory: Directory.current,
      logger: logger,
    ).find();

    logger.stdout('The following packages are not used anywhere in the lib directory:');
    unusedPackages.forEach((element) {
      logger.stdout('   - $element');
    });
    logger.stdout('\nIf they are used, elsewhere (e.g. /test), consider moving them to `dev_dependencies` in `pubspec.yaml`');
  }
}
