import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController          = TextEditingController();
  final _emailController         = TextEditingController();
  final _phoneController         = TextEditingController();
  final _passwordController      = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  bool _loading               = false;
  bool _obscurePassword       = true;
  bool _obscureConfirm        = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5, now.month, now.day),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _register() async {
    final l = AppLocalizations.of(context);

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = l.passwordsDoNotMatch);
      return;
    }

    setState(() { _loading = true; _error = null; });

    final error = await context.read<AuthService>().register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      phone: _phoneController.text.trim(),
      birthDate: _birthDate != null ? _formatDate(_birthDate!) : null,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() { _loading = false; _error = error; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.accountCreated)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(l.createAccount),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding block
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color:        context.greenTint,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: context.greenBorder, width: 0.5),
                    ),
                    child: Icon(Icons.sports_soccer,
                        color: context.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.createAccount,
                  textAlign: TextAlign.center,
                  style: context.tt.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  l.joinAndPlay,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: context.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:        context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: context.borderColor, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full name
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText:  l.fullName,
                          prefixIcon: const Icon(
                              Icons.person_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextField(
                        controller:   _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText:  l.email,
                          prefixIcon: const Icon(
                              Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mobile number
                      TextField(
                        controller:   _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText:  l.phoneNumber,
                          prefixIcon: const Icon(
                              Icons.phone_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Birth date
                      GestureDetector(
                        onTap: _pickBirthDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: context.borderColor, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake_outlined,
                                  size: 20,
                                  color: context.textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                _birthDate != null
                                    ? _formatDate(_birthDate!)
                                    : l.selectBirthDate,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _birthDate != null
                                      ? null
                                      : context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextField(
                        controller:  _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText:  l.password,
                          prefixIcon: const Icon(
                              Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Confirm password
                      TextField(
                        controller:  _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText:  l.confirmPassword,
                          prefixIcon: const Icon(
                              Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
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
                          child: Text(
                            _error!,
                            style: TextStyle(
                                color: context.errorColor, fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(l.createAccount),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
