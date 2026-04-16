import 'package:flutter/material.dart';
import 'package:ripple/const/theme/app_colors.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradientText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => AppColors.igGradient.createShader(b),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}