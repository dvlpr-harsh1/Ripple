import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ripple/features/auth/domain/repositories/auth_repository.dart';
import 'package:ripple/features/auth/domain/usecases/login_usecase.dart';
import 'package:ripple/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:ripple/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_event.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUsecase _login;
  final SignUpUsecase _signUp;
  final SignOutUsecase _signOut;
  final AuthRepository _repository;
  AuthBloc({
    required LoginUsecase login,
    required SignUpUsecase signUp,
    required SignOutUsecase signOut,
    required AuthRepository repository,
  }) : _login = login,
       _signUp = signUp,
       _signOut = signOut,
       _repository = repository,
       super(AuthInitialState()) {
    on<AuthCheckRequested>(_onCheck);
    on<LoginRequested>(_onLogin);
    on<SignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
  }

  void _onCheck(AuthCheckRequested event, Emitter<AuthState> emit) {
    final user = _repository.currentUser;
    if (user != null) {
      emit(AuthenticatedUser(user: user));
    } else {
      emit(UnAuthenticatedUser());
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(LoadingRequested());
    try {
      final user = await _login(email: event.email, password: event.password);
      emit(AuthenticatedUser(user: user));
    } catch (e) {
      emit(LoadingRequested());
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onSignUp(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(LoadingRequested());
    try {
      final user = await _signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        confirmPassword: event.confirmPassword,
        username: event.username,
        phoneNum: event.phoneNum,
      );
      emit(AuthenticatedUser(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _signOut();
    emit(UnAuthenticatedUser());
  }
}
