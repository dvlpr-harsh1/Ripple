import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ripple/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ripple/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:ripple/shared/common_widgets/custom_loading_widget.dart';
import 'package:ripple/shared/common_widgets/gradient_border_field.dart';

import '../../../const/spacing/spacing.dart';
import '../../../shared/widgets/dashboard_widgets/dashboard_card.dart';
import '../domain/entities/known_user_entity.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const _igGradient = LinearGradient(
    colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final Stream<List<KnownUserEntity>> _chatUsersStream;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late String? userId;
  late String? userId2;

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        body: Padding(
          padding: Spacing.screenSpacing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient title
              ShaderMask(
                shaderCallback: (bounds) =>
                    DashboardPage._igGradient.createShader(bounds),
                child: Text(
                  'Messages',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge!.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),

              // Search bar
              GradientBorderField(
                controller: _searchController,
                hint: 'Search',
                icon: Icons.search,
                pulseAnim: _pulseAnim,
                onChanged: (v) {
                  context.read<DashboardBloc>().add(
                    SearchUserRequested(query: v),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                            'All',
                            'Unread',
                            'Favourites',
                            'Best',
                            'Loved',
                            'Secret',
                            'Groups',
                          ]
                          .asMap()
                          .entries
                          .map(
                            (e) => _FilterChip(
                              label: e.value,
                              isSelected: e.key == 0,
                              gradient: DashboardPage._igGradient,
                            ),
                          )
                          .toList(),
                ),
              ),
              SizedBox(height: 12),
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoadingState) {
                    return Expanded(
                      child: Center(child: CustomLoadingWidget()),
                    );
                  }
                  if (state is DashboardErrorState) {
                    if (kDebugMode) {
                      print(state.message);
                    }
                    return Center(child: Text(state.message));
                  }
                  if (state is DashboardUsersState) {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: state.users.length,
                        itemBuilder: (context, index) {
                          final userEntity = state.users[index];
                          return GestureDetector(
                            onTap: () =>
                                context.push('/chat', extra: userEntity),
                            child: ChatCard(knownUserEntity: userEntity),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final LinearGradient gradient;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: Colors.white38),
              ),
            ),
    );
  }
}
