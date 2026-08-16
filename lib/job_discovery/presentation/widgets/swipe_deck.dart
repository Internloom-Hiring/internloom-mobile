import 'package:flutter/material.dart';

import '../../data/models/placement_drive.dart';
import '../../data/models/swipe_action.dart';
import 'job_discovery_card.dart';

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.cards,
    required this.onSwipe,
    required this.onOpenDetails,
  });

  final List<PlacementDrive> cards;
  final ValueChanged<SwipeDirection> onSwipe;
  final ValueChanged<PlacementDrive> onOpenDetails;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck>
    with SingleTickerProviderStateMixin {
  static const _threshold = 100.0;

  late final AnimationController _controller;

  Offset _dragOffset = Offset.zero;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(covariant SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldTop = oldWidget.cards.isEmpty ? null : oldWidget.cards.first.id;
    final newTop = widget.cards.isEmpty ? null : widget.cards.first.id;

    if (oldTop != newTop && !_isAnimating) {
      _dragOffset = Offset.zero;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    final visible = widget.cards.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = visible.length - 1; index > 0; index--)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, (index - 1) * 10),
                    child: Transform.scale(
                      scale: 1 - ((index - 1) * 0.035),
                      child: JobDiscoveryCard(drive: visible[index]),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: GestureDetector(
                onTap: () => widget.onOpenDetails(visible.first),
                onPanUpdate: _isAnimating
                    ? null
                    : (details) {
                        setState(() {
                          _dragOffset += details.delta;
                        });
                      },
                onPanEnd: _isAnimating ? null : (_) => _finishDrag(width, height),
                child: Transform.translate(
                  offset: _dragOffset,
                  child: Transform.rotate(
                    angle: _dragOffset.dx / 900,
                    child: JobDiscoveryCard(
                      drive: visible.first,
                      onTap: () => widget.onOpenDetails(visible.first),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _finishDrag(double width, double height) {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    SwipeDirection? direction;

    if (dx.abs() >= _threshold && dx.abs() >= dy.abs()) {
      direction = dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else if (dy <= -_threshold && dy.abs() > dx.abs()) {
      direction = SwipeDirection.up;
    }

    if (direction == null) {
      _animateTo(Offset.zero);
      return;
    }

    final target = switch (direction) {
      SwipeDirection.left => Offset(-width * 1.5, _dragOffset.dy),
      SwipeDirection.right => Offset(width * 1.5, _dragOffset.dy),
      SwipeDirection.up => Offset(_dragOffset.dx, -height * 1.5),
    };

    _animateTo(target, onComplete: () {
      widget.onSwipe(direction!);
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
        });
      }
    });
  }

  void _animateTo(
    Offset target, {
    VoidCallback? onComplete,
  }) {
    if (_isAnimating) return;

    _isAnimating = true;
    final begin = _dragOffset;

    _controller
      ..stop()
      ..reset();

    final animation = Tween<Offset>(
      begin: begin,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _dragOffset = animation.value;
      });
    }

    void statusListener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;

      _controller.removeListener(listener);
      _controller.removeStatusListener(statusListener);
      _isAnimating = false;
      onComplete?.call();

      if (onComplete == null && mounted) {
        setState(() {
          _dragOffset = target;
        });
      }
    }

    _controller.addListener(listener);
    _controller.addStatusListener(statusListener);
    _controller.forward();
  }
}
