import 'package:flutter/material.dart';

class AppUser {
  final String uid;
  final String email;
  final String contactNum;
  final String name;

  AppUser({
    required this.uid,
    required this.email,
    required this.contactNum,
    required this.name,
  });

  factory AppUser.fromJson(Map<String, dynamic> jsonUser) {
    final uid = jsonUser['uid'] as String?;
    final email = jsonUser['email'] as String?;
    final contactNum = jsonUser['contact_num'] as String?;
    final name = jsonUser['name'] as String?;

    if (uid == null || email == null || contactNum == null || name == null) {
      debugPrint('AppUser.fromJson: Invalid data: $jsonUser');
      throw ArgumentError('Missing required fields in user data');
    }

    return AppUser(
      uid: uid,
      email: email,
      contactNum: contactNum,
      name: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'contact_num': contactNum,
      'name': name,
    };
  }
}