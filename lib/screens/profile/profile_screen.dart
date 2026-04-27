import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();

  bool _saving        = false;
  bool _uploadingAvatar = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        _nameController.text  = user.name;
        _phoneController.text = user.phone ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(
      source:       ImageSource.gallery,
      maxWidth:     1024,
      maxHeight:    1024,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    final error = await context.read<AuthService>().uploadAvatar(file);
    if (mounted) {
      setState(() => _uploadingAvatar = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: context.errorColor),
        );
      }
    }
  }

  void _showAvatarOptions(String avatarUrl) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.fullscreen_rounded, color: context.primary),
              title: const Text('Preview photo'),
              onTap: () {
                Navigator.pop(context);
                _showPreview(avatarUrl);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: context.primary),
              title: const Text('Change photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.white, size: 80),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final l     = AppLocalizations.of(context);
    final name  = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      setState(() { _error = l.nameCannotBeEmpty; _success = null; });
      return;
    }
    setState(() { _saving = true; _error = null; _success = null; });

    final error = await context.read<AuthService>().updateProfile(
      name:  name,
      phone: phone.isEmpty ? null : phone,
    );

    if (mounted) {
      final l2 = AppLocalizations.of(context);
      setState(() {
        _saving  = false;
        _error   = error;
        _success = error == null ? l2.profileUpdated : null;
      });
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  // ---------------------------------------------------------------------------

  Widget _buildAvatar(String name, String? avatarUrl) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: hasAvatar ? () => _showAvatarOptions(avatarUrl) : _pickAndUpload,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  context.greenTint,
              border: Border.all(color: context.greenBorder, width: 1.5),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      width: 88, height: 88,
                      errorBuilder: (_, __, ___) => _avatarLetter(name),
                    )
                  : _avatarLetter(name),
            ),
          ),
          if (_uploadingAvatar)
            Container(
              width: 88, height: 88,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.black45),
              child: const Center(
                child: SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            ),
          if (!_uploadingAvatar)
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color:  context.surface,
                  shape:  BoxShape.circle,
                  border: Border.all(color: context.greenBorder, width: 1),
                ),
                child: Icon(Icons.camera_alt_rounded,
                    color: context.primary, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarLetter(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: context.primary,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor, width: 0.5),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l    = AppLocalizations.of(context);
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Avatar + identity card ───────────────────────────────────────
          _card(
            child: Column(
              children: [
                _buildAvatar(user.name, user.avatarUrl),
                const SizedBox(height: 12),
                Text(
                  user.name.isNotEmpty ? user.name : l.noNameSet,
                  style: context.tt.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(user.email,
                    style: TextStyle(
                        color: context.textSecondary, fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: user.roles.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color:        context.greenTint,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: context.greenBorder, width: 0.5),
                      ),
                      child: Text(r,
                          style: TextStyle(
                            color:      context.primary,
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                          )),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  user.avatarUrl != null
                      ? 'Tap photo to preview or change'
                      : l.tapAvatarToChange,
                  style: TextStyle(color: context.textHint, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Edit fields card ─────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.editInfo,
                    style: TextStyle(
                      color:         context.textSecondary,
                      fontSize:      12,
                      fontWeight:    FontWeight.w600,
                      letterSpacing: 0.4,
                    )),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText:  l.fullName,
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: user.email),
                  readOnly:   true,
                  decoration: InputDecoration(
                    labelText:  l.email,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller:   _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:  l.phoneNumber,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color:        context.errorBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.errorBorder),
                    ),
                    child: Text(_error!,
                        style: TextStyle(
                            color: context.errorColor, fontSize: 13)),
                  ),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color:        context.greenTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: context.greenBorder, width: 0.5),
                    ),
                    child: Text(_success!,
                        style: TextStyle(
                            color: context.primary, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _saveChanges,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(l.saveChanges),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Language card ────────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.language,
                    style: TextStyle(
                      color:         context.textSecondary,
                      fontSize:      12,
                      fontWeight:    FontWeight.w600,
                      letterSpacing: 0.4,
                    )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _langButton(
                      label:    '🇬🇧  ${l.langEnglish}',
                      selected: !l.isAr,
                      onTap: () => context
                          .read<LocaleProvider>()
                          .setLocale(const Locale('en')),
                    ),
                    const SizedBox(width: 10),
                    _langButton(
                      label:    '🇸🇦  ${l.langArabic}',
                      selected: l.isAr,
                      onTap: () => context
                          .read<LocaleProvider>()
                          .setLocale(const Locale('ar')),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Logout ───────────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(l.logout),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.errorColor,
              side:            BorderSide(color: context.errorBorder),
              minimumSize:     const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _langButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.greenTint : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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
