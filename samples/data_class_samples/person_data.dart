abstract class Hobby {
  Map<String, dynamic> toMap();
  String toJson();
  factory Hobby.fromJson(String json) => throw UnimplementedError();
  factory Hobby.fromMap(Map<String, dynamic> map) => throw UnimplementedError();
}

/// a doc comment for the class represneting a person
///
/// It includes a list of the person's [Hobby]
// not a doc comment
class Person {
  /// This is the name of the person
  final String name;

  /// The nickname
  final String? nickname;
  // age of the person
  final int age;
  final double height;
  final List<Hobby> hobbies;
}
