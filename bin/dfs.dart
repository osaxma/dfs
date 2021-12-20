import 'dart:io';

import 'package:dfs/dfs.dart' as dfs;

void main(List<String> arguments) async {
  try {
    await dfs.DFSCommandRunner().run(arguments);
  } catch (err) {
    stderr.writeln(err.toString());
    exitCode = 1;
  }
}
