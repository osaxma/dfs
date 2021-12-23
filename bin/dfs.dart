import 'dart:io';

import 'package:dfs/dfs.dart' as dfs;
import 'package:dfs/src/analysis_server/client.dart';

void main(List<String> arguments) async {
  try {
    await dfs.DFSCommandRunner().run(arguments);
  } catch (err) {
    stderr.writeln(err.toString());
    exitCode = 1;
  } finally {
    AnalysisServerClient.forceStop();
  }
}
