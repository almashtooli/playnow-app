import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A shimmer loading effect used while data is being fetched.
class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const ShimmerWidget.rounded({
    super.key,
    required this.width,
    required this.height,
    double radius = 8,
  }) : borderRadius = const BorderRadius.all(Radius.circular(8));

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    final highlight = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 0.5, 0),
              end: Alignment(_animation.value + 0.5, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

// ── Venue Card Shimmer ────────────────────────────────────────────────────────

class VenueCardShimmer extends StatelessWidget {
  const VenueCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: double.infinity,
            height: 160,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget.rounded(width: 180, height: 16),
                const SizedBox(height: 8),
                ShimmerWidget.rounded(width: 120, height: 12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ShimmerWidget.rounded(width: 60, height: 24),
                    const SizedBox(width: 8),
                    ShimmerWidget.rounded(width: 60, height: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session Card Shimmer ──────────────────────────────────────────────────────

class SessionCardShimmer extends StatelessWidget {
  const SessionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          ShimmerWidget(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget.rounded(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                ShimmerWidget.rounded(width: 140, height: 12),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerWidget.rounded(width: 70, height: 20),
                    const SizedBox(width: 8),
                    ShimmerWidget.rounded(width: 70, height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer List Builder ──────────────────────────────────────────────────────

class ShimmerList extends StatelessWidget {
  final int count;
  final Widget Function() itemBuilder;

  const ShimmerList({super.key, this.count = 4, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(count, (_) => itemBuilder()));
  }
}
