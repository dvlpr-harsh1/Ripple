import 'package:equatable/equatable.dart';
import 'package:ripple/features/auth/domain/entities/user_entity.dart';

class AuthState extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class LoadingRequested extends AuthState {}

class AuthenticatedUser extends AuthState {
  UserEntity user;
  AuthenticatedUser({required this.user});
  List<Object?> get props => [user];
}

class UnAuthenticatedUser extends AuthState {}

class AuthFailure extends AuthState {
  String message;
  AuthFailure({required this.message});
  List<Object?> get props => [message];
}
