import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ripple/features/search/domain/entities/unknown_user_entity.dart';

import '../../../const/theme/app_colors.dart';

class SearchCard extends StatelessWidget {
  final UnknownUserEntity cardEntity;
  final bool isAdded; // ✅
  final VoidCallback onAdd;

  const SearchCard({
    required this.cardEntity,
    required this.isAdded, // ✅
    required this.onAdd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final nameInitial = cardEntity.name[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // _Avatar(nameInitial: nameInitial, imgUrl: cardEntity.imgUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardEntity.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(color: Colors.white),
                ),
                Text(
                  cardEntity.username,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),

          // ✅ shows "Added ✓" after tapping
          GestureDetector(
            onTap: onAdd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isAdded ? null : AppColors.igGradient,
                color: isAdded ? AppColors.inputFill : null,
                borderRadius: BorderRadius.circular(12),
                border: isAdded
                    ? Border.all(color: AppColors.textPrimary.withOpacity(0.1))
                    : null,
              ),
              child: Text(
                isAdded ? 'Added ✓' : 'Add',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: isAdded ? AppColors.textHint : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
