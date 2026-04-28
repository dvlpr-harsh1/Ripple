import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/unknown_user_entity.dart';

class UnknownUserModel extends UnknownUserEntity {
  UnknownUserModel({
    required super.name,
    required super.nameLower,
    required super.imgUrl,
    required super.id,
    required super.username,
    required super.usernameLower,
  });

  factory UnknownUserModel.fromJson(QueryDocumentSnapshot snapshot) {
    return UnknownUserModel(
      id: snapshot.id,
      name: snapshot['name'] ?? '',
      imgUrl: snapshot['imgUrl'] ?? '',
      username: snapshot['username'] ?? '',
      nameLower: snapshot['nameLower'],
      usernameLower: snapshot['usernameLower'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "nameLower": name.toLowerCase(),
      "username": username,
      "usernameLower": username.toLowerCase(),
      "imgUrl": imgUrl,
    };
  }
}
