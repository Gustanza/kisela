import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme.dart';
import '../widgets/swipe_card.dart';

/// A full-screen, Tinder-style expanded view of a single user. When reached
/// by tapping their photo on the Discover deck, liking or passing pops back
/// with the chosen [SwipeDirection] so the caller can drive the same
/// swipe-recording/looping/match logic as an on-deck swipe. When [readOnly]
/// is set - viewing an existing match's profile from a chat, say - the
/// like/pass action bar is left off since that decision was already made.
class ProfileDetailScreen extends StatelessWidget {
  final AppUser user;
  final bool readOnly;

  const ProfileDetailScreen({
    super.key,
    required this.user,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildPhoto(context)),
                SliverToBoxAdapter(child: _buildInfo()),
                SliverToBoxAdapter(
                  child: SizedBox(height: readOnly ? 24 : 110),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _roundIconButton(
              icon: Icons.close,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          if (!readOnly)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActionBar(context),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.58;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          user.photoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: user.photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _placeholderPhoto(),
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                )
              : _placeholderPhoto(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderPhoto() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.person, size: 120, color: Colors.white),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${user.name}, ${user.age}',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (user.bio.isNotEmpty) ...[
            const Text(
              'About',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              user.bio,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionButton(
            icon: Icons.close,
            color: AppColors.nope,
            onTap: () => Navigator.of(context).pop(SwipeDirection.nope),
          ),
          const SizedBox(width: 32),
          _actionButton(
            icon: Icons.favorite,
            color: AppColors.like,
            onTap: () => Navigator.of(context).pop(SwipeDirection.like),
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

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.black45,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
