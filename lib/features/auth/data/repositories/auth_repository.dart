import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ripple/const/Strings/app_strings.dart';
import 'package:ripple/const/errors/app_errors.dart';
import 'package:ripple/features/auth/data/model/user_model.dart';
import 'package:ripple/features/auth/domain/entities/user_entity.dart';
import 'package:ripple/features/auth/domain/repositories/auth_repository.dart';
import 'package:ripple/features/profile/data/model/user_profile.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  UserEntity? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebase(user);
  }

  @override
  Future<UserEntity> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return UserModel.fromFirebase(credential.user!);
    } on FirebaseAuthException catch (err) {
      throw firebaseAuthErrorToMessage(err.code.toString());
    } catch (e) {
      throw UnknownErrors();
    }
  }

  @override
  Future<UserEntity> signUp({
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
          .collection(AppStrings.firebaseCol)
          .doc(currentUser!.id.toString())
          .set(
            UserProfile(
              id: currentUser!.id,
              name: name,
              email: email,
              username: username,
              phoneNum: phoneNum,
            ).toMap(),
          );

      return UserModel.fromFirebase(credential.user!);
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
