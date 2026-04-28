import 'package:ripple/features/auth/domain/entities/user_auth_entity.dart';

abstract class AuthRepository {
  Future<UserAuthEntity> logIn({
    required String email,
    required String password,
  });
  Future<UserAuthEntity> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required String username,
    required String phoneNum,
  });
  Future<void> signOut();
  UserAuthEntity? get currentUser;

  Future<void> setOnlineStatus(bool isOnline);
}
