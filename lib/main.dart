import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ripple/const/routes/app_router.dart';
import 'package:ripple/const/theme/app_theme.dart';
import 'package:ripple/features/auth/data/repositories/auth_repository.dart';
import 'package:ripple/features/auth/domain/usecases/login_usecase.dart';
import 'package:ripple/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:ripple/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_event.dart';
import 'package:ripple/features/dashboard/data/repository/dashboard_repository_impl.dart';
import 'package:ripple/features/dashboard/domain/usecases/get_user_usecase.dart';
import 'package:ripple/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ripple/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ripple/firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  usePathUrlStrategy();
  runApp(const MyApp());
}

late Size mq;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ✅ Created once, lived for app lifetime, disposed properly
  late final AuthBloc _authBloc;
  late final DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();

    final repository = AuthRepositoryImpl();

    _authBloc = AuthBloc(
      login: LoginUsecase(repository: repository),
      signUp: SignUpUsecase(repository: repository),
      signOut: SignOutUsecase(repository: repository),
      repository: repository,
    )..add(AuthCheckRequested()); // ✅ correct event

    _dashboardBloc = DashboardBloc(
      getUserUsercase: GetUserUsercase(
        repository: DashboardRepositoryImpl(),
      ),
    );
    // ✅ Only dispatch if already logged in at startup
    // If not logged in, app_router.dart dispatches after login
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _dashboardBloc.add(ChatUserRequested(userId: uid));
    }
  }

  @override
  void dispose() {
    _authBloc.close();
    _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return MultiBlocProvider(
      providers: [
        // ✅ Provide the already-created blocs — no `create` duplication
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<DashboardBloc>.value(value: _dashboardBloc),
      ],
      child: MaterialApp.router(
        theme: AppTheme.themeDark,
        routerConfig: AppRouter().routes(authBloc: _authBloc),
      ),
    );
  }
}