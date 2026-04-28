import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/const/routes/app_shell.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_state.dart';
import 'package:ripple/features/auth/presentation/login_page.dart';
import 'package:ripple/features/auth/presentation/sign_up_page.dart';
import 'package:ripple/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:ripple/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ripple/features/chat/presentation/chat_page.dart';
import 'package:ripple/features/dashboard/domain/entities/known_user_entity.dart';
import 'package:ripple/features/dashboard/presentation/dashboard_page.dart';
import 'package:ripple/features/profile/presentation/profile_page.dart';
import 'package:ripple/features/search/data/repository/search_repository_impl.dart';
import 'package:ripple/features/search/domain/usecases/search_user_usecase.dart';
import 'package:ripple/features/search/presentation/bloc/search_bloc.dart';
import 'package:ripple/features/search/presentation/search_page.dart';
import '../../features/dashboard/data/repository/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/usecases/get_user_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_event.dart';

class AppRouter {
  GoRouter routes({required AuthBloc authBloc}) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: GoRouterRefreshListenable(stream: authBloc.stream),
      redirect: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final isLoggedIn = authState is AuthenticatedUser;
        final isGoingToAuth =
            state.matchedLocation == '/signUp' ||
            state.matchedLocation == '/login';

        if (!isLoggedIn && !isGoingToAuth) return '/login';

        if (isLoggedIn && isGoingToAuth) {
          // ✅ Dispatch dashboard load when redirecting after login
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            context.read<DashboardBloc>().add(ChatUserRequested(userId: uid));
          }
          return '/dashboard';
        }

        return null;
      },

      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [GoRoute(
  path: '/dashboard',
  builder: (context, state) => const DashboardPage(),
),
            GoRoute(
              path: '/search',
              builder: (context, state) => BlocProvider(
                create: (_) => SearchBloc(
                  searchUserUsecase: SearchUserUsecase(
                    repository: SearchRepositoryImpl(),
                  ),
                ),
                child: SearchPage(),
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => ProfilePage(),
            ),
          ],
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) {
            KnownUserEntity knownUserEntity = state.extra as KnownUserEntity;
            return BlocProvider(
              create: (_) => ChatBloc(repository: ChatRepositoryImpl()),
              child: ChatPage(knownUser: knownUserEntity),
            );
          },
        ),
        GoRoute(path: '/login', builder: (context, state) => LoginPage()),
        GoRoute(path: '/signUp', builder: (context, state) => SignUpPage()),
      ],
    );
  }
}

class GoRouterRefreshListenable extends ChangeNotifier {
  GoRouterRefreshListenable({required Stream stream}) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
