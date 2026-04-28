import 'package:flutter/material.dart';

class CustomLoadingWidget extends StatefulWidget {
  double? itemSize;
  double? itemDistance;
  CustomLoadingWidget({this.itemSize, this.itemDistance, super.key});

  @override
  State<CustomLoadingWidget> createState() => _CustomLoadingWidgetState();
}

class _CustomLoadingWidgetState extends State<CustomLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Color> _colors = [
    const Color(0xFFE040FB),
    const Color(0xFFFF4081),
    const Color(0xFFFF6D00),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _buildAnimation(double start, double end) {
    return TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Interval(start, end)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animations = [
      _buildAnimation(0.0, 0.5),
      _buildAnimation(0.2, 0.7),
      _buildAnimation(0.4, 0.9),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: animations[i],
          builder: (_, __) {
            final t = animations[i].value;

            // 👇 Reduced bounce height (was -8)
            final dy = -4.0 * t;

            final opacity = 0.5 + (0.5 * t);

            return Transform.translate(
              offset: Offset(0, dy),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  // 👇 Reduced spacing (was 3)
                  margin:  EdgeInsets.symmetric(
                    horizontal: widget.itemDistance ?? 1.5,
                  ),
                  width: widget.itemSize ?? 6.5,
                  height: widget.itemSize ?? 6.5,
                  decoration: BoxDecoration(
                    color: _colors[i],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
