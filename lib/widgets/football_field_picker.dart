import 'package:flutter/material.dart';

class FieldPosition {
  final String label;
  final String fullName;
  /// 'A' = left half (blue), 'B' = right half (red)
  final String team;
  /// Normalised x (0 = left goal, 1 = right goal)
  final double x;
  /// Normalised y (0 = top touchline, 1 = bottom touchline)
  final double y;

  const FieldPosition({
    required this.label,
    required this.fullName,
    required this.team,
    required this.x,
    required this.y,
  });
}

// 6-a-side: 1-2-2-1 formation per team
const List<FieldPosition> kFieldPositions = [
  // ── Team A (left half, attacks →) ──────────────────────────
  FieldPosition(label: 'GK', fullName: 'Goalkeeper',      team: 'A', x: 0.06, y: 0.50),
  FieldPosition(label: 'LB', fullName: 'Left Back',        team: 'A', x: 0.21, y: 0.25),
  FieldPosition(label: 'RB', fullName: 'Right Back',       team: 'A', x: 0.21, y: 0.75),
  FieldPosition(label: 'LM', fullName: 'Left Midfielder',  team: 'A', x: 0.36, y: 0.28),
  FieldPosition(label: 'RM', fullName: 'Right Midfielder', team: 'A', x: 0.36, y: 0.72),
  FieldPosition(label: 'ST', fullName: 'Striker',          team: 'A', x: 0.44, y: 0.50),

  // ── Team B (right half, attacks ←) ─────────────────────────
  FieldPosition(label: 'GK', fullName: 'Goalkeeper',      team: 'B', x: 0.94, y: 0.50),
  FieldPosition(label: 'RB', fullName: 'Right Back',       team: 'B', x: 0.79, y: 0.25),
  FieldPosition(label: 'LB', fullName: 'Left Back',        team: 'B', x: 0.79, y: 0.75),
  FieldPosition(label: 'RM', fullName: 'Right Midfielder', team: 'B', x: 0.64, y: 0.28),
  FieldPosition(label: 'LM', fullName: 'Left Midfielder',  team: 'B', x: 0.64, y: 0.72),
  FieldPosition(label: 'ST', fullName: 'Striker',          team: 'B', x: 0.56, y: 0.50),
];

const _kTeamA = Color(0xFF1565C0); // blue
const _kTeamB = Color(0xFFC62828); // red
const _kSelected = Color(0xFF1DB954); // green

/// Shows a football field with two teams (6 vs 6). Returns the selected
/// [FieldPosition] or null if dismissed.
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

  @override
  Widget build(BuildContext context) {
    final selColor = _selected == null
        ? Colors.white38
        : (_selected!.team == 'A' ? _kTeamA : _kTeamB);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Select Your Position',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          // Team legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TeamBadge(color: _kTeamA, label: 'Team A'),
              const SizedBox(width: 24),
              _TeamBadge(color: _kTeamB, label: 'Team B'),
            ],
          ),
          const SizedBox(height: 8),

          // Selection hint / result
          Text(
            _selected == null
                ? 'Tap a player to pick your position'
                : 'Team ${_selected!.team}  ·  ${_selected!.label} — ${_selected!.fullName}',
            style: TextStyle(
              color: selColor,
              fontSize: 13,
              fontWeight: _selected == null ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // Field
          AspectRatio(
            aspectRatio: 1.7,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return GestureDetector(
                  onTapUp: (d) => _handleTap(d.localPosition, w, h),
                  child: CustomPaint(
                    painter: _FieldPainter(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Team labels on the field
                        Positioned(
                          left: w * 0.1,
                          top: 8,
                          child: _FieldLabel('TEAM A →', _kTeamA),
                        ),
                        Positioned(
                          right: w * 0.1,
                          top: 8,
                          child: _FieldLabel('← TEAM B', _kTeamB),
                        ),
                        // Position dots
                        ...kFieldPositions.map((pos) {
                          final isSelected = _selected == pos;
                          return Positioned(
                            left: pos.x * w - 20,
                            top: pos.y * h - 20,
                            child: GestureDetector(
                              onTap: () => setState(() => _selected = pos),
                              child: _PositionDot(
                                label: pos.label,
                                team: pos.team,
                                selected: isSelected,
                              ),
                            ),
                          );
                        }),
                      ],
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
                backgroundColor: _kSelected,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white30,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
              ),
              child: Text(
                _selected == null
                    ? 'Choose a Position'
                    : 'Confirm — Team ${_selected!.team}  ·  ${_selected!.label}',
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _handleTap(Offset pos, double w, double h) {
    FieldPosition? closest;
    double minDist = 40 * 40;
    for (final p in kFieldPositions) {
      final dx = p.x * w - pos.dx;
      final dy = p.y * h - pos.dy;
      final dist = dx * dx + dy * dy;
      if (dist < minDist) {
        minDist = dist;
        closest = p;
      }
    }
    if (closest != null) setState(() => _selected = closest);
  }
}

class _TeamBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _TeamBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white54, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _FieldLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color.withOpacity(0.85),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
    );
  }
}

class _PositionDot extends StatelessWidget {
  final String label;
  final String team;
  final bool selected;
  const _PositionDot({required this.label, required this.team, required this.selected});

  @override
  Widget build(BuildContext context) {
    final baseColor = selected ? _kSelected : (team == 'A' ? _kTeamA : _kTeamB);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: baseColor,
        border: Border.all(
          color: Colors.white,
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.55),
            blurRadius: selected ? 12 : 4,
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

    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(8),
    );
    canvas.drawRRect(fieldRect, fieldPaint);

    // Alternating stripes
    const stripeCount = 8;
    final stripeWidth = w / stripeCount;
    for (var i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, h),
        stripePaint,
      );
    }
    canvas.clipRRect(fieldRect);

    // Boundary
    canvas.drawRect(Rect.fromLTWH(4, 4, w - 8, h - 8), linePaint);

    // Halfway line
    canvas.drawLine(Offset(w / 2, 4), Offset(w / 2, h - 4), linePaint);

    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.18, linePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 3,
        Paint()..color = Colors.white.withOpacity(0.85));

    // Left penalty area
    final penaltyW = w * 0.14;
    final penaltyH = h * 0.50;
    final penaltyTop = (h - penaltyH) / 2;
    canvas.drawRect(
        Rect.fromLTWH(4, penaltyTop, penaltyW, penaltyH), linePaint);

    // Left goal area
    final goalAreaW = w * 0.065;
    final goalAreaH = h * 0.26;
    final goalAreaTop = (h - goalAreaH) / 2;
    canvas.drawRect(
        Rect.fromLTWH(4, goalAreaTop, goalAreaW, goalAreaH), linePaint);

    // Left penalty spot + arc
    canvas.drawCircle(Offset(w * 0.115, h / 2), 3,
        Paint()..color = Colors.white.withOpacity(0.85));
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.115, h / 2),
          width: penaltyH * 0.65,
          height: penaltyH * 0.65),
      -1.1, 2.2, false, linePaint,
    );

    // Right penalty area
    canvas.drawRect(
        Rect.fromLTWH(w - 4 - penaltyW, penaltyTop, penaltyW, penaltyH),
        linePaint);

    // Right goal area
    canvas.drawRect(
        Rect.fromLTWH(w - 4 - goalAreaW, goalAreaTop, goalAreaW, goalAreaH),
        linePaint);

    // Right penalty spot + arc
    canvas.drawCircle(Offset(w * 0.885, h / 2), 3,
        Paint()..color = Colors.white.withOpacity(0.85));
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(w * 0.885, h / 2),
          width: penaltyH * 0.65,
          height: penaltyH * 0.65),
      2.0, 2.2, false, linePaint,
    );

    // Goals
    final goalH = h * 0.16;
    final goalW = w * 0.025;
    final goalTop = (h - goalH) / 2;
    final goalPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, goalTop, goalW, goalH), goalPaint);
    canvas.drawRect(
        Rect.fromLTWH(w - goalW, goalTop, goalW, goalH), goalPaint);

    // Corner arcs
    final cr = w * 0.025;
    final corners = [
      Offset(4, 4), Offset(w - 4, 4),
      Offset(4, h - 4), Offset(w - 4, h - 4),
    ];
    final angles = [0.0, 1.57, -1.57, 3.14];
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCenter(center: corners[i], width: cr * 2, height: cr * 2),
        angles[i], 1.57, false, linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_FieldPainter old) => false;
}
