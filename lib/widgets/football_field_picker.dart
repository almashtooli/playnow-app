import 'package:flutter/material.dart';

/// A position on the football field.
class FieldPosition {
  final String label;
  final String fullName;
  /// Normalized x (0 = left/GK goal, 1 = right/ST goal)
  final double x;
  /// Normalized y (0 = top, 1 = bottom)
  final double y;

  const FieldPosition({
    required this.label,
    required this.fullName,
    required this.x,
    required this.y,
  });
}

/// Standard football positions laid out on the field.
const List<FieldPosition> kFieldPositions = [
  FieldPosition(label: 'GK',  fullName: 'Goalkeeper',         x: 0.07, y: 0.50),
  FieldPosition(label: 'LB',  fullName: 'Left Back',           x: 0.23, y: 0.18),
  FieldPosition(label: 'CB',  fullName: 'Center Back',         x: 0.23, y: 0.50),
  FieldPosition(label: 'RB',  fullName: 'Right Back',          x: 0.23, y: 0.82),
  FieldPosition(label: 'LM',  fullName: 'Left Midfielder',     x: 0.43, y: 0.20),
  FieldPosition(label: 'CM',  fullName: 'Central Midfielder',  x: 0.50, y: 0.50),
  FieldPosition(label: 'RM',  fullName: 'Right Midfielder',    x: 0.43, y: 0.80),
  FieldPosition(label: 'LW',  fullName: 'Left Winger',         x: 0.68, y: 0.18),
  FieldPosition(label: 'CF',  fullName: 'Center Forward',      x: 0.68, y: 0.50),
  FieldPosition(label: 'RW',  fullName: 'Right Winger',        x: 0.68, y: 0.82),
  FieldPosition(label: 'ST',  fullName: 'Striker',             x: 0.86, y: 0.35),
  FieldPosition(label: 'ST',  fullName: 'Second Striker',      x: 0.86, y: 0.65),
];

/// Shows a football field where the user taps a position to select it.
/// Returns the selected [FieldPosition] or null if dismissed.
Future<FieldPosition?> showPositionPicker(BuildContext context) {
  return showModalBottomSheet<FieldPosition>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PositionPickerSheet(),
  );
}

class _PositionPickerSheet extends StatefulWidget {
  const _PositionPickerSheet();

  @override
  State<_PositionPickerSheet> createState() => _PositionPickerSheetState();
}

class _PositionPickerSheetState extends State<_PositionPickerSheet> {
  FieldPosition? _selected;

  static const _green = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Select Your Position',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selected == null
                ? 'Tap a position on the field'
                : '${_selected!.label} — ${_selected!.fullName}',
            style: TextStyle(
              color: _selected == null ? Colors.white38 : _green,
              fontSize: 13,
              fontWeight:
                  _selected == null ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Field
          AspectRatio(
            aspectRatio: 1.7,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details.localPosition, w, h),
                  child: CustomPaint(
                    painter: _FieldPainter(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: kFieldPositions.map((pos) {
                        final isSelected = _selected == pos;
                        final left = pos.x * w - 20;
                        final top = pos.y * h - 20;
                        return Positioned(
                          left: left,
                          top: top,
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = pos),
                            child: _PositionDot(
                              label: pos.label,
                              selected: isSelected,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(context, _selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white30,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              child: Text(
                _selected == null
                    ? 'Choose a Position'
                    : 'Confirm — ${_selected!.label}',
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _handleTap(Offset pos, double w, double h) {
    // Find nearest position within 40px tap radius
    FieldPosition? closest;
    double minDist = 40;
    for (final p in kFieldPositions) {
      final dx = p.x * w - pos.dx;
      final dy = p.y * h - pos.dy;
      final dist = (dx * dx + dy * dy);
      if (dist < minDist * minDist && dist < minDist) {
        minDist = dist.toDouble();
        closest = p;
      }
    }
    if (closest != null) setState(() => _selected = closest);
  }
}

/// A single position marker dot.
class _PositionDot extends StatelessWidget {
  final String label;
  final bool selected;

  const _PositionDot({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? const Color(0xFF1DB954) : const Color(0xFFCC1F3A),
        border: Border.all(
          color: Colors.white,
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (selected ? const Color(0xFF1DB954) : const Color(0xFFCC1F3A))
                .withOpacity(0.5),
            blurRadius: selected ? 10 : 4,
            spreadRadius: selected ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

/// Draws a realistic green football field with white markings.
class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fieldPaint = Paint()..color = const Color(0xFF2D8A4E);
    final stripePaint = Paint()..color = const Color(0xFF2A8049);
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // ── Background ──
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(8),
    );
    canvas.drawRRect(fieldRect, fieldPaint);

    // ── Alternating grass stripes ──
    final stripeCount = 8;
    final stripeWidth = w / stripeCount;
    for (var i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, h),
        stripePaint,
      );
    }

    // Clip to field bounds
    canvas.clipRRect(fieldRect);

    // ── Outer boundary ──
    canvas.drawRect(
      Rect.fromLTWH(4, 4, w - 8, h - 8),
      linePaint,
    );

    // ── Halfway line ──
    canvas.drawLine(Offset(w / 2, 4), Offset(w / 2, h - 4), linePaint);

    // ── Center circle ──
    final centerCircleRadius = h * 0.18;
    canvas.drawCircle(Offset(w / 2, h / 2), centerCircleRadius, linePaint);

    // ── Center spot ──
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      3,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    // ── Left penalty area ──
    final penaltyW = w * 0.14;
    final penaltyH = h * 0.50;
    final penaltyTop = (h - penaltyH) / 2;
    canvas.drawRect(
      Rect.fromLTWH(4, penaltyTop, penaltyW, penaltyH),
      linePaint,
    );

    // ── Left goal area ──
    final goalAreaW = w * 0.065;
    final goalAreaH = h * 0.26;
    final goalAreaTop = (h - goalAreaH) / 2;
    canvas.drawRect(
      Rect.fromLTWH(4, goalAreaTop, goalAreaW, goalAreaH),
      linePaint,
    );

    // ── Left penalty spot ──
    canvas.drawCircle(
      Offset(w * 0.115, h / 2),
      3,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    // ── Left penalty arc ──
    final arcRect = Rect.fromCenter(
      center: Offset(w * 0.115, h / 2),
      width: penaltyH * 0.65,
      height: penaltyH * 0.65,
    );
    canvas.drawArc(arcRect, -1.1, 2.2, false, linePaint);

    // ── Right penalty area ──
    canvas.drawRect(
      Rect.fromLTWH(w - 4 - penaltyW, penaltyTop, penaltyW, penaltyH),
      linePaint,
    );

    // ── Right goal area ──
    canvas.drawRect(
      Rect.fromLTWH(w - 4 - goalAreaW, goalAreaTop, goalAreaW, goalAreaH),
      linePaint,
    );

    // ── Right penalty spot ──
    canvas.drawCircle(
      Offset(w * 0.885, h / 2),
      3,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    // ── Right penalty arc ──
    final arcRectR = Rect.fromCenter(
      center: Offset(w * 0.885, h / 2),
      width: penaltyH * 0.65,
      height: penaltyH * 0.65,
    );
    canvas.drawArc(arcRectR, 2.0, 2.2, false, linePaint);

    // ── Left goal ──
    final goalH = h * 0.16;
    final goalW = w * 0.025;
    final goalTop = (h - goalH) / 2;
    final goalPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(0, goalTop, goalW, goalH),
      goalPaint,
    );

    // ── Right goal ──
    canvas.drawRect(
      Rect.fromLTWH(w - goalW, goalTop, goalW, goalH),
      goalPaint,
    );

    // ── Corner arcs ──
    final cornerRadius = w * 0.025;
    final corners = [
      Offset(4, 4),
      Offset(w - 4, 4),
      Offset(4, h - 4),
      Offset(w - 4, h - 4),
    ];
    final cornerAngles = [0.0, 1.57, -1.57, 3.14];
    for (var i = 0; i < 4; i++) {
      final r = Rect.fromCenter(
        center: corners[i],
        width: cornerRadius * 2,
        height: cornerRadius * 2,
      );
      canvas.drawArc(r, cornerAngles[i], 1.57, false, linePaint);
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => false;
}
