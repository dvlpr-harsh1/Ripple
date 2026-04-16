import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_event.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_state.dart';
import 'package:ripple/features/auth/presentation/login_page.dart';
import 'package:ripple/features/auth/presentation/sign_up_page.dart';

class AppRouter {
  GoRouter routes({required AuthBloc authBloc}) => GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshListenable(stream: authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signUp';

      if (authState is AuthenticatedUser && isAuthRoute) return '/';
      if (authState is UnAuthenticatedUser && !isAuthRoute) return '/signUp';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthSignOutRequested()),
              child: Text('Logout'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/signUp', builder: (context, state) => SignupPage()),
    ],
  );
}

class GoRouterRefreshListenable extends ChangeNotifier {
  GoRouterRefreshListenable({required Stream stream}) {
    stream.listen((_) => notifyListeners());
  }
}
