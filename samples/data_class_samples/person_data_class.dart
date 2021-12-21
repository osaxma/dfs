import 'dart:convert';

import 'package:collection/collection.dart';

abstract class Hobby {
  Map<String, dynamic> toMap();
  String toJson();
  factory Hobby.fromJson(String json) => throw UnimplementedError();
  factory Hobby.fromMap(Map<String, dynamic> map) => throw UnimplementedError();
}

class Person {
  final String name;
  final String? nickname;
  final int age;
  final double height;
  final List<Hobby> hobbies;
  Person({
    required this.name,
    this.nickname,
    required this.age,
    required this.height,
    required this.hobbies,
  });

  Person copyWith({
    String? name,
    String? nickname,
    int? age,
    double? height,
    List<Hobby>? hobbies,
  }) {
    return Person(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      height: height ?? this.height,
      hobbies: hobbies ?? this.hobbies,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nickname': nickname,
      'age': age,
      'height': height,
      'hobbies': hobbies.map((x) => x.toMap()).toList(),
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      name: map['name'] ?? '',
      nickname: map['nickname'],
      age: map['age']?.toInt() ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      hobbies: List<Hobby>.from(map['hobbies']?.map((x) => Hobby.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Person(name: $name, nickname: $nickname, age: $age, height: $height, hobbies: $hobbies)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Person &&
        other.name == name &&
        other.nickname == nickname &&
        other.age == age &&
        other.height == height &&
        listEquals(other.hobbies, hobbies);
  }

  @override
  int get hashCode {
    return name.hashCode ^ nickname.hashCode ^ age.hashCode ^ height.hashCode ^ hobbies.hashCode;
  }
}
