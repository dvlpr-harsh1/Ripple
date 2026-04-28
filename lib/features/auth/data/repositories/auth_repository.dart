import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ripple/const/Strings/app_strings.dart';
import 'package:ripple/const/errors/app_errors.dart';
import 'package:ripple/features/auth/data/model/user_auth_model.dart';
import 'package:ripple/features/auth/domain/entities/user_auth_entity.dart';
import 'package:ripple/features/auth/domain/repositories/auth_repository.dart';
import 'package:ripple/features/profile/data/model/user_profile.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  UserAuthEntity? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserAuthModel.fromFirebase(user);
  }
  // In AuthRepositoryImpl — call this after login and on app start
Future<void> setOnlineStatus(bool isOnline) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  await FirebaseFirestore.instance
      .collection(AppStrings.firebaseCollection)
      .doc(uid)
      .update({'isOnline': isOnline});
}

  @override
  Future<UserAuthEntity> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return UserAuthModel.fromFirebase(credential.user!);
    } on FirebaseAuthException catch (err) {
      throw firebaseAuthErrorToMessage(err.code.toString());
    } catch (e) {
      throw UnknownErrors();
    }
  }

  @override
  Future<UserAuthEntity> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required String username,
    required String phoneNum,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _firestore
          .collection(AppStrings.firebaseCollection)
          .doc(currentUser!.id.toString())
          .set(
            UserProfile(
              nameLower: name.toLowerCase(),
              usernameLower: username.toLowerCase(),
              id: currentUser!.id,
              name: name,
              email: email,
              username: username,
              phoneNum: phoneNum,
            ).toMap(),
          );

      return UserAuthModel.fromFirebase(credential.user!);
    } on FirebaseAuthException catch (err) {
      throw AuthErrors(
        message: firebaseAuthErrorToMessage(err.code.toString()),
      );
    } catch (e) {
      throw UnknownErrors();
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
