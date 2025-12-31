import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedTopButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isBlue;
  final bool isCircle;
  final ThemeData theme;

  const AnimatedTopButton({
    super.key,
    required this.icon,
    this.onTap,
    required this.isBlue,
    this.isCircle = false,
    required this.theme,
  });

  @override
  State<AnimatedTopButton> createState() => _AnimatedTopButtonState();
}

class _AnimatedTopButtonState extends State<AnimatedTopButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isBlue ? Colors.blue.withOpacity(0.5) : (isDark ? Colors.white24 : Colors.black12),
            ),
            borderRadius: widget.isCircle ? null : BorderRadius.circular(12.r),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            color: isDark ? Colors.black54 : Colors.grey[200],
            boxShadow: [
              if (widget.isBlue)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.isBlue ? Colors.blue : (isDark ? Colors.white : Colors.black87),
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}
