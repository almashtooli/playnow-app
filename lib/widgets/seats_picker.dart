import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet for the user to pick how many seats to book.
/// Returns the chosen seat count (≥ 1) or null if dismissed.
Future<int?> showSeatsPicker(
  BuildContext context, {
  required int remainingSpots,
  required double pricePerPlayer,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SeatsPickerSheet(
      remainingSpots: remainingSpots,
      pricePerPlayer: pricePerPlayer,
    ),
  );
}

class _SeatsPickerSheet extends StatefulWidget {
  final int remainingSpots;
  final double pricePerPlayer;

  const _SeatsPickerSheet({
    required this.remainingSpots,
    required this.pricePerPlayer,
  });

  @override
  State<_SeatsPickerSheet> createState() => _SeatsPickerSheetState();
}

class _SeatsPickerSheetState extends State<_SeatsPickerSheet> {
  int _seats = 1;

  int get _maxSeats => widget.remainingSpots.clamp(1, 10);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = (_seats * widget.pricePerPlayer).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            l.howManySeats,
            style: context.tt.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l.seatsForYouAndFriends,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 28),

          // Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: _seats > 1
                    ? () => setState(() => _seats--)
                    : null,
              ),
              const SizedBox(width: 28),
              Column(
                children: [
                  Text(
                    '$_seats',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: context.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    l.seatsCount(_seats),
                    style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: _seats < _maxSeats
                    ? () => setState(() => _seats++)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Remaining spots info
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.greenTint,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: context.greenBorder, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 16, color: context.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.remainingSpots} ${l.spotsRemaining}',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  l.totalCost(total),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: context.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _seats),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15),
              ),
              child: Text(
                _seats == 1
                    ? l.join
                    : '${l.join} · ${l.seatsCount(_seats)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? context.primary.withOpacity(0.12)
              : context.borderColor.withOpacity(0.3),
          border: Border.all(
            color: enabled ? context.primary : context.borderColor,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? context.primary : context.textHint,
        ),
      ),
    );
  }
}
