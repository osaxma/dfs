import 'base.dart';

class FindUnusedPackagesCommand extends DFSCommand {
  FindUnusedPackagesCommand() {
   
    argParser.addFlag(name);
  }

  @override
  final String name = 'find-unused-packages';

  @override
  final List<String> aliases = ['fup'];

  @override
  final String description = 'Find unused packages within a dart or flutter projects (only those used in lib and defined under dependencies)';
}
