import 'package:analysis_server_client/server.dart';

class ServerCustom extends Server {
  // TODO: implement start where we supply dartBinary.
  @override
  Future start(
      {String? clientId,
      String? clientVersion,
      int? diagnosticPort,
      String? instrumentationLogFile,
      bool profileServer = false,
      String? sdkPath,
      String? serverPath,
      int? servicesPort,
      bool suppressAnalytics = true,
      bool useAnalysisHighlight2 = false,
      bool enableAsserts = false}) async {
    // if (_process != null) {
    //   throw Exception('Process already started');
    // }
    // var dartBinary = Platform.executable;

    // // The integration tests run 3x faster when run from snapshots
    // // (you need to run test.py with --use-sdk).
    // if (serverPath == null) {
    //   // Look for snapshots/analysis_server.dart.snapshot.
    //   serverPath = normalize(join(dirname(Platform.resolvedExecutable), 'snapshots', 'analysis_server.dart.snapshot'));

    //   if (!FileSystemEntity.isFileSync(serverPath)) {
    //     // Look for dart-sdk/bin/snapshots/analysis_server.dart.snapshot.
    //     serverPath = normalize(join(
    //         dirname(Platform.resolvedExecutable), 'dart-sdk', 'bin', 'snapshots', 'analysis_server.dart.snapshot'));
    //   }
    // }

    // var arguments = <String>[];
    // //
    // // Add VM arguments.
    // //
    // if (profileServer) {
    //   if (servicesPort == null) {
    //     arguments.add('--observe');
    //   } else {
    //     arguments.add('--observe=$servicesPort');
    //   }
    //   arguments.add('--pause-isolates-on-exit');
    // } else if (servicesPort != null) {
    //   arguments.add('--enable-vm-service=$servicesPort');
    // }
    // if (Platform.packageConfig != null) {
    //   arguments.add('--packages=${Platform.packageConfig}');
    // }
    // if (enableAsserts) {
    //   arguments.add('--enable-asserts');
    // }
    // //
    // // Add the server executable.
    // //
    // arguments.add(serverPath);

    // arguments.addAll(getServerArguments(
    //     clientId: clientId,
    //     clientVersion: clientVersion,
    //     suppressAnalytics: suppressAnalytics,
    //     diagnosticPort: diagnosticPort,
    //     instrumentationLogFile: instrumentationLogFile,
    //     sdkPath: sdkPath,
    //     useAnalysisHighlight2: useAnalysisHighlight2));

    // listener?.startingServer(dartBinary, arguments);
    // final process = await Process.start(dartBinary, arguments);
    // _process = process;
    // // ignore: unawaited_futures
    // process.exitCode.then((int code) {
    //   if (code != 0 && _process != null) {
    //     // Report an error if server abruptly terminated
    //     listener?.unexpectedStop(code);
    //   }
    // });
  }
}
