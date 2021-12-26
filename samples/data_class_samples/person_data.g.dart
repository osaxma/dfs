import 'dart:convert';
import 'package:collection/collection.dart';

abstract class Hobby {
  Map<String, dynamic> toMap();
  String toJson();
  factory Hobby.fromJson(String json) => throw UnimplementedError();
  factory Hobby.fromMap(Map<String, dynamic> map) => throw UnimplementedError();
}

/// a doc comment for the class represneting a person
///
/// It includes a list of the person's [Hobby]
class Person {
  const Person({
    required this.name,
    this.nickname,
    required this.age,
    required this.height,
    required this.hobbies,
    required this.one,
    this.two,
  });

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      name: map['name'],
      nickname: map['nickname'],
      age: map['age'].toInt(),
      height: map['height'].toDouble(),
      hobbies: List.from(map['hobbies']),
      one: List.from(map['one']),
      two: map['two'] == null ? null : List.from(map['two']),
    );
  }

  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));

  /// This is the name of the person
  final String name;

  /// The nickname
  final String? nickname;

  final int age;

  final double height;

  final List<Hobby> hobbies;

  final List<String?> one;

  final List<String?>? two;

  Person copyWith({
    String? name,
    String? nickname,
    int? age,
    double? height,
    List<Hobby>? hobbies,
    List<String?>? one,
    List<String?>? two,
  }) {
    return Person(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      height: height ?? this.height,
      hobbies: hobbies ?? this.hobbies,
      one: one ?? this.one,
      two: two ?? this.two,
    );
  }

  String toJson() => json.encode(toMap());
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nickname': nickname,
      'age': age,
      'height': height,
      'hobbies': hobbies.map((x) => x.toMap()),
      'one': one,
      'two': two,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final collectionEquals = const DeepCollectionEquality().equals;

    return other is Person &&
        other.name == name &&
        other.nickname == nickname &&
        other.age == age &&
        other.height == height &&
        collectionEquals(other.hobbies, hobbies) &&
        collectionEquals(other.one, one) &&
        collectionEquals(other.two, two);
  }

  @override
  int get hashCode {
    return name.hashCode ^
        nickname.hashCode ^
        age.hashCode ^
        height.hashCode ^
        hobbies.hashCode ^
        one.hashCode ^
        two.hashCode;
  }

  @override
  String toString() {
    return 'Person(name: $name, nickname: $nickname, age: $age, height: $height, hobbies: $hobbies, one: $one, two: $two)';
  }
}
