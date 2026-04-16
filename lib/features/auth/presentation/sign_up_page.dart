import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/const/theme/app_colors.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_event.dart';
import 'package:ripple/shared/widgets/auth_widgets/field_label.dart';
import 'package:ripple/shared/widgets/gradient_border_field.dart';
import 'package:ripple/shared/widgets/auth_widgets/gradient_button.dart';
import 'package:ripple/shared/widgets/auth_widgets/gradient_text.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Avatar pick placeholder
  bool _avatarPicked = false;

  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nameError = null;
      _usernameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Please enter your name';
      }

      if (_usernameController.text.trim().isEmpty) {
        _usernameError = 'Please enter your username';
      } else if (_usernameController.text.trim().length < 3) {
        _usernameError = 'Username must be at least 3 characters';
      }

      if (_emailController.text.trim().isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(_emailController.text.trim())) {
        _emailError = 'Please enter a valid email';
      }

      if (_phoneController.text.trim().isEmpty) {
        _phoneError = 'Please enter your phone number';
      } else if (_phoneController.text.trim().length != 10) {
        _phoneError = 'Please enter a valid 10-digit phone number';
      }

      if (_passwordController.text.trim().isEmpty) {
        _passwordError = 'Please enter your password';
      } else if (_passwordController.text.trim().length < 8) {
        _passwordError = 'Password must be at least 8 characters';
      }

      if (_confirmController.text.trim().isEmpty) {
        _confirmError = 'Please confirm your password';
      } else if (_confirmController.text.trim() !=
          _passwordController.text.trim()) {
        _confirmError = 'Passwords do not match';
      }
    });

    if (_nameError == null &&
        _usernameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _confirmError == null) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          confirmPassword: _confirmController.text.trim(),
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phoneNum: _phoneController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Back + title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GradientText(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Avatar picker — unique: tap to pick, gradient ring
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _avatarPicked = !_avatarPicked),
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) {
                      return Container(
                        width: 92,
                        height: 92,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gradientPurple.withOpacity(
                                _pulseAnim.value,
                              ),
                              AppColors.gradientPink.withOpacity(
                                _pulseAnim.value,
                              ),
                              AppColors.gradientOrange.withOpacity(
                                _pulseAnim.value,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.inputFill,
                            shape: BoxShape.circle,
                          ),
                          child: _avatarPicked
                              ? const CircleAvatar(
                                  backgroundColor: AppColors.inputFill,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: AppColors.textSecondary,
                                    size: 36,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (b) =>
                                          AppColors.igGradient.createShader(b),
                                      child: const Icon(
                                        Icons.add_a_photo_outlined,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Photo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall!
                                          .copyWith(color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Full name
              FieldLabel('Full name'),
              const SizedBox(height: 8),
              GradientBorderField(
                controller: _nameController,
                hint: 'Harsh Rajput',
                icon: Icons.person_outline_rounded,
                pulseAnim: _pulseAnim,
                validator: _nameError,
              ),

              const SizedBox(height: 18),

              // Username
              FieldLabel('Username'),
              const SizedBox(height: 8),
              GradientBorderField(
                controller: _usernameController,
                hint: '@harsh_rajput',
                icon: Icons.alternate_email_rounded,
                pulseAnim: _pulseAnim,
                validator: _usernameError,
              ),

              const SizedBox(height: 18),

              // Email
              FieldLabel('Email address'),
              const SizedBox(height: 8),
              GradientBorderField(
                controller: _emailController,
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.mail_outline_rounded,
                pulseAnim: _pulseAnim,
                validator: _emailError,
              ),

              const SizedBox(height: 18),

              // Phone
              FieldLabel('Phone number'),
              const SizedBox(height: 8),
              GradientBorderField(
                controller: _phoneController,
                hint: '+91 00000 00000',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                icon: Icons.phone_outlined,
                pulseAnim: _pulseAnim,
                validator: _phoneError,
              ),

              const SizedBox(height: 18),

              // Password
              FieldLabel('Password'),
              const SizedBox(height: 8),
              GradientBorderField(
                controller: _passwordController,
                hint: 'Min. 8 characters',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                pulseAnim: _pulseAnim,
                validator: _passwordError,
              ),

              const SizedBox(height: 18),

              // Confirm password
              FieldLabel('Confirm password'),
              const SizedBox(height: 8),
              GradientBorderField(
                controller: _confirmController,
                hint: 'Repeat password',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
                pulseAnim: _pulseAnim,
                validator: _confirmError,
              ),

              const SizedBox(height: 32),

              // Terms checkbox
              _TermsRow(),

              const SizedBox(height: 28),

              // Create account button
              GradientButton(label: 'Create Account', onTap: () => _submit()),

              const SizedBox(height: 24),

              // Login redirect
              Center(
                child: GestureDetector(
                  onTap: () => context.pop('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.textHint,
                      ),
                      children: [
                        WidgetSpan(
                          child: ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.igGradient.createShader(b),
                            child: Text(
                              'Log In',
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Terms row ─────────────────────────────────────────────────────────────────
class _TermsRow extends StatefulWidget {
  @override
  State<_TermsRow> createState() => _TermsRowState();
}

class _TermsRowState extends State<_TermsRow> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _accepted = !_accepted),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: _accepted ? AppColors.igGradient : null,
              border: Border.all(
                color: _accepted ? Colors.transparent : Colors.white24,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _accepted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.textHint,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
