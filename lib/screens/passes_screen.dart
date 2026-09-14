import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/match_dialog.dart';
import 'chat_screen.dart';

class PassesScreen extends StatefulWidget {
  final AppUser myProfile;

  const PassesScreen({super.key, required this.myProfile});

  @override
  State<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Future<void> _like(String targetUid, AppUser targetUser) async {
    final myUid = _authService.currentUser!.uid;
    final matchedUid = await _firestoreService.recordSwipe(
      myUid: myUid,
      targetUid: targetUid,
      liked: true,
    );
    if (matchedUid != null && mounted) {
      _showMatch(targetUser);
    }
  }

  Future<void> _rePass(String targetUid) async {
    final myUid = _authService.currentUser!.uid;
    await _firestoreService.rePass(myUid: myUid, targetUid: targetUid);
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
            builder: (_) => ChatScreen(matchId: matchId, otherUser: matchedUser),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Passed')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.passesStream(myUid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "No one here. Anyone you pass on in Discover shows up\n"
                  "here, so you can change your mind later.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final targetUid = docs[index].id;

              return FutureBuilder<AppUser?>(
                future: _firestoreService.getProfile(targetUid),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const SizedBox.shrink();
                  }
                  final user = userSnapshot.data!;

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(
                      '${user.name}, ${user.age}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      user.bio.isNotEmpty ? user.bio : 'No bio yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _circleButton(
                          icon: Icons.close,
                          color: AppColors.nope,
                          onTap: () => _rePass(targetUid),
                        ),
                        const SizedBox(width: 10),
                        _circleButton(
                          icon: Icons.favorite,
                          color: AppColors.like,
                          onTap: () => _like(targetUid, user),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      shape: const CircleBorder(),
      color: color.withValues(alpha: 0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
