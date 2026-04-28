import 'package:ripple/features/dashboard/domain/entities/known_user_entity.dart';

class DashboardState {}

class InitialDashboardState extends DashboardState {}

class DashboardLoadingState extends DashboardState {}

class DashboardUsersState extends DashboardState {
  List<KnownUserEntity> users;
  DashboardUsersState({required this.users});
}

class DashboardErrorState extends DashboardState {
  String message;
  DashboardErrorState({required this.message});
}
