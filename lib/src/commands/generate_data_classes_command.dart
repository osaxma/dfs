import 'base.dart';

class GenerateDataClassesCommand extends DFSCommand {
  GenerateDataClassesCommand();

  @override
  final String name = 'generate-data-classes';

  @override
  final List<String> aliases = ['gdc'];

  @override
  final String description = 'Generate Data Classes for specified directory where file name ends with `_data.dart';
}
