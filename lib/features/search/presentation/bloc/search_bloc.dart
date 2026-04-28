import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:ripple/features/search/domain/usecases/search_user_usecase.dart';
import 'package:ripple/features/search/presentation/bloc/search_event.dart';
import 'package:ripple/features/search/presentation/bloc/search_state.dart';

import '../../domain/entities/unknown_user_entity.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchUserUsecase searchUserUsecase;
  List<UnknownUserEntity> searchUserList = [];
  SearchBloc({required this.searchUserUsecase}) : super(InitialSearchState()) {
    on<SearchRequested>(
      _onSearchReq,
      transformer: _restartable(Duration(milliseconds: 400)),
    );
  }

  Future<void> _onSearchReq(
    SearchRequested event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(InitialSearchState());
      return;
    }

    emit(SearchLoadingState());

    await emit.forEach<List<UnknownUserEntity>>(
      searchUserUsecase(query: query.toLowerCase()),
      onData: (users) {
        searchUserList = users;
        return SearchResultState(users: searchUserList);
      },
      onError: (error, stackTrace) =>
          SearchErrorState(message: error.toString()),
    );
  }
}

EventTransformer<T> _restartable<T>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}
