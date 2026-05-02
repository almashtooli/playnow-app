import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/rating_service.dart';
import '../theme/app_theme.dart';

/// Shows a bottom-sheet dialog for rating a completed session.
/// Returns true if the user submitted a rating, false/null if skipped.
Future<bool?> showRatingDialog(
  BuildContext context, {
  required int sessionId,
  required String venueName,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RatingSheet(
      sessionId: sessionId,
      venueName: venueName,
    ),
  );
}

class _RatingSheet extends StatefulWidget {
  final int sessionId;
  final String venueName;

  const _RatingSheet({required this.sessionId, required this.venueName});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    try {
      await RatingService().rateSession(
        widget.sessionId,
        _rating,
        comment: _commentController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

          Icon(Icons.star_rounded, size: 36, color: const Color(0xFFF39C12)),
          const SizedBox(height: 8),
          Text(
            l.rateYourSession,
            style: context.tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            widget.venueName,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            l.howWasSession,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.textSecondary),
          ),
          const SizedBox(height: 20),

          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: AnimatedScale(
                  scale: _rating >= star ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    _rating >= star ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 44,
                    color: _rating >= star
                        ? const Color(0xFFF39C12)
                        : context.borderColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Optional comment
          TextField(
            controller: _commentController,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: l.tapStarsToRate,
              counterStyle:
                  TextStyle(fontSize: 11, color: context.textHint),
              filled: true,
              fillColor: context.scaffoldBg,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textSecondary,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.skipRating,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_rating == 0 || _submitting) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l.submitRating,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Star display widget for showing average rating (read-only).
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double starSize;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    required this.totalRatings,
    this.starSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final star = i + 1;
          final filled = rating >= star;
          final half = !filled && rating >= star - 0.5;
          return Icon(
            half
                ? Icons.star_half_rounded
                : filled
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
            size: starSize,
            color: const Color(0xFFF39C12),
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating > 0
              ? '${rating.toStringAsFixed(1)} ${l.ratingsCount(totalRatings)}'
              : l.noRatingsYet,
          style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
