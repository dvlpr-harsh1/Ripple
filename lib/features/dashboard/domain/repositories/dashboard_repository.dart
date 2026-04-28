import 'package:flutter/material.dart';
import 'package:ripple/features/dashboard/domain/entities/known_user_entity.dart';

abstract class DashboardRepository {
  Stream<List<KnownUserEntity>> getCardUser({
    required String userId,
  });
}
