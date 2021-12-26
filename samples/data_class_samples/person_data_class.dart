import 'dart:convert';

import 'package:collection/collection.dart';

abstract class Hobby {
  Map<String, dynamic> toMap();
  String toJson();
  factory Hobby.fromJson(String json) => throw UnimplementedError();
  factory Hobby.fromMap(Map<String, dynamic> map) => throw UnimplementedError();
}

abstract class Interest {
  Map<String, dynamic> toMap();
  String toJson();
  factory Interest.fromJson(String json) => throw UnimplementedError();
  factory Interest.fromMap(Map<String, dynamic> map) => throw UnimplementedError();
}

class Person {
  final String name;
  final String? nickname;
  final int age;
  final double height;
  final List<Hobby> hobbies;
  final Set<Interest> interests;
  final Map<String, dynamic> addresses;

  Person({
    required this.name,
    this.nickname,
    required this.age,
    required this.height,
    required this.hobbies,
    required this.interests,
    required this.addresses,
  });

  Person copyWith({
    String? name,
    String? nickname,
    int? age,
    double? height,
    List<Hobby>? hobbies,
    Set<Interest>? interests,
    Map<String, dynamic>? addresses,
  }) {
    return Person(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      height: height ?? this.height,
      hobbies: hobbies ?? this.hobbies,
      interests: interests ?? this.interests,
      addresses: addresses ?? this.addresses,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nickname': nickname,
      'age': age,
      'height': height,
      'hobbies': hobbies.map((x) => x.toMap()).toList(),
      'interests': interests.map((x) => x.toMap()).toList(),
      'addresses': addresses,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      name: map['name'] ?? '',
      nickname: map['nickname'],
      age: map['age']?.toInt() ?? 0,
      height: map['height']?.toDouble() ?? 0.0,
      hobbies: List<Hobby>.from(map['hobbies']?.map((x) => Hobby.fromMap(x))),
      interests: Set<Interest>.from(map['interests']?.map((x) => Interest.fromMap(x))),
      addresses: Map<String, dynamic>.from(map['addresses']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Person(name: $name, nickname: $nickname, age: $age, height: $height, hobbies: $hobbies, interests: $interests, addresses: $addresses)';
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
        collectionEquals(other.interests, interests) &&
        collectionEquals(other.addresses, addresses);
  }

  @override
  int get hashCode {
    return name.hashCode ^
        nickname.hashCode ^
        age.hashCode ^
        height.hashCode ^
        hobbies.hashCode ^
        interests.hashCode ^
        addresses.hashCode;
  }
}
