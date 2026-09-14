import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme.dart';

enum SwipeDirection { like, nope }

class SwipeCard extends StatefulWidget {
  final AppUser user;
  final void Function(SwipeDirection direction) onSwiped;
  final bool isFront;

  const SwipeCard({
    super.key,
    required this.user,
    required this.onSwiped,
    required this.isFront,
  });

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  late AnimationController _controller;
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_animation != null) {
          setState(() => _dragOffset = _animation!.value);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.28;

    if (_dragOffset.dx.abs() > threshold) {
      final direction =
          _dragOffset.dx > 0 ? SwipeDirection.like : SwipeDirection.nope;
      final endX = direction == SwipeDirection.like
          ? screenWidth * 1.5
          : -screenWidth * 1.5;
      _animateTo(Offset(endX, _dragOffset.dy), then: () {
        widget.onSwiped(direction);
      });
    } else {
      _animateTo(Offset.zero);
    }
  }

  void _animateTo(Offset target, {VoidCallback? then}) {
    _animation = Tween<Offset>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0).then((_) {
      if (then != null) then();
    });
  }

  void swipeProgrammatically(SwipeDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final endX =
        direction == SwipeDirection.like ? screenWidth * 1.5 : -screenWidth * 1.5;
    _animateTo(Offset(endX, 0), then: () => widget.onSwiped(direction));
  }

  @override
  Widget build(BuildContext context) {
    final angle = _dragOffset.dx / 300 * 0.4;
    final likeOpacity = (_dragOffset.dx / 100).clamp(0.0, 1.0);
    final nopeOpacity = (-_dragOffset.dx / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: widget.isFront ? _onPanUpdate : null,
      onPanEnd: widget.isFront ? _onPanEnd : null,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              _buildCard(),
              if (likeOpacity > 0)
                Positioned(
                  top: 40,
                  left: 24,
                  child: _stamp('LIKE', AppColors.like, likeOpacity),
                ),
              if (nopeOpacity > 0)
                Positioned(
                  top: 40,
                  right: 24,
                  child: _stamp('NOPE', AppColors.nope, nopeOpacity),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stamp(String text, Color color, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: text == 'LIKE' ? -0.3 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.user.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.user.photoUrl,
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
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.user.name}, ${widget.user.age}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.user.bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.user.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
}
