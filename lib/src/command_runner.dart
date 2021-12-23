import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dfs/src/commands/find_unused_packages_command.dart';
import 'package:dfs/src/commands/find_unused_top_level_command.dart';

import 'version.dart';
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
    addCommand(FindUnusedTopLevelCommand());
  }

  @override
  Future<void> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      // ignore: avoid_print
      print(dfsVersion);
      return;
    }
    await super.runCommand(topLevelResults);
  }
}
