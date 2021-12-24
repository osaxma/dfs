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
    // the server is a separate process and we need to make sure it's stopped when the application exits. 
    // TODO: find if this is most reliable way to kill the process 
    //       (e.g. what if one used this as a package or with a different etnry point?)
    AnalysisServerClient.forceStop();
  }
}
