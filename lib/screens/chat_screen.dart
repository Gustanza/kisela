import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'profile_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final AppUser otherUser;
  final AppUser myProfile;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUser,
    required this.myProfile,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  DateTime? _matchedAt;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _firestoreService.getMatchCreatedAt(widget.matchId).then((value) {
      if (mounted) setState(() => _matchedAt = value);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final myUid = _authService.currentUser!.uid;
    _messageController.clear();
    await _firestoreService.sendMessage(
      matchId: widget.matchId,
      senderId: myUid,
      text: text,
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileDetailScreen(user: widget.otherUser, readOnly: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openProfile,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(widget.otherUser.photoUrl)
                    : null,
                child: widget.otherUser.photoUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.otherUser.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreService.messagesStream(widget.matchId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: docs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildMatchHeader(context);
                    }
                    final i = index - 1;
                    final data = docs[i].data();
                    final isMe = data['senderId'] == myUid;
                    final createdAt = (data['createdAt'] as Timestamp?)
                        ?.toDate();

                    final prev = i > 0 ? docs[i - 1].data() : null;
                    final prevCreatedAt = (prev?['createdAt'] as Timestamp?)
                        ?.toDate();
                    final sameSenderAsPrev =
                        prev != null &&
                        prev['senderId'] == data['senderId'] &&
                        createdAt != null &&
                        prevCreatedAt != null &&
                        _isSameDay(createdAt, prevCreatedAt);

                    final next = i < docs.length - 1
                        ? docs[i + 1].data()
                        : null;
                    final nextCreatedAt = (next?['createdAt'] as Timestamp?)
                        ?.toDate();
                    final isLastInRun =
                        !(next != null &&
                            next['senderId'] == data['senderId'] &&
                            createdAt != null &&
                            nextCreatedAt != null &&
                            _isSameDay(createdAt, nextCreatedAt));

                    final showDateDivider =
                        createdAt != null &&
                        (prevCreatedAt == null ||
                            !_isSameDay(createdAt, prevCreatedAt));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateDivider) _buildDateDivider(createdAt),
                        _buildBubble(
                          text: data['text'] ?? '',
                          isMe: isMe,
                          topMargin: sameSenderAsPrev ? 3 : 12,
                          showTime: isLastInRun && createdAt != null,
                          time: createdAt,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          SizedBox(
            height: 84,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: _headerAvatar(widget.myProfile.photoUrl),
                ),
                Positioned(
                  right: 0,
                  child: _headerAvatar(widget.otherUser.photoUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'You matched with ${widget.otherUser.name}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (_matchedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatMatchDate(_matchedAt!),
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerAvatar(String photoUrl) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6),
        ],
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateDivider(date),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isMe,
    required double topMargin,
    required bool showTime,
    DateTime? time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: topMargin),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : AppColors.textDark),
            ),
          ),
          if (showTime && time != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatMessageTime(time),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 23,
              backgroundColor: _hasText
                  ? AppColors.primary
                  : Colors.grey.shade300,
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: _hasText ? Colors.white : Colors.grey[500],
                  size: 20,
                ),
                onPressed: _hasText ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatMessageTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDateDivider(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final year = dt.year != now.year ? ', ${dt.year}' : '';
    return '${_months[dt.month - 1]} ${dt.day}$year';
  }

  String _formatMatchDate(DateTime dt) {
    final now = DateTime.now();
    final year = dt.year != now.year ? ', ${dt.year}' : '';
    return '${_months[dt.month - 1]} ${dt.day}$year';
  }
}
