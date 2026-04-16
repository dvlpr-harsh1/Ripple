import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ripple/const/theme/app_colors.dart';

class SignInContact extends StatefulWidget {
  const SignInContact({super.key});

  @override
  State<SignInContact> createState() => _SignInContactState();
}

class _SignInContactState extends State<SignInContact>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _phoneController.addListener(() {
      final hasText = _phoneController.text.trim().isNotEmpty;
      if (hasText != _hasInput) setState(() => _hasInput = hasText);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo mark
              _GradientText(
                'Ripple.',
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a ripple.',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(),

              // Phone field
              Text(
                'Your phone number',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _GradientBorderInput(
                controller: _phoneController,
                hint: '+91 00000 00000',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                pulseAnim: _pulseAnim,
                isActive: _hasInput,
              ),

              const SizedBox(height: 20),

              // Primary CTA
              _GradientButton(
                label: 'Send OTP',
                enabled: _hasInput,
                onTap: () {},
              ),

              const SizedBox(height: 16),

              // Divider
              Row(
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
              ),

              const SizedBox(height: 16),

              // Social row — unique: icon-only pills, no text clutter
              Row(
                children: [
                  Expanded(
                    child: _SocialPill(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Google',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialPill(
                      icon: Icons.apple,
                      label: 'Apple',
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Footer
              Center(
                child: Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gradient border input ─────────────────────────────────────────────────────
class _GradientBorderInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final Animation<double> pulseAnim;
  final bool isActive;

  const _GradientBorderInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.inputFormatters,
    required this.pulseAnim,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gradientPurple.withOpacity(
                  isActive ? 1.0 : pulseAnim.value * 0.5,
                ),
                AppColors.gradientPink.withOpacity(
                  isActive ? 1.0 : pulseAnim.value * 0.5,
                ),
                AppColors.gradientOrange.withOpacity(
                  isActive ? 1.0 : pulseAnim.value * 0.5,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(1.5), // border thickness
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(13),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 0.5,
                ),
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Gradient fill button ──────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: enabled
                ? AppColors.igGradient
                : const LinearGradient(
                    colors: [Colors.white24, Colors.white24],
                  ),
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
      ),
    );
  }
}

// ── Social pill ───────────────────────────────────────────────────────────────
class _SocialPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient text ─────────────────────────────────────────────────────────────
class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _GradientText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.igGradient.createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
