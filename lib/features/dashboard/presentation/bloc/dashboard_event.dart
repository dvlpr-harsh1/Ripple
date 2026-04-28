import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {}

class ChatUserRequested extends DashboardEvent {
  final String userId;
  String? searchUser;
  ChatUserRequested({required this.userId, this.searchUser});
  @override
  List<Object?> get props => [userId];
}

class SearchUserRequested extends DashboardEvent {
  String query;
  SearchUserRequested({required this.query});
  @override
  List<Object?> get props => [query];
}
