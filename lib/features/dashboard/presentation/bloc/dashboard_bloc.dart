import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripple/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ripple/features/dashboard/presentation/bloc/dashboard_state.dart';

import '../../domain/entities/known_user_entity.dart';
import '../../domain/usecases/get_user_usecase.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetUserUsercase getUserUsercase;
  List<KnownUserEntity> allUsers = [];

  DashboardBloc({required this.getUserUsercase})
      : super(InitialDashboardState()) {
    on<ChatUserRequested>(_onChatUsers);
    on<SearchUserRequested>(_onSearchUsers);
  }

  // ✅ Future<void> + async
  Future<void> _onChatUsers(
    ChatUserRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoadingState());
    await emit.forEach(
      getUserUsercase(userId: event.userId),
      onData: (users) {
        allUsers = users;
        return DashboardUsersState(users: allUsers);
      },
      onError: (error, _) => DashboardErrorState(message: error.toString()),
    );
  }

  void _onSearchUsers(
    SearchUserRequested event,
    Emitter<DashboardState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(DashboardUsersState(users: allUsers));
      return;
    }
    final filtered = allUsers
        .where((u) =>
            u.name.toLowerCase().contains(query) ||
            u.username.toLowerCase().contains(query))
        .toList();
    emit(DashboardUsersState(users: filtered));
  }
}