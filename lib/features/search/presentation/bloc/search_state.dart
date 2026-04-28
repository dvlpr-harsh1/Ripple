import 'package:equatable/equatable.dart';

import '../../domain/entities/unknown_user_entity.dart';

abstract class SearchState extends Equatable {
  @override
  List<Object?> get props => const [];
}

class InitialSearchState extends SearchState {}

class SearchLoadingState extends SearchState {}

class SearchResultState extends SearchState {
  final List<UnknownUserEntity> users;

  SearchResultState({required this.users});

  @override
  List<Object?> get props => [users];
}

class SearchErrorState extends SearchState {
  final String message;

  SearchErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
