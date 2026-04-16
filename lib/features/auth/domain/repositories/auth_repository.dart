import 'package:ripple/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> logIn({required String email, required String password});
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required String username,
    required String phoneNum,
  });
  Future<void> signOut();
  UserEntity? get currentUser;
}
