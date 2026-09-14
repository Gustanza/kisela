import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/match_dialog.dart';
import '../widgets/swipe_card.dart';
import 'chat_screen.dart';
import 'profile_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final AppUser myProfile;

  const DiscoverScreen({super.key, required this.myProfile});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // The full batch fetched from Firestore. [_candidates] is drained as the
  // user swipes through it; once empty we refill from this pool (minus
  // anyone liked so far) instead of leaving the deck empty, so passed-on
  // people loop back around like a playlist repeating while liked people
  // drop out of the rotation for good.
  List<AppUser> _pool = [];
  List<AppUser> _candidates = [];
  bool _isLoading = true;
  GlobalKey<SwipeCardState> _frontCardKey = GlobalKey<SwipeCardState>();
  final Set<String> _shownMatchUids = {};
  final Set<String> _likedUids = {};

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
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
      _frontCardKey = GlobalKey<SwipeCardState>();
      _isLoading = false;
    });
  }

  Future<void> _handleSwiped(AppUser target, SwipeDirection direction) async {
    final myUid = _authService.currentUser!.uid;
    final matchedUid = await _firestoreService.recordSwipe(
      myUid: myUid,
      targetUid: target.uid,
      liked: direction == SwipeDirection.like,
    );

    setState(() {
      _candidates.removeWhere((c) => c.uid == target.uid);
      if (direction == SwipeDirection.like) _likedUids.add(target.uid);
      if (_candidates.isEmpty) {
        final remaining =
            _pool.where((u) => !_likedUids.contains(u.uid)).toList();
        if (remaining.isNotEmpty) {
          _candidates = remaining..shuffle();
        }
      }
      _frontCardKey = GlobalKey<SwipeCardState>();
    });

    if (matchedUid != null && mounted && _shownMatchUids.add(matchedUid)) {
      _showMatch(target);
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

  void _buttonSwipe(SwipeDirection direction) {
    _frontCardKey.currentState?.swipeProgrammatically(direction);
  }

  Future<void> _openProfile(AppUser user) async {
    final direction = await Navigator.of(context).push<SwipeDirection>(
      MaterialPageRoute(builder: (_) => ProfileDetailScreen(user: user)),
    );
    if (direction != null && mounted) {
      _frontCardKey.currentState?.swipeProgrammatically(direction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
          child: const Text(
            'kisela',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildDeck()),
            if (!_isLoading && _candidates.isNotEmpty) _buildActionButtons(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDeck() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_candidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No more people nearby right now',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCandidates,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _candidates.take(3).toList().reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Stack(
        alignment: Alignment.center,
        children: visible.map((user) {
          final isFront = user.uid == _candidates.first.uid;
          return SwipeCard(
            key: isFront ? _frontCardKey : null,
            user: user,
            isFront: isFront,
            onSwiped: (direction) => _handleSwiped(user, direction),
            onTap: isFront ? () => _openProfile(user) : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionButton(
            icon: Icons.close,
            color: AppColors.nope,
            onTap: () => _buttonSwipe(SwipeDirection.nope),
          ),
          const SizedBox(width: 28),
          _actionButton(
            icon: Icons.favorite,
            color: AppColors.like,
            onTap: () => _buttonSwipe(SwipeDirection.like),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black45,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 62,
          height: 62,
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}
