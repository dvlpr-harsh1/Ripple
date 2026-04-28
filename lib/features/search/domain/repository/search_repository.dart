import '../entities/unknown_user_entity.dart';

abstract class SearchRepository {
  Stream<List<UnknownUserEntity>> searchUser({required String query});
  // UnknownUserEntity addUser({
  //   required String user1,
  //   required String SearchUserEntity,
  // });
}
