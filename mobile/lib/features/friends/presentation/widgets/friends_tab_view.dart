import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/websocket_service.dart';
import '../../domain/entities/friend.dart';
import '../blocs/friends_bloc.dart';

class FriendsTabView extends StatelessWidget {
  final ValueNotifier<int>? subTabNotifier;
  const FriendsTabView({super.key, this.subTabNotifier});

  @override
  Widget build(BuildContext context) => _FriendsContent(subTabNotifier: subTabNotifier);
}

class _FriendsContent extends StatefulWidget {
  final ValueNotifier<int>? subTabNotifier;
  const _FriendsContent({this.subTabNotifier});

  @override
  State<_FriendsContent> createState() => _FriendsContentState();
}

class _FriendsContentState extends State<_FriendsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.subTabNotifier?.addListener(_onSubTabChanged);
  }

  void _onSubTabChanged() {
    final idx = widget.subTabNotifier!.value;
    if (_tabController.index != idx) _tabController.animateTo(idx);
  }

  @override
  void dispose() {
    widget.subTabNotifier?.removeListener(_onSubTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, state) {
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('AMIS', style: AppTextStyles.h2.copyWith(color: AppColors.yellow)),
              ),
              const SizedBox(height: 16),
              // Champ de recherche
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (q) => context.read<FriendsBloc>().add(FriendsSearchChanged(q)),
                  onClear: () {
                    _searchController.clear();
                    context.read<FriendsBloc>().add(FriendsSearchChanged(''));
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (state.isSearching)
                Expanded(child: _SearchResults(results: state.searchResults))
              else ...[
                // Onglets Amis / Demandes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTabBar(state.requests.length),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _FriendsMainTab(
                        friends: state.friends,
                        suggestions: state.suggestions,
                        status: state.status,
                      ),
                      _RequestsList(requests: state.requests),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(int requestCount) {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.yellow,
      labelColor: AppColors.yellow,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelStyle: AppTextStyles.bodySm.copyWith(fontSize: 12),
      dividerColor: Colors.white12,
      tabs: [
        const Tab(text: 'MES AMIS'),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DEMANDES'),
              if (requestCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$requestCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Search field ────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Rechercher un joueur…',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ─── Friends main tab (online + suggestions + list) ──────────────────────────

class _FriendsMainTab extends StatelessWidget {
  final List<Friend> friends;
  final List<UserSearchResult> suggestions;
  final FriendsStatus status;

  const _FriendsMainTab({required this.friends, required this.suggestions, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == FriendsStatus.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }

    final onlineFriends = friends
        .where((f) => f.presence == Presence.online || f.presence == Presence.inGame)
        .toList();

    return CustomScrollView(
      slivers: [
        // Section amis en ligne
        if (onlineFriends.isNotEmpty) ...[
          _sectionHeader('EN LIGNE (${onlineFriends.length})'),
          SliverToBoxAdapter(child: _OnlineFriendsRow(friends: onlineFriends)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // Section suggestions
        if (suggestions.isNotEmpty) ...[
          _sectionHeader('SUGGESTIONS'),
          SliverToBoxAdapter(child: _SuggestionsRow(suggestions: suggestions)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],

        // Liste complète
        if (friends.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_off_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text('Aucun ami pour l\'instant', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Recherche des joueurs ci-dessus', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          )
        else ...[
          _sectionHeader('TOUS MES AMIS'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: friends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _FriendTile(friend: friends[i]),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _sectionHeader(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(title,
              style: const TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      );
}

// ─── Online friends horizontal row ───────────────────────────────────────────

class _OnlineFriendsRow extends StatelessWidget {
  final List<Friend> friends;
  const _OnlineFriendsRow({required this.friends});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: friends.length,
        itemBuilder: (context, i) {
          final f = friends[i];
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {
                final bloc = context.read<FriendsBloc>();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: FriendProfileSheet(friend: f),
                  ),
                );
              },
              child: _OnlineFriendAvatar(friend: f),
            ),
          );
        },
      ),
    );
  }
}

class _OnlineFriendAvatar extends StatelessWidget {
  final Friend friend;
  const _OnlineFriendAvatar({required this.friend});

  @override
  Widget build(BuildContext context) {
    final dotColor = friend.presence == Presence.inGame ? AppColors.yellow : AppColors.green;
    final parts = (friend.fullName ?? friend.username).trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : friend.username.substring(0, friend.username.length.clamp(0, 2)).toUpperCase();

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 2),
                boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)],
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.yellow,
                child: Text(initials,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1A0F08), width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          friend.username.length > 7 ? '${friend.username.substring(0, 6)}…' : friend.username,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Suggestions horizontal row ──────────────────────────────────────────────

class _SuggestionsRow extends StatelessWidget {
  final List<UserSearchResult> suggestions;
  const _SuggestionsRow({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: suggestions.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _SuggestionCard(result: suggestions[i]),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final UserSearchResult result;
  const _SuggestionCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isNone = result.friendshipStatus == 'NONE';
    final isSent = result.friendshipStatus == 'PENDING_SENT';

    return Container(
      width: 128,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Avatar(name: result.fullName ?? result.username, size: 48),
          const SizedBox(height: 8),
          Text(
            result.username.length > 10 ? '${result.username.substring(0, 9)}…' : result.username,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.yellow, size: 11),
              const SizedBox(width: 3),
              Text('${result.elo}', style: const TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          if (isSent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Envoyé', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            )
          else if (isNone)
            GestureDetector(
              onTap: () => context.read<FriendsBloc>().add(FriendRequestSent(result.id)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_outlined, color: AppColors.green, size: 13),
                    SizedBox(width: 4),
                    Text('Ajouter', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProfileSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            _Avatar(name: friend.fullName ?? friend.username, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.username, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _PresenceDot(presence: friend.presence),
                      const SizedBox(width: 4),
                      Text(_presenceLabel(friend.presence), style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(width: 8),
                      Text('ELO ${friend.elo}', style: TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
              onPressed: () => _showProfileSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  String _presenceLabel(Presence p) => switch (p) {
        Presence.online => 'En ligne',
        Presence.inGame => 'En jeu',
        Presence.offline => 'Hors ligne',
      };

  void _showProfileSheet(BuildContext context) {
    final bloc = context.read<FriendsBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: FriendProfileSheet(friend: friend),
      ),
    );
  }

}

// ─── Friend profile bottom sheet ─────────────────────────────────────────────

class FriendProfileSheet extends StatelessWidget {
  final Friend friend;
  const FriendProfileSheet({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    final presenceColor = switch (friend.presence) {
      Presence.online => AppColors.green,
      Presence.inGame => AppColors.yellow,
      Presence.offline => AppColors.textSecondary,
    };
    final presenceLabel = switch (friend.presence) {
      Presence.online => 'En ligne',
      Presence.inGame => 'En jeu',
      Presence.offline => 'Hors ligne',
    };

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E110A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),

          // Avatar + infos
          _Avatar(name: friend.fullName ?? friend.username, size: 64),
          const SizedBox(height: 12),
          Text(friend.username, style: AppTextStyles.h2.copyWith(fontSize: 20, color: Colors.white)),
          if (friend.fullName != null) ...[
            const SizedBox(height: 2),
            Text(friend.fullName!, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: presenceColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(presenceLabel, style: TextStyle(color: presenceColor, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Icon(Icons.star, color: AppColors.yellow, size: 14),
              const SizedBox(width: 4),
              Text('ELO ${friend.elo}', style: const TextStyle(color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Actions
          _SheetAction(
            icon: Icons.sports_esports_outlined,
            label: 'Défier',
            color: AppColors.green,
            onTap: () {
              Navigator.pop(context);
              _sendChallenge(context);
            },
          ),
          _SheetAction(
            icon: Icons.person_outline,
            label: 'Voir le profil',
            onTap: () {
              Navigator.pop(context);
              // TODO: naviguer vers /profile/:id quand la page existe
            },
          ),
          _SheetAction(
            icon: Icons.person_remove_outlined,
            label: 'Supprimer de mes amis',
            color: AppColors.red,
            onTap: () {
              Navigator.pop(context);
              _confirmRemove(context);
            },
          ),
        ],
      ),
    );
  }

  void _sendChallenge(BuildContext context) {
    sl<WebSocketService>().sendMessage({
      'type': 'game.challenge.send',
      'targetId': friend.id,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Défi envoyé à ${friend.username}…'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 30),
        action: SnackBarAction(
          label: 'Annuler',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D1810),
        title: const Text('Supprimer ami ?', style: TextStyle(color: Colors.white)),
        content: Text('Retirer ${friend.username} de ta liste ?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<FriendsBloc>().add(FriendRemoved(friend.id));
            },
            child: Text('Supprimer', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ─── Requests list ────────────────────────────────────────────────────────────

class _RequestsList extends StatelessWidget {
  final List<FriendRequest> requests;
  const _RequestsList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Aucune demande en attente', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _RequestTile(request: requests[i]),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final from = request.from;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withAlpha(60)),
      ),
      child: Row(
        children: [
          _Avatar(name: from.fullName ?? from.username, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(from.username, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('ELO ${from.elo}', style: TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Row(
            children: [
              _ActionButton(
                icon: Icons.check,
                color: AppColors.green,
                onTap: () => context.read<FriendsBloc>().add(
                      FriendRequestAccepted(requestId: request.requestId, fromId: from.id),
                    ),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.close,
                color: AppColors.red,
                onTap: () => context.read<FriendsBloc>().add(
                      FriendRequestDeclined(requestId: request.requestId, fromId: from.id),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Search results ───────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<UserSearchResult> results;
  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Text('Aucun résultat', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _SearchResultTile(result: results[i]),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final UserSearchResult result;
  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _Avatar(name: result.fullName ?? result.username, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.username, style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('ELO ${result.elo}', style: TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _friendshipButton(context, result),
        ],
      ),
    );
  }

  Widget _friendshipButton(BuildContext context, UserSearchResult r) {
    return switch (r.friendshipStatus) {
      'FRIENDS' => Row(
          children: [
            Icon(Icons.check, color: AppColors.green, size: 16),
            const SizedBox(width: 4),
            Text('Amis', style: TextStyle(color: AppColors.green, fontSize: 12)),
          ],
        ),
      'PENDING_SENT' => Text('Envoyé', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      'PENDING_RECEIVED' => TextButton(
          onPressed: () {},
          child: Text('Accepter', style: TextStyle(color: AppColors.yellow, fontSize: 12)),
        ),
      _ => _ActionButton(
          icon: Icons.person_add_outlined,
          color: AppColors.green,
          onTap: () => context.read<FriendsBloc>().add(FriendRequestSent(r.id)),
        ),
    };
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
      child: Center(
        child: Text(initials, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: size * 0.35)),
      ),
    );
  }
}

class _PresenceDot extends StatelessWidget {
  final Presence presence;
  const _PresenceDot({required this.presence});

  @override
  Widget build(BuildContext context) {
    final color = switch (presence) {
      Presence.online => AppColors.green,
      Presence.inGame => AppColors.yellow,
      Presence.offline => AppColors.textSecondary,
    };
    return Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
