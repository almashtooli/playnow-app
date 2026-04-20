import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _SectionHeader(label: l.appearance),
          _ThemeTile(),
          const SizedBox(height: 16),

          _SectionHeader(label: l.preferencesSection),
          _LanguageTile(),
          const SizedBox(height: 16),

          _SectionHeader(label: l.notificationsSection),
          _NotificationsTile(),
          const SizedBox(height: 16),

          _SectionHeader(label: l.accountSection),
          _AccountTile(),
          const SizedBox(height: 16),

          _SectionHeader(label: l.aboutSection),
          _AboutTile(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color:         context.textSecondary,
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        context.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: context.borderColor, width: 0.5),
      ),
      child: child,
    );
  }
}

// ── Theme tile ────────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final service  = context.watch<ThemeService>();
    final current  = service.mode;

    final options = [
      (ThemeMode.system, l.themeSystem, Icons.brightness_auto_rounded),
      (ThemeMode.light,  l.themeLight,  Icons.light_mode_rounded),
      (ThemeMode.dark,   l.themeDark,   Icons.dark_mode_rounded),
    ];

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, size: 18, color: context.primary),
                const SizedBox(width: 10),
                Text(l.themeMode, style: context.tt.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: options.map((opt) {
                final (mode, label, icon) = opt;
                final selected = current == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.read<ThemeService>().setMode(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:        selected ? context.greenTint : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? context.greenBorder : context.borderColor,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(icon,
                            size:  18,
                            color: selected ? context.primary : context.textSecondary),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize:   11,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color:      selected ? context.primary : context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final provider = context.watch<LocaleProvider>();

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language_rounded, size: 18, color: context.primary),
                const SizedBox(width: 10),
                Text(l.language, style: context.tt.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _LangOption(
                  label:    '🇬🇧  ${l.langEnglish}',
                  selected: !provider.isAr,
                  onTap:    () => context.read<LocaleProvider>().setLocale(const Locale('en')),
                ),
                const SizedBox(width: 10),
                _LangOption(
                  label:    '🇸🇦  ${l.langArabic}',
                  selected: provider.isAr,
                  onTap:    () => context.read<LocaleProvider>().setLocale(const Locale('ar')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:        selected ? context.greenTint : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.greenBorder : context.borderColor,
              width: 0.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color:      selected ? context.primary : context.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize:   13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notifications tile ────────────────────────────────────────────────────────

class _NotificationsTile extends StatefulWidget {
  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Card(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(Icons.notifications_outlined,
            size: 20, color: context.primary),
        title: Text(l.enableNotifications, style: context.tt.bodyLarge),
        value: _enabled,
        onChanged: (v) => setState(() => _enabled = v),
      ),
    );
  }
}

// ── Account tile ──────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l    = AppLocalizations.of(context);
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon:  Icons.person_outline_rounded,
              label: user.name.isNotEmpty ? user.name : l.noNameSet,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon:  Icons.email_outlined,
              label: user.email,
            ),
            if (user.roles.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon:  Icons.badge_outlined,
                label: user.roles.join(', '),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(color: context.textPrimary, fontSize: 14)),
        ),
      ],
    );
  }
}

// ── About tile ────────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _Card(
      child: Column(
        children: [
          _AboutRow(
            icon:  Icons.info_outline_rounded,
            label: l.appVersion,
            value: '1.0.0',
          ),
          Divider(height: 1, color: context.borderColor),
          _AboutRow(
            icon:  Icons.privacy_tip_outlined,
            label: l.privacyPolicy,
          ),
          Divider(height: 1, color: context.borderColor),
          _AboutRow(
            icon:  Icons.article_outlined,
            label: l.termsOfService,
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _AboutRow({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(color: context.textPrimary, fontSize: 14)),
          ),
          if (value != null)
            Text(value!,
                style: TextStyle(color: context.textSecondary, fontSize: 13))
          else
            Icon(Icons.chevron_right_rounded,
                size: 18, color: context.textHint),
        ],
      ),
    );
  }
}
