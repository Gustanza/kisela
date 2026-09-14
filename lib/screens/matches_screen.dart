import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'profile_detail_screen.dart';

class MatchesScreen extends StatefulWidget {
  final AppUser myProfile;

  const MatchesScreen({super.key, required this.myProfile});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final myUid = _authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.matchesStream(myUid),
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
                  'No matches yet. Keep swiping!',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 88, color: Color(0xFFEFEFEF)),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final matchId = docs[index].id;
              final users = List<String>.from(data['users'] ?? []);
              final otherUid = users.firstWhere(
                (u) => u != myUid,
                orElse: () => '',
              );
              if (otherUid.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<AppUser?>(
                future: _firestoreService.getProfile(otherUid),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const SizedBox.shrink();
                  }
                  final otherUser = userSnapshot.data!;
                  final lastMessage = data['lastMessage'] as String? ?? '';
                  final lastMessageAt = data['lastMessageAt'] as Timestamp?;
                  final hasMessage = lastMessage.isNotEmpty;

                  // A plain ListTile wraps its whole row (leading included)
                  // in one InkWell, so a nested tap handler on the avatar
                  // never wins the gesture arena against the tile's own
                  // onTap. Building the row by hand keeps the avatar's tap
                  // target and the rest-of-row tap target as independent
                  // siblings instead, so each reliably gets its own taps.
                  return Material(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileDetailScreen(
                                  user: otherUser,
                                  readOnly: true,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: otherUser.photoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        otherUser.photoUrl,
                                      )
                                    : null,
                                child: otherUser.photoUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    matchId: matchId,
                                    otherUser: otherUser,
                                    myProfile: widget.myProfile,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${otherUser.name}, ${otherUser.age}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          hasMessage
                                              ? lastMessage
                                              : "You're matched! Say hi 👋",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: hasMessage
                                                ? Colors.grey[700]
                                                : AppColors.primary,
                                            fontStyle: hasMessage
                                                ? FontStyle.normal
                                                : FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (lastMessageAt != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Text(
                                        _formatTimestamp(
                                          lastMessageAt.toDate(),
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}
