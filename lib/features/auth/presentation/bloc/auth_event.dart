import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {} // ✅ for startup check

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String username;
  final String confirmPassword;
  final String phoneNum;

  SignUpRequested({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.name,
    required this.username,
    required this.phoneNum,
  });

  @override
  List<Object?> get props => [email, password, name, username, phoneNum];
}

class AuthSignOutRequested extends AuthEvent {}
