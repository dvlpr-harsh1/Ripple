import 'package:ripple/features/auth/data/repositories/auth_repository.dart';

class SignOutUsecase {
  AuthRepositoryImpl repository;

  SignOutUsecase({required this.repository});
  Future<void> call() => repository.signOut();
}
