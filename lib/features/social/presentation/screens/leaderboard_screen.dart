import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/localization_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/leaderboard_user.dart';
import '../providers/social_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final leaderboardState = ref.watch(leaderboardProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final profileState = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboardTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.leaderboardSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: profileState.when(
          data: (profile) => DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: l10n.leaderboardRussiaTab),
                    Tab(text: profile?.city ?? l10n.leaderboardCityTab),
                  ],
                ),
                Expanded(
                  child: leaderboardState.when(
                    data: (users) {
                      final cityUsers = _filterCityUsers(users, profile);
                      return TabBarView(
                        children: [
                          _LeaderboardList(
                            users: users,
                            currentUserId: currentUserId,
                            emptyMessage: l10n.leaderboardEmpty,
                          ),
                          _LeaderboardList(
                            users: cityUsers,
                            currentUserId: currentUserId,
                            emptyMessage: profile?.city == null
                                ? l10n.profileCityRequired
                                : l10n.leaderboardCityEmpty(profile!.city!),
                          ),
                        ],
                      );
                    },
                    error: (error, _) {
                      final message = error is AppException
                          ? error.code.localize(l10n)
                          : l10n.errorUnknown;

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(message, textAlign: TextAlign.center),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            ),
          ),
          error: (error, _) {
            final message = error is AppException
                ? error.code.localize(l10n)
                : l10n.errorUnknown;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(message, textAlign: TextAlign.center),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  List<LeaderboardUser> _filterCityUsers(
    List<LeaderboardUser> users,
    UserProfile? profile,
  ) {
    final city = profile?.city?.trim();
    if (city == null || city.isEmpty) {
      return const <LeaderboardUser>[];
    }

    return users
        .where((user) => user.city?.trim().toLowerCase() == city.toLowerCase())
        .toList(growable: false);
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.users,
    required this.currentUserId,
    required this.emptyMessage,
  });

  final List<LeaderboardUser> users;
  final String? currentUserId;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return _LeaderboardTile(
          position: index + 1,
          user: user,
          isCurrentUser: user.userId == currentUserId,
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.position,
    required this.user,
    required this.isCurrentUser,
  });

  final int position;
  final LeaderboardUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isCurrentUser
          ? colorScheme.primaryContainer.withValues(alpha: 0.6)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _rankColor(position),
              foregroundColor: Colors.white,
              child: Text('$position'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (isCurrentUser)
                        Chip(
                          label: Text(l10n.leaderboardYou),
                          visualDensity: VisualDensity.compact,
                        ),
                      if ((user.city ?? '').isNotEmpty)
                        Chip(
                          label: Text(user.city!),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _StatChip(label: l10n.leaderboardPoints('${user.score}')),
                      _StatChip(
                        label: l10n.leaderboardWorkouts(
                          '${user.workoutsCount}',
                        ),
                      ),
                      _StatChip(
                        label: l10n.leaderboardSteps('${user.stepsCount}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int position) {
    return switch (position) {
      1 => const Color(0xFFD97706),
      2 => const Color(0xFF6B7280),
      3 => const Color(0xFFB45309),
      _ => const Color(0xFF2563EB),
    };
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label),
      ),
    );
  }
}
