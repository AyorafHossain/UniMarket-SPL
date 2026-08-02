import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const Shimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE2E8F0), // gray200
                Color(0xFFF8FAFC), // background
                Color(0xFFE2E8F0), // gray200
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Translate the gradient horizontally from left to right
    return Matrix4.translationValues(
      bounds.width * (slidePercent - 0.5) * 2.5,
      0.0,
      0.0,
    );
  }
}

/// A simple helper widget that represents a skeleton card or box to apply the Shimmer to.
class ShimmerLoadingPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;

  const ShimmerLoadingPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.margin,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    if (shape != null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: shape!,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
