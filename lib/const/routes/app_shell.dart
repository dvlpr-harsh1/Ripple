import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/const/Strings/app_strings.dart';
import 'package:ripple/const/theme/app_colors.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ripple/features/auth/presentation/bloc/auth_event.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _showNav = false;
  double _fabOffsetX = 0.0;
  bool _isDragging = false;
  double _dragAccum = 0.0;
  bool _dragToClose = false;
  bool _isHolding = false;
  Timer? _holdTimer;

  // ✅ Save AuthBloc reference — safe to use in dispose/callbacks
  late AuthBloc _authBloc;

  late AnimationController _springController;
  late Animation<double> _springAnim;
  late AnimationController _rippleController;

  static const double _fabSize = 56.0;
  static const double _snapThreshold = 70.0;
  static const Duration _holdDelay = Duration(milliseconds: 300);

  // ── Layout constants ───────────────────────────────────────────
  static const double _navHeight = 65.0;
  static const double _navSideMargin = 20.0;
  static const double _navBottomGap = 0;
  static const double _fabNavGap = .0;
  static const double _fabRightMargin = 0;

  @override
  void initState() {
    super.initState();

    // ✅ Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // ✅ Save bloc reference while context is valid
    _authBloc = context.read<AuthBloc>();

    // ✅ Mark online immediately
    _setOnline(true);

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _springAnim = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_springController);
    _springController.addListener(() {
      if (mounted) setState(() => _fabOffsetX = _springAnim.value);
    });

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅
    _setOnline(false); // ✅ mark offline on exit
    _holdTimer?.cancel();
    _springController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  // ✅ App lifecycle — online/offline based on foreground state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _setOnline(false);
        break;
      default:
        break;
    }
  }

  // ✅ Updates isOnline field in Firestore users collection
  Future<void> _setOnline(bool isOnline) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection(AppStrings.firebaseCollection)
          .doc(uid)
          .update({'isOnline': isOnline});
    } catch (_) {
      // Silently ignore — user doc may not exist yet during signup flow
    }
  }

  // ── Hold handlers ──────────────────────────────────────────────
  void _onLongPressStart(LongPressStartDetails _) {
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDelay, () {
      if (mounted && !_isDragging) {
        setState(() => _isHolding = true);
        _rippleController.repeat();
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) => _clearHold();

  void _clearHold() {
    _holdTimer?.cancel();
    _rippleController
      ..stop()
      ..reset();
    if (mounted) setState(() => _isHolding = false);
  }

  // ── Rubber band + spring ───────────────────────────────────────
  double _rubberBand(double drag) => -(sqrt(drag) * 3.2);

  void _springBackThen({required bool reveal}) {
    _springController.duration = const Duration(milliseconds: 500);
    _springAnim = Tween<double>(begin: _fabOffsetX, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.elasticOut),
    );
    _springController
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) setState(() => _showNav = reveal);
      });
  }

  // ── FAB tap: shake → toggle nav ───────────────────────────────
  void _onFabTap() {
    if (_isDragging) return;
    _clearHold();
    _springController.stop();

    final bool willOpen = !_showNav;
    if (!willOpen) setState(() => _showNav = false);

    _springController.duration = const Duration(milliseconds: 600);
    _springAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -28.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -28.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_springController);

    _springController
      ..reset()
      ..forward().whenComplete(() {
        _springController.duration = const Duration(milliseconds: 500);
        if (mounted && willOpen) setState(() => _showNav = true);
      });
  }

  // ── Drag handlers ──────────────────────────────────────────────
  void _onHorizontalDragStart(DragStartDetails _) {
    _clearHold();
    _springController.stop();
    _springController.duration = const Duration(milliseconds: 500);
    _isDragging = true;
    _dragAccum = 0.0;
    _dragToClose = _showNav;
    setState(() => _showNav = false);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    _dragAccum = (_dragAccum - details.delta.dx).clamp(0.0, double.infinity);
    setState(() => _fabOffsetX = _rubberBand(_dragAccum));
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    _isDragging = false;
    _springBackThen(
      reveal: _dragToClose ? false : _dragAccum >= _snapThreshold,
    );
  }

  int _getIndexFromLocation() {
    final location = GoRouterState.of(context).fullPath ?? '';
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/notifications')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromLocation();
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final double navBottom = safeBottom + _navBottomGap;
    final double fabBottom = navBottom + _navHeight + _fabNavGap;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // ── Page content ────────────────────────────────────────
          widget.child,

          // ── Nav bar ─────────────────────────────────────────────
          Positioned(
            bottom: navBottom,
            left: _navSideMargin,
            right: _navSideMargin,
            child: AnimatedOpacity(
              opacity: _showNav ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: AnimatedSlide(
                offset: _showNav ? Offset.zero : const Offset(0, 0.12),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: Container(
                  height: _navHeight,
                  decoration: BoxDecoration(
                    // ✅ Solid dark surface — visible against all content
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        icon: CupertinoIcons.house_fill,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        onTap: () => context.go('/dashboard'),
                      ),
                      _NavItem(
                        icon: CupertinoIcons.search,
                        label: 'Search',
                        isActive: currentIndex == 1,
                        onTap: () => context.go('/search'),
                      ),
                      _NavItem(
                        icon: CupertinoIcons.bell_fill,
                        label: 'Alerts',
                        isActive: currentIndex == 2,
                        // ✅ Route to /notifications when you add that route
                        // For now falls back to dashboard
                        onTap: () => context.go('/dashboard'),
                      ),
                      _NavItem(
                        icon: CupertinoIcons.person_fill,
                        label: 'Profile',
                        isActive: currentIndex == 3,
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── FAB + ripple ────────────────────────────────────────
          Positioned(
            bottom: fabBottom,
            right: _fabRightMargin,
            child: Transform.translate(
              offset: Offset(_fabOffsetX, 0),
              child: GestureDetector(
                onTap: _onFabTap,
                // ✅ Use saved _authBloc — not context.read (safe in callbacks)
                onDoubleTap: () => _authBloc.add(AuthSignOutRequested()),
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: SizedBox(
                  width: _fabSize + 44,
                  height: _fabSize + 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple ring 1
                      if (_isHolding)
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (_, __) {
                            final t = _rippleController.value;
                            return Transform.scale(
                              scale: 1.0 + t * 0.85,
                              child: Container(
                                width: _fabSize,
                                height: _fabSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gradientPurple.withOpacity(
                                      (1.0 - t) * 0.75,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // Ripple ring 2
                      if (_isHolding)
                        AnimatedBuilder(
                          animation: _rippleController,
                          builder: (_, __) {
                            final t = (_rippleController.value + 0.45) % 1.0;
                            return Transform.scale(
                              scale: 1.0 + t * 0.85,
                              child: Container(
                                width: _fabSize,
                                height: _fabSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.gradientPink.withOpacity(
                                      (1.0 - t) * 0.5,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // FAB button
                      Container(
                        height: _fabSize,
                        width: _fabSize,
                        decoration: BoxDecoration(
                          gradient: AppColors.igGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gradientPurple.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: AnimatedRotation(
                          turns: _isDragging ? -0.08 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            CupertinoIcons.app_badge,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 75,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Gradient only when active, plain color when inactive
            if (isActive)
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    AppColors.igGradient.createShader(bounds),
                child: Icon(icon, size: 22, color: Colors.white),
              )
            else
              Icon(icon, size: 22, color: Colors.white30),

            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
