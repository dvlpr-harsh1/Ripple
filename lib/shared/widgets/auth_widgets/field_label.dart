import 'package:flutter/material.dart';
import 'package:ripple/const/theme/app_colors.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge!.copyWith(color: AppColors.textSecondary),
    );
  }
}
