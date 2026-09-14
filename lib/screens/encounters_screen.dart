import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/match_dialog.dart';
import '../widgets/swipe_card.dart' show SwipeDirection;
import 'chat_screen.dart';
import 'profile_detail_screen.dart';

/// A grid/carousel style browsing view over the same candidate pool as
/// [DiscoverScreen]'s swipe deck - an alternative for people who'd rather
/// scan a list than swipe one card at a time.
class EncountersScreen extends StatefulWidget {
  final AppUser myProfile;

  const EncountersScreen({super.key, required this.myProfile});

  @override
  State<EncountersScreen> createState() => _EncountersScreenState();
}

class _EncountersScreenState extends State<EncountersScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // Same loop-instead-of-dead-end approach as DiscoverScreen: [_pool] holds
  // the full fetched batch, and once [_candidates] is drained it's refilled
  // (reshuffled) from the pool minus anyone liked so far, instead of
  // leaving an empty screen.
  List<AppUser> _pool = [];
  List<AppUser> _candidates = [];
  bool _isLoading = true;
  final Set<String> _shownMatchUids = {};
  final Set<String> _likedUids = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final myUid = _authService.currentUser!.uid;
    final candidates = await _firestoreService.getDiscoverCandidates(
      myUid,
      myGender: widget.myProfile.gender,
    );
    if (!mounted) return;
    setState(() {
      _pool = candidates;
      _candidates = List.of(candidates);
      _likedUids.clear();
      _isLoading = false;
    });
  }

  Future<void> _like(AppUser target) async {
    final myUid = _authService.currentUser!.uid;
    final matchedUid = await _firestoreService.recordSwipe(
      myUid: myUid,
      targetUid: target.uid,
      liked: true,
    );
    if (!mounted) return;
    setState(() {
      _candidates.removeWhere((c) => c.uid == target.uid);
      _likedUids.add(target.uid);
      if (_candidates.isEmpty) {
        final remaining = _pool
            .where((u) => !_likedUids.contains(u.uid))
            .toList();
        if (remaining.isNotEmpty) {
          _candidates = remaining..shuffle();
        }
      }
    });
    if (matchedUid != null && _shownMatchUids.add(matchedUid)) {
      _showMatch(target);
    }
  }

  Future<void> _pass(AppUser target) async {
    final myUid = _authService.currentUser!.uid;
    await _firestoreService.recordSwipe(
      myUid: myUid,
      targetUid: target.uid,
      liked: false,
    );
    if (!mounted) return;
    setState(() {
      _candidates.removeWhere((c) => c.uid == target.uid);
      if (_candidates.isEmpty) {
        final remaining = _pool
            .where((u) => !_likedUids.contains(u.uid))
            .toList();
        if (remaining.isNotEmpty) {
          _candidates = remaining..shuffle();
        }
      }
    });
  }

  Future<void> _openProfile(AppUser user) async {
    final direction = await Navigator.of(context).push<SwipeDirection>(
      MaterialPageRoute(builder: (_) => ProfileDetailScreen(user: user)),
    );
    if (!mounted || direction == null) return;
    if (direction == SwipeDirection.like) {
      _like(user);
    } else {
      _pass(user);
    }
  }

  void _showMatch(AppUser matchedUser) {
    showMatchDialog(
      context: context,
      me: widget.myProfile,
      them: matchedUser,
      onSendMessage: () {
        final matchId = FirestoreService.matchIdFor(
          widget.myProfile.uid,
          matchedUser.uid,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              matchId: matchId,
              otherUser: matchedUser,
              myProfile: widget.myProfile,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encounters')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _candidates.isEmpty
            ? _buildEmpty()
            : _buildContent(),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 120),
          child: Center(
            child: Text(
              'No one new to show right now',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final suggested = _candidates.take(5).toList();
    final everyone = _candidates.skip(5).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSuggestedBanner(suggested)),
        if (everyone.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Everyone',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _EveryoneTile(
                  user: everyone[index],
                  onLike: () => _like(everyone[index]),
                  onTap: () => _openProfile(everyone[index]),
                ),
                childCount: everyone.length,
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildSuggestedBanner(List<AppUser> suggested) {
    if (suggested.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.07),
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggested for you today',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              'A fresh batch of people to meet, picked just for you.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggested.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _SuggestedCard(
                user: suggested[index],
                onLike: () => _like(suggested[index]),
                onTap: () => _openProfile(suggested[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLike;
  final VoidCallback onTap;

  const _SuggestedCard({
    required this.user,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 190,
          height: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              user.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey[300]),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.5, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${user.name}, ${user.age}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.bio.isNotEmpty)
                            Text(
                              user.bio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onLike,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.favorite,
                            color: AppColors.like,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EveryoneTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLike;
  final VoidCallback onTap;

  const _EveryoneTile({
    required this.user,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  user.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              Container(color: Colors.grey[300]),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Material(
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onLike,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.favorite,
                            color: AppColors.like,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${user.name}, ${user.age}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
