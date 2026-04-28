import 'package:firebase_auth/firebase_auth.dart';
import 'package:ripple/features/auth/domain/entities/user_auth_entity.dart';

class UserAuthModel extends UserAuthEntity {
  const UserAuthModel({
    required super.id,
    required super.email,
    super.displayName,
    super.imgUrl,
    super.profileViews,
  });

  factory UserAuthModel.fromFirebase(User user) => UserAuthModel(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    imgUrl: user.photoURL,
    profileViews: [],
  );
}
