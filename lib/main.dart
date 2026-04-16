import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ripple/const/routes/app_router.dart';
import 'package:ripple/features/auth/data/repositories/auth_repository.dart';
import 'package:ripple/features/auth/domain/usecases/login_usecase.dart';
import 'package:ripple/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:ripple/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_event.dart';
import 'package:ripple/firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  usePathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AuthRepositoryImpl();
    final authBloc = AuthBloc(
      login: LoginUsecase(repository: repository),
      signUp: SignUpUsecase(repository: repository),
      signOut: SignOutUsecase(repository: repository),
      repository: repository,
    )..add(AuthCheckRequested());
    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp.router(
        routerConfig: AppRouter().routes(authBloc: authBloc),
      ),
    );
  }
}
