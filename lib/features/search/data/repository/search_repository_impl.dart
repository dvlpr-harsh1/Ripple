import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ripple/const/Strings/app_strings.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/repository/search_repository.dart';
import '../model/unknown_user_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final FirebaseFirestore _firestore;
  SearchRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<UnknownUserModel>> searchUser({required String query}) {
    final lower = query.toLowerCase().trim();
    final upper = lower + "\uf8ff";

    final byUsername = _firestore
        .collection(AppStrings.firebaseCollection)
        .where('usernameLower', isGreaterThanOrEqualTo: lower)
        .where('usernameLower', isLessThanOrEqualTo: upper)
        .limit(10)
        .snapshots();

    final byName = _firestore
        .collection(AppStrings.firebaseCollection)
        .where('nameLower', isGreaterThanOrEqualTo: lower)
        .where('nameLower', isLessThanOrEqualTo: upper)
        .limit(10)
        .snapshots();

    return Rx.combineLatest2(byUsername, byName, (a, b) {
      final seen = <String>{};
      return [...a.docs, ...b.docs]
          .where((doc) => seen.add(doc.id))
          .map((doc) => UnknownUserModel.fromJson(doc))
          .toList();
    });
  }

  // @override
  // UnknownUserEntity addUser({required KnownUserEntity user1, required KnownUserEntity unknownUserEntity}) {
  //   _firestore.collection(AppStrings.chatCollection).doc("${user1.id}_${unknownUserEntity.id}").set({});
  // }
}
