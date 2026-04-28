import 'package:equatable/equatable.dart';
import 'package:ripple/features/auth/domain/entities/user_auth_entity.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class LoadingRequested extends AuthState {}

class AuthenticatedUser extends AuthState {
  final UserAuthEntity user;
   AuthenticatedUser({required this.user});

  @override
  List<Object?> get props => [user];
}

class UnAuthenticatedUser extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
   AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}