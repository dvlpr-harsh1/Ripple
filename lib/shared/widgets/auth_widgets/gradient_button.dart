import 'package:flutter/material.dart';
import 'package:ripple/const/theme/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.igGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
