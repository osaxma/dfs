import 'dart:io';

import 'package:cli_util/cli_util.dart';
import 'package:dfs/dfs.dart' as dfs;
import 'package:dfs/src/analysis_server/client.dart';
import 'package:dfs/src/common/io_utils.dart';

void main(List<String> arguments) async {
  print('executable ${Platform.executable}');
  print('resolvedExecutable ${Platform.resolvedExecutable}');
  print('resolvedExecutable ${getSdkPath()}');
  print('findSdkPath: ${findSdkPath()}');
  try {
    await dfs.DFSCommandRunner().run(arguments);
  } catch (err) {
    stderr.writeln(err.toString());
    exitCode = 1;
  } finally {
    print('existing...');
    // the server is a separate process and we need to make sure it's stopped when the application exits.
    // TODO: find if this is most reliable way to kill the process
    //       (e.g. what if one used this as a package or with a different etnry point?)
    AnalysisServerClient.forceStop();
  }
}
