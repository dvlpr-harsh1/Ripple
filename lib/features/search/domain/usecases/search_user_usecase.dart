import '../../data/repository/search_repository_impl.dart';
import '../entities/unknown_user_entity.dart';

class SearchUserUsecase {
  final SearchRepositoryImpl repository;
  const SearchUserUsecase({required this.repository});
  Stream<List<UnknownUserEntity>> call({required String query}) {
    return repository.searchUser(query: query);
  }
}
