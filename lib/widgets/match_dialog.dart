import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme.dart';

Future<void> showMatchDialog({
  required BuildContext context,
  required AppUser me,
  required AppUser them,
  required VoidCallback onSendMessage,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => Material(
        child: _MatchContent(me: me, them: them, onSendMessage: onSendMessage),
      ),
      transitionsBuilder: (context, anim, secondaryAnim, child) {
        return Transform.scale(
          scale: 0.7 + Curves.easeOutBack.transform(anim.value) * 0.3,
          child: Opacity(
            opacity: anim.value.clamp(0, 1),
            child: child,
          ),
        );
      },
    ),
  );
}

class _MatchContent extends StatelessWidget {
  final AppUser me;
  final AppUser them;
  final VoidCallback onSendMessage;

  const _MatchContent({
    required this.me,
    required this.them,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "It's a Match!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${them.name} liked each other',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _avatar(me.photoUrl),
                  Transform.translate(
                    offset: const Offset(-16, 0),
                    child: _avatar(them.photoUrl),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSendMessage();
                  },
                  child: const Text('Send a Message'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Keep Swiping',
                  style: TextStyle(
                    color: Colors.white70,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String url) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
            : Container(
                color: Colors.white24,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
      ),
    );
  }
}
