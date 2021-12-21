import 'dart:io';

import "package:dart_style/dart_style.dart"; // for formatting the generated code
import 'package:analyzer/dart/ast/ast.dart' hide Expression; // for AST types
import 'package:analyzer/dart/ast/visitor.dart'; // for building AST visitors
import 'package:built_collection/built_collection.dart'; // for buildng parts as a list (constructors, parameters, etc.)
import 'package:cli_util/cli_logging.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dfs/src/common/ast_utils.dart';
import 'package:dfs/src/common/io_utils.dart'; // for building code
import 'package:path/path.dart' as p;

class DataClassGenerator {
  final Logger logger;
  final Directory directory;

  DataClassGenerator({
    required this.logger,
    required this.directory,
  });

  // TODO: let the user pass an options for:
  //  - `bool format` whether to format or not.
  //  - `int pageWidth`
  late final formatter = DartFormatter(pageWidth: 120);

  late final dartEmitter = DartEmitter();

  // if `eagerError` is `true`, the generation process stop in the first error and return a Future.error
  // if `false` (default), it'll continute for the rest of the files.
  Future<DataClassGeneratorResult> generate([
    bool eagerError = false,
    String filesEndWith = '_data.dart',
  ]) async {
    final targetFiles = await findAllDartFiles(directory, endsWith: filesEndWith);

    final res = DataClassGeneratorResult();
    for (final file in targetFiles) {
      final basename = p.basename(file.path);
      logger.trace('generating data class for $basename');
      final generator = _Generator(
        file: file,
        formatter: formatter,
        emitter: dartEmitter,
        logger: logger,
      );
      // TODO: add a flag to stop on first failure and if so stop the process.
      try {
        await generator.generate();
        res.succeeded.add(file);
      } catch (e) {
        logger.stderr('could not generate data class for $basename due to the following exception:\n$e');
        res.failed.add(file);
        res.errors.add(e);
        if (eagerError) {
          return res;
        }
      }
    }
    // TODO: should this return `Future.error` if `res.hasErrors == true`?
    // The issue is what if a file failed in the middle. This means some
    // succeeded and some failed -- so an error won't represent all files.
    return res;
  }
}

class DataClassGeneratorResult {
  final failed = <File>[];
  final succeeded = <File>[];
  final errors = <Object?>[];

  bool get hasErrors => errors.isNotEmpty;

  DataClassGeneratorResult();
}

// a generator that works with one file at a time
class _Generator {
  // TODO: once serialization is optional, remove and use that option to determine
  bool requireDartConvertImport = true;
  bool requireDeepEquality = false;
  final Logger logger;
  final File file;
  final DartFormatter formatter;
  final DartEmitter emitter;

  // these will be reset for each class in case there are multiple classes per file
  // or maybe we should keep them in some sort of a map since after we loop through
  // the classes, we need to replace them in the file.
  // or create our own object
  late ClassDeclaration clazz;
  final extractedParameters = <_ExtractedParameter>[];

  // TODO: in the class visitor, check if any of the two are already imported
  //       and make these true.
  bool dartConvertIsImported = false;
  bool collectionPackageIsImported = false;

  _Generator({
    required this.file,
    required this.logger,
    required this.formatter,
    required this.emitter,
  });

  Future<void> generate() async {
    final ast = generateASTfromFile(file);
    final classVisitor = _ClassesCollectorVisitor();
    // get all the classes
    final List<ClassDeclaration> classes = classVisitor.classes;
    // visit all the classes and class visitor willl accumulate them
    ast.visitChildren(classVisitor);

    dartConvertIsImported = classVisitor.dartConvertIsImported;
    collectionPackageIsImported = classVisitor.collectionPackageIsImported;

    final dataClasses = <String>[];
    // use it to format the generated code
    final formatter = DartFormatter(pageWidth: 120);
    for (var c in classes) {
      // temp: see comment above clazz definition
      clazz = c;
      extractedParameters.clear();
      extractedParameters.addAll(_ExtractedParameter.extractParameters(clazz));
      final dataClass = generateDataClass();
      final source = generateSourceFromSingleClass(dataClass);
      final formattedSource = formatter.format(source);
      dataClasses.add(formattedSource);
      print(formattedSource);
    }
    // final addCollectionImport = classVisitor.collectionExists;
    // TODO: replace the classes in the old source with the newly created dataClasses
  }


 // TODO: move the functions below to _GeneratorData and make them such as:
 // _GeneratorData.getFields
 // _GeneratorData.getCopyWith
 // _GeneratorData.getEtc.
/* -------------------------------------------------------------------------- */
/*                                    TODOS                                   */
/* -------------------------------------------------------------------------- */
// TODO: wrap all the functions in a class or classes as applicable
// TODO: handle toMap/fromMap for collections with Generic Custom Types e.g. List<Employees>
// TODO: handle deep equality for collections e.g. collectionEquals(other.list, list)
// TODO: include 'dart:convert' (for json.decode/encode) in generated code when serialization is generated
// TODO: include 'package:collection/collection.dart' import when using deep equality.
// TODO: replace classes in parsed source with generated data classes and put it into a new source.

/* -------------------------------------------------------------------------- */
/*                                    BASE                                    */
/* -------------------------------------------------------------------------- */

  Class generateDataClass() {
    final clazzBuilder = ClassBuilder();
    clazzBuilder
      ..name = clazz.name.name
      ..constructors = buildConstructors()
      ..fields = buildClassFields()
      ..methods = buildMethods();

    return clazzBuilder.build();
  }

/* -------------------------------------------------------------------------- */
/*                            CONSTRUCTORS BUILDERS                           */
/* -------------------------------------------------------------------------- */
  ListBuilder<Constructor> buildConstructors() {
    // TODO: build fromMap and fromJson factory consts
    final constructors = <Constructor>[
      buildUnnamedConstructor(),
      buildFromMapConstructor(),
      buildFromJsonConstructor(),
    ];

    return ListBuilder(constructors);
  }

/* -------------------------------------------------------------------------- */
/*                            CLASS FIELDS BUILDER                            */
/* -------------------------------------------------------------------------- */
// final String name;
// final String? nickname;
// final int age;
// final double height;
// final List<String> hobbies;
  ListBuilder<Field> buildClassFields() {
    final fields = <Field>[];
    for (var param in extractedParameters) {
      final assignment = param.assignment != null ? Code(param.assignment!) : null;
      fields.add(Field((b) {
        b
          ..name = param.name
          ..modifier = FieldModifier.final$
          ..assignment = assignment
          ..type = param.typeRef;
      }));
    }

    return ListBuilder(fields);
  }

/* -------------------------------------------------------------------------- */
/*                           CLASS METHODS BUILDERS                           */
/* -------------------------------------------------------------------------- */
  ListBuilder<Method> buildMethods() {
    final methods = <Method>[
      generateCopyWithMethod(),
      generateToJsonMethod(),
      generateToMapMethod(),
      generateToStringMethod(),
      generateEqualityOperator(),
      generateHashCodeGetter(),
    ];

    return ListBuilder(methods);
  }

/* -------------------------------------------------------------------------- */
/*                           BUILDERS IMPLEMENTATION                          */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                             DEFAULT CONSTRUCTOR                            */
/* -------------------------------------------------------------------------- */
// const Person({
//   required this.name,
//   this.nickname,
//   required this.age,
//   required this.height,
//   required this.hobbies,
// });
  Constructor buildUnnamedConstructor() {
    return Constructor((b) {
      b
        ..optionalParameters = buildConstructorNamedParameters()
        ..constant = true;
    });
  }

  ListBuilder<Parameter> buildConstructorNamedParameters() {
    final namedParameters = <Parameter>[];
    extractedParameters.forEach((param) {
      if (param.isInitialized) return;
      namedParameters.add(
        Parameter(
          (b) {
            b
              ..name = param.name
              ..named = true
              ..toThis = true
              ..required = !param.isNullable;
          },
        ),
      );
    });

    if (namedParameters.isNotEmpty) {
      // a workaround to add a trailing comma by a trailing parameter with an empty name.
      // there's no method in the ConstructorBuilder to add a trailing comma nor is there one with in DartFormatter.
      namedParameters.add(Parameter((b) {
        b.name = '';
      }));
    }

    return ListBuilder(namedParameters);
  }

/* -------------------------------------------------------------------------- */
/*                        fromJson Factory Constructor                        */
/* -------------------------------------------------------------------------- */
// TODO: include import 'dart:convert';
//  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));
  Constructor buildFromJsonConstructor() {
    final name = clazz.name.name;
    return Constructor((b) {
      b
        ..name = 'fromJson'
        ..factory = true
        ..requiredParameters = ListBuilder<Parameter>([
          Parameter((b) {
            b
              ..name = 'source'
              ..type = refer('String');
          })
        ])
        ..lambda = true
        ..body = Code('$name.fromMap(json.decode(source))');
    });
  }

/* -------------------------------------------------------------------------- */
/*                         fromMap Factory Constructor                        */
/* -------------------------------------------------------------------------- */
// factory Person.fromMap(Map<String, dynamic> map) {
//   return Person(
//     name: map['name'],
//     nickname: map['nickname'],
//     age: map['age'].toInt(),
//     height: map['height'].toDouble(),
//     hobbies: List<String>.from(map['hobbies']),
//   );
// }
  Constructor buildFromMapConstructor() {
    return Constructor((b) {
      b
        ..name = 'fromMap'
        ..factory = true
        ..requiredParameters = ListBuilder<Parameter>([
          Parameter((b) {
            b
              ..name = 'map'
              ..type = refer('Map<String, dynamic>');
          })
        ])
        ..body = generateFromMapConstructorBody();
    });
  }

  Code generateFromMapConstructorBody() {
    final body = extractedParameters
        .where((p) => !p.isInitialized)
        .map(buildFromMapField)
        .reduce((value, element) => value + ',' + element);
    return Code('return ${clazz.name.name}($body,);');
  }

  String buildFromMapField(_ExtractedParameter param) {
    // TODO: we should capture the generic for Lists and Maps
    String symbol = removeGenericsFromType(param.symbol).replaceAll('?', '');
    final fieldName = param.name;
    String mapValue = "map['$fieldName']";
    final nullablel = param.isNullable;
    switch (symbol) {
      case 'num':
      case 'dynamic':
      case 'bool':
      case 'Object':
      case 'String':
        // do nothing e.g. map[fieldName] as is.
        break;
      case 'int':
        // - int --> map['fieldName']?.toInt()       OR     int.parse(map['fieldName'])
        mapValue = nullablel ? '$mapValue?.toInt()' : '$mapValue.toInt()';
        break;
      case 'double':
        // - double --> map['fieldName']?.double()   OR     double.parse(map['fieldName'])
        // note: dart, especially when used with web, would convert double to integer (1.0 -> 1) so account for it.
        mapValue = nullablel ? '$mapValue?.toDouble()' : '$mapValue.toDouble()';
        break;
      case 'List':
        // TODO: handle generics
        // e.g. List<int>.from(map['employeeIDs']) or List<Employee>.from(map['employee']?.map((x) => Employee.fromMap(x))),
        mapValue = nullablel ? '$mapValue == null ? null : List.from($mapValue)' : 'List.from($mapValue)';
        break;
      case 'Set':
        // TODO: handle generics
        // e.g. Set<int>.from(map['fieldName'])
        mapValue = nullablel ? '$mapValue == null ? null : Set.from($mapValue)' : 'Set.from($mapValue)';
        break;
      case 'Map':
        // TODO: handle generics
        // e.g. Map<int>.from(map['fieldName'])
        mapValue = nullablel ? '$mapValue == null ? null : Map.from($mapValue)' : 'Map.from($mapValue)';
        break;
      default:
        // CustomType --> CustomType.fromMap(map['fieldName'])
        mapValue = nullablel ? '$mapValue == null ? null : $fieldName.from($mapValue)' : '$fieldName.from($mapValue)';
        break;
    }
    return '$fieldName: $mapValue';
  }

/* -------------------------------------------------------------------------- */
/*                                toMap METHOD                                */
/* -------------------------------------------------------------------------- */

// Map<String, dynamic> toMap() {
//   return {
//     'name': name,
//     'nickname': nickname,
//     'age': age,
//     'height': height,
//     'hobbies': hobbies,
//   };
// }
  Method generateToMapMethod() {
    return Method((b) {
      b
        ..name = 'toMap'
        ..returns = refer('Map<String, dynamic>')
        ..body = generateToMapMethodBody();
    });
  }

  Code generateToMapMethodBody() {
    final body = extractedParameters
        .where((p) => !p.isInitialized)
        .map(buildToMapField)
        .reduce((value, element) => value + ',' + element);
    return Code('return {$body,};');
  }

  String buildToMapField(_ExtractedParameter param) {
    // TODO: we should capture the generic for Lists and Maps
    String symbol = removeGenericsFromType(param.symbol).replaceAll('?', '');
    final fieldName = param.name;
    String mapValue = fieldName;
    final nullablel = param.isNullable;
    switch (symbol) {
      case 'num':
      case 'dynamic':
      case 'Object':
      case 'String':
      case 'int':
      case 'double':
      case 'bool':
        // return as is 'map[fieldName]'
        break;
      case 'List':
        // todo: handle generics (if the generic is a basic type accepted by json, leave as is)
        //  e.g. employees.map((x) => x.toMap()).toList(),
        // mapValue = nullablel ? '$mapValue == null ? null : List.from($mapValue)' : 'List.from($mapValue)';
        break;
      case 'Set':
        // todo: handle generics (if the generic is a basic type accepted by json, leave as is)
        // mapValue = nullablel ? '$mapValue == null ? null : Set.from($mapValue)' : 'Set.from($mapValue)';
        break;
      case 'Map':
        // todo: handle generics (if the generic is a basic type accepted by json, leave as is)
        // mapValue = nullablel ? '$mapValue == null ? null : Map.from($mapValue)' : 'Map.from($mapValue)';
        break;
      default:
        mapValue = nullablel ? '$mapValue?.toMap()' : '$mapValue.toMap()';
        break;
    }

    return "'$fieldName': $mapValue";
  }

/* -------------------------------------------------------------------------- */
/*                               toJson() METHOD                              */
/* -------------------------------------------------------------------------- */
//  String toJson() => json.encode(toMap());
  Method generateToJsonMethod() {
    return Method((b) {
      b
        ..name = 'toJson'
        ..returns = refer('String')
        ..lambda = true
        ..body = Code('json.encode(toMap())');
    });
  }

/* -------------------------------------------------------------------------- */
/*                               copyWith METHOD                              */
/* -------------------------------------------------------------------------- */
// Person copyWith({
//   String? name,
//   String? nickname,
//   int? age,
//   double? height,
//   List<String>? hobbies,
// }) {
//   return Person(
//     name: name ?? this.name,
//     nickname: nickname ?? this.nickname,
//     age: age ?? this.age,
//     height: height ?? this.height,
//     hobbies: hobbies ?? this.hobbies,
//   );
// }
  Method generateCopyWithMethod() {
    final copyWithMethod = Method((b) {
      b
        ..returns = refer(clazz.name.name)
        ..name = 'copyWith'
        ..body = generateCopyWithBody()
        ..optionalParameters = generateCopyWithMethodParameters();
    });

    return copyWithMethod;
  }

  ListBuilder<Parameter> generateCopyWithMethodParameters() {
    final parameters = <Parameter>[];

    parameters.addAll(
      extractedParameters.where((p) => !p.isInitialized).map(
            (p) => Parameter(
              (b) {
                b
                  ..name = p.name
                  ..named = true
                  ..type = p.typeRefAsNullable;
              },
            ),
          ),
    );

    if (parameters.isNotEmpty) {
      // to force adding a trailing comma
      parameters.add(Parameter((b) => b.name = ''));
    }

    return ListBuilder(parameters);
  }

  Code generateCopyWithBody() {
    final body = extractedParameters
        .where((p) => !p.isInitialized)
        .map((p) => '${p.name}: ${p.name} ?? this.${p.name}')
        .reduce((value, element) => value + ',' + element);
    return Code('return ${clazz.name.name}($body,);');
  }

/* -------------------------------------------------------------------------- */
/*                           EQUALITY AND HASH CODE                           */
/* -------------------------------------------------------------------------- */
// TODO: handle collection equality
// @override
// bool operator ==(Object other) {
//   if (identical(this, other)) return true;
//   return other is Person &&
//       other.name == name &&
//       other.nickname == nickname &&
//       other.age == age &&
//       other.height == height &&
//       other.hobbies == hobbies;
// }
  Method generateEqualityOperator() {
    return Method((b) {
      b
        ..name = '=='
        ..returns = refer('bool operator')
        ..requiredParameters = ListBuilder([
          Parameter((b) {
            b
              ..name = 'other'
              ..type = refer('Object');
          })
        ])
        ..annotations = overrideAnnotation()
        ..body = generateEqualityOperatorBody();
    });
  }

  Code generateEqualityOperatorBody() {
    final className = clazz.name.name;
    final fields =
        extractedParameters.map((p) => 'other.${p.name} == ${p.name}').reduce((prev, next) => prev + '&&' + next);
    return Code('''
  if (identical(this, other)) return true;
  // TODO: handle list equality here 
  return other is $className && $fields;
  ''');
  }

// @override
// int get hashCode {
//   return name.hashCode ^ nickname.hashCode ^ age.hashCode ^ height.hashCode ^ hobbies.hashCode;
// }
  Method generateHashCodeGetter() {
    final fields = extractedParameters.map((p) => '${p.name}.hashCode').reduce((prev, next) => prev + '^' + next);
    return Method((b) {
      b
        ..name = 'hashCode'
        ..type = MethodType.getter
        ..returns = refer('int')
        ..annotations = overrideAnnotation()
        ..body = Code('return $fields;');
    });
  }

/* -------------------------------------------------------------------------- */
/*                                  toString                                  */
/* -------------------------------------------------------------------------- */

// @override
// String toString() {
//   return 'Person(name: $name, nickname: $nickname, age: $age, height: $height, hobbies: $hobbies)';
// }
  Method generateToStringMethod() {
    final className = clazz.name.name;
    final fields =
        extractedParameters.map((p) => p.name + ': ' '\$${p.name}').reduce((prev, next) => prev + ', ' + next);
    return Method((b) {
      b
        ..name = 'toString'
        ..returns = refer('String')
        ..annotations = overrideAnnotation()
        ..body = Code("return '$className($fields)';");
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                               HELPER METHODS                               */
  /* -------------------------------------------------------------------------- */

  ListBuilder<Expression> overrideAnnotation() {
    return ListBuilder(const [CodeExpression(Code('override'))]);
  }

  String generateSourceFromSingleClass(Class clazz) {
    final str = clazz.accept(emitter);
    return str.toString();
  }
}
/* -------------------------------------------------------------------------- */
/*                               HELPER CLASSES                               */
/* -------------------------------------------------------------------------- */

class _GeneratorData {
  final ClassDeclaration clazz;

  /// This indicates that there's an uninitialized FieldDeclaration of a collection type
  ///
  /// This is used by the _Generator to determine if it needs to include `collection` library
  /// for deepEquality
  late final bool hasCollection;
  late final List<_ExtractedParameter> extractedParameters;

  _GeneratorData(
    this.clazz,
  ) {
    // TODO: handle this in _ExtractedParameter.extractParameters and add it as a property
    //       since the generator neeeds to add deepequality anyway.
    final _collectionFinder = _FindCollectionVisitor();
    clazz.accept(_collectionFinder);
    hasCollection = _collectionFinder.foundCollection;
    extractedParameters = _ExtractedParameter.extractParameters(clazz);
  }
}

class _ClassesCollectorVisitor extends SimpleAstVisitor {
  final bool includeAbstract;
  _ClassesCollectorVisitor({
    this.includeAbstract = false,
  });

  // todo remove
  final _collectionFinder = _FindCollectionVisitor();

  bool get collectionExists => _collectionFinder.foundCollection;

  final classes = <ClassDeclaration>[];
  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (includeAbstract || !node.isAbstract) {
      // todo remove
      if (!_collectionFinder.foundCollection) {
        node.accept(_collectionFinder);
      }
      classes.add(node);
    }
  }

  bool dartConvertIsImported = false;
  bool collectionPackageIsImported = false;
  @override
  visitImportDirective(ImportDirective node) {
    if (dartConvertIsImported && collectionPackageIsImported) return;
    if (node.uri.stringValue.toString() == _dartConvertImportUri) {
      dartConvertIsImported = true;
    }
    if (node.uri.stringValue.toString() == _collectionImportUri) {
      collectionPackageIsImported = true;
    }
    return super.visitImportDirective(node);
  }
}

class _FindCollectionVisitor extends RecursiveAstVisitor {
  final collectionReg = RegExp(r'List|Map|Set');
  bool foundCollection = false;
  @override
  visitFieldDeclaration(FieldDeclaration node) {
    // for some reason node.fields.type.type is always null
    // (node.fields.type.type  is a DartType and has some checks like isDartCoreList etc);
    final typeName = node.fields.type?.toSource() ?? '';
    // TODO: improve this parser
    if (typeName.startsWith(collectionReg)) {
      // initialized fields aren't generated in the data class so they're not accounted for.
      if (node.fields.variables.any((element) => element.initializer == null)) {
        foundCollection = true;
      }
    }
    if (foundCollection) {
      return;
    } else {
      return super.visitFieldDeclaration(node);
    }
  }
}

class _ExtractedParameter {
  final String name;
  final bool isNullable;
  final bool isInitialized;
  final String symbol;
  final Reference typeRef;
  final String? assignment;

  _ExtractedParameter({
    required this.name,
    required this.isNullable,
    required this.isInitialized,
    required this.symbol,
    this.assignment,
  }) : typeRef = refer(symbol);

  Reference? get typeRefAsNullable => isNullable ? typeRef : refer(symbol + '?');

  static List<_ExtractedParameter> extractParameters(ClassDeclaration clazz) {
    final parameters = <_ExtractedParameter>[];
    for (var member in clazz.members.whereType<FieldDeclaration>()) {
      // this applies to all variables
      final type = member.fields.type?.toSource() ?? 'dynamic';
      final isNullable = member.fields.type?.question != null || type == 'dynamic';
      // note: member.fields.variables is a List since once can define multiple variables within the same declaration
      //       such as: `final int x, y, z;` or `final int x = 0, y = 1, z = 3;`
      for (var variable in member.fields.variables) {
        final name = variable.name.name;
        final isInitialized = variable.initializer != null;
        final assignment = isInitialized ? variable.initializer!.toSource() : null;
        parameters.add(
          _ExtractedParameter(
            name: name,
            isNullable: isNullable,
            isInitialized: isInitialized,
            symbol: type,
            assignment: assignment,
          ),
        );
      }
    }
    return parameters;
  }
}

/* -------------------------------------------------------------------------- */
/*                                   GENERAL                                  */
/* -------------------------------------------------------------------------- */

final genericRegExp = RegExp(r'<.*>');

String removeGenericsFromType(String string) {
  return string.replaceAll(genericRegExp, '');
}

const _dartConvertImportUri = "dart:convert";
const _collectionImportUri = "package:collection/collection.dart";
