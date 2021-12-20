import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'dart:io';

AstNode generateASTfromSource(String string) {
  final parsedString = parseString(
    content: string,
  );

  return parsedString.unit;
}

// There's an issue here that File is defined in both Resource and dart:io ...
//
AstNode generateASTfromFile(File file) {
  final parsedString = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(), // same as used by parseString
    // We already have the file reference in hand but it's a 'dart:io` typee while
    // ResourceProvider uses its own File/Folder types. ResourceProvider has two 
    // implementations:  PhysicalResourceProvider or MemoryResourceProvider.
    // it's worth looking at how they handle multiple files and directories since
    // we are reading the entire lib folder find unused packages command. 
    // resourceProvider: 
  );

  return parsedString.unit;
}
