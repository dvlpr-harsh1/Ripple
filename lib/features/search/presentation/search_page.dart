import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ripple/const/spacing/spacing.dart';
import 'package:ripple/const/theme/app_colors.dart';
import 'package:ripple/features/search/domain/entities/unknown_user_entity.dart';
import 'package:ripple/features/search/presentation/bloc/search_bloc.dart';
import 'package:ripple/features/search/presentation/bloc/search_event.dart';
import 'package:ripple/features/search/presentation/bloc/search_state.dart';
import 'package:ripple/shared/common_widgets/gradient_border_field.dart';

import '../../../shared/common_widgets/custom_loading_widget.dart';
import '../../../shared/widgets/search_widgets/search_card.dart';
import '../../chat/data/repositories/chat_repository_impl.dart';
import '../../dashboard/domain/entities/known_user_entity.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchUserController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final _chatRepo = ChatRepositoryImpl(); 
  final Set<String> _addedUsers = {};  

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
    _searchUserController.dispose();
    super.dispose();
  }

  // ✅ Core logic — create chat then navigate
  Future<void> _onAddUser(UnknownUserEntity user) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    // 1. Create the chat document in Firestore if it doesn't exist
    await _chatRepo.createChatIfNotExists(
      myUid: myUid,
      otherUid: user.id,
    );

    // 2. Mark as added locally for UI feedback
    setState(() => _addedUsers.add(user.id));

    // 3. Navigate to chat page
    if (mounted) {
      context.push('/chat', extra: user.toKnownUser());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Padding(
          padding: Spacing.screenSpacing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientBorderField(
                controller: _searchUserController,
                hint: 'Search name or @username',
                icon: Icons.search,
                pulseAnim: _pulseAnim,
                onChanged: (v) {
                  context.read<SearchBloc>().add(SearchRequested(query: v));
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (state is SearchLoadingState) {
                      return  Center(child: CustomLoadingWidget());
                    }
                    if (state is SearchResultState) {
                      if (state.users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (b) =>
                                    AppColors.igGradient.createShader(b),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 52,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No one found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge!
                                    .copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try a different name or @username',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: AppColors.textHint),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: state.users.length,
                        itemBuilder: (context, i) {
                          final user = state.users[i];
                          final isAdded = _addedUsers.contains(user.id);
                          return SearchCard(
                            cardEntity: user,
                            isAdded: isAdded,       
                            onAdd: isAdded
                                ? () {}            
                                : () => _onAddUser(user),
                          );
                        },
                      );
                    }
                    if (state is SearchErrorState) {
                      return Center(child: Text(state.message));
                    }
                    return EmptyState(
                      pulseAnim: _pulseAnim,
                      onChipTap: (label) {
                        _searchUserController.text = label;
                        _searchUserController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: label.length),
                        );
                        context
                            .read<SearchBloc>()
                            .add(SearchRequested(query: label));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE — shown before user types anything
// ─────────────────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final Animation<double> pulseAnim;
  final Function(String) onChipTap;

  const EmptyState({required this.pulseAnim, required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Quick search suggestion chips
          Text(
            'Try searching for',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Friends', 'Colleagues', 'Designers', 'Developers']
                .map(
                  (tag) => GestureDetector(
                    onTap: () => onChipTap(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.textPrimary.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 32),

          // Vibe board section header
          Row(
            children: [
              Text(
                'Vibes right now',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(width: 8),
              // Subtle live indicator
              AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, __) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.online.withOpacity(pulseAnim.value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING VIEW — shown while BLoC is fetching
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomLoadingWidget(itemSize: 10, itemDistance: 4),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULTS VIEW — shown when BLoC returns results
// Replace mockResults with state.results from BLoC
// ─────────────────────────────────────────────────────────────────────────────
class ResultsView extends StatelessWidget {
  final List<UnknownUserEntity> userResult;
  final Set<String> addedUsers;
  final Set<String> wavedUsers;
  final Function(String) onAdd;
  final Function(String) onWave;

  const ResultsView({
    required this.userResult,
    required this.addedUsers,
    required this.wavedUsers,
    required this.onAdd,
    required this.onWave,
  });

  @override
  Widget build(BuildContext context) {
    if (userResult.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.igGradient.createShader(b),
              child: const Icon(
                Icons.search_off_rounded,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No one found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different name or @username',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: userResult.length,
      itemBuilder: (context, i) {
        final user = userResult[i];
        return _UserResultCard(
          user: user,
          isAdded: addedUsers.contains(user.id),
          hasWaved: wavedUsers.contains(user.id),
          onAdd: () => onAdd(user.id),
          onWave: () => onWave(user.id),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIBE CARD — horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────
class _VibeCard extends StatelessWidget {
  final KnownUserEntity user;
  const _VibeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = user.name[0].toUpperCase();
    return Container(
      width: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AvatarRing(initial: initial, size: 42),
          const SizedBox(height: 6),
          Text(
            user.name.split(' ')[0],
            style: Theme.of(
              context,
            ).textTheme.labelSmall!.copyWith(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            user.badge,
            style: const TextStyle(fontSize: 9, color: AppColors.textHint),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT USER ROW — used in "Recently active" section
// ─────────────────────────────────────────────────────────────────────────────
class _CompactUserRow extends StatelessWidget {
  final KnownUserEntity user;
  const _CompactUserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _AvatarRing(initial: user.name[0].toUpperCase(), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user.username,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          // Vibe pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gradientPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.badge,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.gradientPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER RESULT CARD — full card in search results
// ─────────────────────────────────────────────────────────────────────────────
class _UserResultCard extends StatelessWidget {
  final UnknownUserEntity user;
  final bool isAdded;
  final bool hasWaved;
  final VoidCallback onAdd;
  final VoidCallback onWave;

  const _UserResultCard({
    required this.user,
    required this.isAdded,
    required this.hasWaved,
    required this.onAdd,
    required this.onWave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdded
              ? AppColors.gradientPurple.withOpacity(0.4)
              : AppColors.textPrimary.withOpacity(0.05),
          width: isAdded ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        children: [
          _AvatarRing(initial: user.name[0].toUpperCase(), size: 52),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.username,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: AppColors.textHint),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 11,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 5),
                // Vibe pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gradientPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Add + Wave buttons
          Column(
            children: [
              // Add button
              GestureDetector(
                onTap: isAdded ? null : onAdd,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isAdded ? null : AppColors.igGradient,
                    color: isAdded ? AppColors.inputFill : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isAdded
                        ? Border.all(
                            color: AppColors.textPrimary.withOpacity(0.1),
                          )
                        : null,
                  ),
                  child: Text(
                    isAdded ? 'Added ✓' : 'Add',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: isAdded
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Wave button — tap once, shows "Waved 👋", disables
              GestureDetector(
                onTap: hasWaved ? null : onWave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hasWaved
                        ? AppColors.inputFill
                        : AppColors.gradientPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasWaved
                          ? AppColors.textPrimary.withOpacity(0.08)
                          : AppColors.gradientPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    hasWaved ? 'Waved 👋' : 'Wave',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: hasWaved
                          ? AppColors.textHint
                          : AppColors.gradientPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE AVATAR RING — same style as ChatCard's _Avatar
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarRing extends StatelessWidget {
  final String initial;
  final double size;

  const _AvatarRing({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundColor: AppColors.gradientPurple.withOpacity(0.2),
        child: Text(
          initial,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: AppColors.textPrimary,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
