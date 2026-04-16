import 'package:ripple/features/auth/data/repositories/auth_repository.dart';
import 'package:ripple/features/auth/domain/entities/user_entity.dart';

class SignUpUsecase {
  final AuthRepositoryImpl repository;
  SignUpUsecase({required this.repository});
  Future<UserEntity> call({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required String username,
    required String phoneNum,
  }) => repository.signUp(
    email: email,
    password: password,
    confirmPassword: confirmPassword,
    name: name,
    username: username,
    phoneNum: phoneNum,
  );
}
