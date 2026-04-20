import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ── Empty State ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.greenTint,
                shape: BoxShape.circle,
                border: Border.all(color: context.greenBorder, width: 0.5),
              ),
              child: Icon(icon, size: 48, color: context.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Preset empty states ──────────────────────────────────────────────────────────

class EmptyVenuesState extends StatelessWidget {
  final VoidCallback? onRetry;
  const EmptyVenuesState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.stadium_rounded,
    title: 'No venues found',
    subtitle: 'Try adjusting your search or check back later.',
    actionLabel: onRetry != null ? 'Refresh' : null,
    onAction: onRetry,
  );
}

class EmptySessionsState extends StatelessWidget {
  final VoidCallback? onRetry;
  const EmptySessionsState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.sports_soccer_rounded,
    title: 'No sessions available',
    subtitle: 'There are no open sessions right now.\nCheck back soon!',
    actionLabel: onRetry != null ? 'Refresh' : null,
    onAction: onRetry,
  );
}

class EmptyBookingsState extends StatelessWidget {
  const EmptyBookingsState({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.calendar_today_rounded,
    title: 'No bookings yet',
    subtitle: 'Browse sessions and reserve your spot\nfor the next match!',
  );
}

// ── Error State ───────────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.errorBg,
                shape: BoxShape.circle,
                border: Border.all(color: context.errorBorder, width: 0.5),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: context.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.errorColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Network Error Banner ──────────────────────────────────────────────────────

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.errorColor,
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'No internet connection',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
