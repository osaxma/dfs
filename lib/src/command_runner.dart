import 'package:args/command_runner.dart';
import 'package:dfs/src/commands/find_unused_packages_command.dart';

import 'commands/generate_data_classes_command.dart';
// TBH: the structure here resembles [melos pacakge](https://github.com/invertase/melos)

class DFSCommandRunner extends CommandRunner<void> {
  // TODO
  final Object? config;

  DFSCommandRunner([this.config])
      : super(
          'dfs',
          'dfs - dart and flutter scripts',
        ) {
    argParser.addFlag(
      'verbose',
      negatable: false,
      help: 'Enable verbose logging.',
    );
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current Melos version.',
    );

    addCommand(FindUnusedPackagesCommand());
    addCommand(GenerateDataClassesCommand());
  }

  // Future<void> run(List<String> arguments) async {}

  // void _setupUpParser() {
  //   argParser
  //     ..addFlag('help', abbr: 'h', help: 'print the usage', negatable: false)
  //     ..addOption('source', abbr: 's', help: 'the source graphql file')
  //     ..addOption('output', abbr: 'o', help: 'the output path')
  //     ..addFlag('keep', abbr: 'k', help: 'keep the old file (no by default)')
  //     ..addFlag('format', abbr: 'f', help: 'format the ouput file using `dart format`');
  // }
}
