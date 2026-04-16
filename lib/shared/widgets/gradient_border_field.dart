import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ripple/const/theme/app_colors.dart';

class GradientBorderField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final IconData icon;
  final bool obscureText;
  final Animation<double> pulseAnim;
  final String? validator;

  const GradientBorderField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.pulseAnim,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.validator,
    super.key,
  });

  @override
  State<GradientBorderField> createState() => _GradientBorderFieldState();
}

class _GradientBorderFieldState extends State<GradientBorderField> {
  late bool _obscure;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.pulseAnim,
      builder: (_, __) {
        final opacity = _focused ? 1.0 : widget.pulseAnim.value * 0.45;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gradientPurple.withOpacity(opacity),
                AppColors.gradientPink.withOpacity(opacity),
                AppColors.gradientOrange.withOpacity(opacity),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Focus(
                  onFocusChange: (f) => setState(() => _focused = f),
                  child: TextFormField(
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    obscureText: _obscure,
                    obscuringCharacter: '•',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: Theme.of(context).textTheme.bodyLarge!
                          .copyWith(color: AppColors.textHint),
                      prefixIcon: Icon(
                        widget.icon,
                        color: _focused
                            ? AppColors.gradientPink
                            : AppColors.textHint,
                        size: 20,
                      ),
                      suffixIcon: widget.obscureText
                          ? IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.validator != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    widget.validator!,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
