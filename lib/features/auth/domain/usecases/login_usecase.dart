import 'package:ripple/features/auth/data/repositories/auth_repository.dart';
import 'package:ripple/features/auth/domain/entities/user_entity.dart';

class LoginUsecase {
  final AuthRepositoryImpl repository;

  LoginUsecase({required this.repository});
  Future<UserEntity> call({required String email, required String password}) =>
      repository.logIn(email: email, password: password);
}
