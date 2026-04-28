import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:ripple/const/Strings/app_strings.dart';
import 'package:ripple/features/dashboard/data/model/known_user_model.dart';
import 'package:ripple/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<KnownUserModel>> getCardUser({required String userId}) {
    return _firestore
        .collection(AppStrings.chatCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessage.timestamp', descending: true)
        .snapshots()
        .switchMap((chatSnaps) {
          if (chatSnaps.docs.isEmpty) return Stream.value(<KnownUserModel>[]);

          final pairs = chatSnaps.docs
              .map((chatDoc) {
                final participants = List<String>.from(
                  chatDoc['participants'] ?? [],
                );
                final otherUid = participants.firstWhere(
                  (id) => id != userId,
                  orElse: () => '',
                );
                return otherUid.isNotEmpty
                    ? (chatDoc: chatDoc, otherUid: otherUid)
                    : null;
              })
              .whereType<({DocumentSnapshot chatDoc, String otherUid})>()
              .toList();

          if (pairs.isEmpty) return Stream.value(<KnownUserModel>[]);

          final perUserStreams = pairs.map((pair) {
            return _firestore
                .collection(AppStrings.firebaseCollection)
                .doc(pair.otherUid)
                .snapshots()
                .map((userDoc) {
                  if (!userDoc.exists) return null;
                  return KnownUserModel.fromMerged(
                    userDoc: userDoc,
                    chatDoc: pair.chatDoc,
                    myUid: userId,
                  );
                });
          }).toList();

          return CombineLatestStream(
            perUserStreams,
            (List<KnownUserModel?> models) =>
                models.whereType<KnownUserModel>().toList(),
          );
        });
  }
}
