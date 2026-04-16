import 'package:equatable/equatable.dart';

class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  String email;
  String password;
  LoginRequested({required this.email, required this.password});
}

class SignUpRequested extends AuthEvent {
  String email;
  String password;
  String name;
  String username;
  String confirmPassword;
  String phoneNum;
  SignUpRequested({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.name,
    required this.username,
    required this.phoneNum,
  });
}

class AuthSignOutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}
