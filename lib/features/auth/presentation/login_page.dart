import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/const/theme/app_colors.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_event.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_state.dart';
import 'package:ripple/shared/widgets/auth_widgets/field_label.dart';
import 'package:ripple/shared/widgets/gradient_border_field.dart';
import 'package:ripple/shared/widgets/auth_widgets/gradient_button.dart';
import 'package:ripple/shared/widgets/auth_widgets/gradient_text.dart';
import 'package:ripple/shared/widgets/auth_widgets/or_divider.dart';
import 'package:ripple/shared/widgets/auth_widgets/social_pill.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  String? _emailError;
  String? _passwordError;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _emailError = null;
      _passwordError = null;

      if (_emailController.text.trim().isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(_emailController.text.trim())) {
        _emailError = 'Please enter a valid email';
      }

      if (_passwordController.text.trim().isEmpty) {
        _passwordError = 'Please enter your password';
      } else if (_passwordController.text.trim().length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      }
    });

    if (_emailError == null && _passwordError == null) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.gradientPink,
                  ),
                );
              }
            },
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo
                GradientText(
                  'Ripple.',
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(color: AppColors.textHint),
                ),

                const SizedBox(height: 52),

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

                const SizedBox(height: 20),

                // Password
                FieldLabel('Password'),
                const SizedBox(height: 8),
                GradientBorderField(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  pulseAnim: _pulseAnim,
                  validator: _passwordError,
                ),

                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.igGradient.createShader(b),
                      child: Text(
                        'Forgot password?',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Login button
                GradientButton(
                  label: state is LoadingRequested ? 'Logging In...' : 'Log In',
                  onTap: () => _submit(),
                ),

                const SizedBox(height: 20),

                // Divider
                OrDivider(),

                const SizedBox(height: 20),

                // Social
                Row(
                  children: [
                    Expanded(
                      child: SocialPill(
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Google',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SocialPill(
                        icon: Icons.apple,
                        label: 'Apple',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Sign up redirect
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // context.go('/signup')
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.textHint,
                        ),
                        children: [
                          WidgetSpan(
                            child: ShaderMask(
                              shaderCallback: (b) =>
                                  AppColors.igGradient.createShader(b),
                              child: InkWell(
                                splashFactory: NoSplash.splashFactory,
                                splashColor: AppColors.transparentBackground,
                                onTap: () => context.push('/signUp'),
                                child: Text(
                                  'Sign Up',
                                  style: Theme.of(context).textTheme.bodySmall!
                                      .copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
