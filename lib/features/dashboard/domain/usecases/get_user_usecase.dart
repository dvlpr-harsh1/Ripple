import 'package:ripple/features/dashboard/data/model/known_user_model.dart';
import 'package:ripple/features/dashboard/data/repository/dashboard_repository_impl.dart';

import '../entities/known_user_entity.dart';

class GetUserUsercase {
  final DashboardRepositoryImpl repository;
  GetUserUsercase({required this.repository});

  Stream<List<KnownUserEntity>> call({required String userId}) {
    return repository.getCardUser(userId: userId);
  }
}
