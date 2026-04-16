import 'package:flutter/material.dart';
import 'package:ripple/const/theme/app_colors.dart';

class OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }
}
