import 'package:firebase_auth/firebase_auth.dart';
import 'package:ripple/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.photoUrl,
  });

  factory UserModel.fromFirebase(User user) => UserModel(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );
}
