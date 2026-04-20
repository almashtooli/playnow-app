import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../screens/landing_screen.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';

// ---------------------------------------------------------------------------
// Country code data
// ---------------------------------------------------------------------------

class _Country {
  final String name;
  final String flag;
  final String dialCode;

  const _Country(this.name, this.flag, this.dialCode);
}

const _kCountries = [
  _Country('Jordan',               '🇯🇴', '+962'),
  _Country('Saudi Arabia',         '🇸🇦', '+966'),
  _Country('United Arab Emirates', '🇦🇪', '+971'),
  _Country('Egypt',                '🇪🇬', '+20'),
  _Country('Kuwait',               '🇰🇼', '+965'),
  _Country('Qatar',                '🇶🇦', '+974'),
  _Country('Bahrain',              '🇧🇭', '+973'),
  _Country('Oman',                 '🇴🇲', '+968'),
  _Country('Lebanon',              '🇱🇧', '+961'),
  _Country('Iraq',                 '🇮🇶', '+964'),
  _Country('Palestine',            '🇵🇸', '+970'),
  _Country('Syria',                '🇸🇾', '+963'),
  _Country('Yemen',                '🇾🇪', '+967'),
  _Country('Libya',                '🇱🇾', '+218'),
  _Country('Tunisia',              '🇹🇳', '+216'),
  _Country('Algeria',              '🇩🇿', '+213'),
  _Country('Morocco',              '🇲🇦', '+212'),
  _Country('Sudan',                '🇸🇩', '+249'),
  _Country('United States',        '🇺🇸', '+1'),
  _Country('United Kingdom',       '🇬🇧', '+44'),
  _Country('Germany',              '🇩🇪', '+49'),
  _Country('France',               '🇫🇷', '+33'),
  _Country('Turkey',               '🇹🇷', '+90'),
  _Country('India',                '🇮🇳', '+91'),
  _Country('Pakistan',             '🇵🇰', '+92'),
  _Country('Canada',               '🇨🇦', '+1'),
  _Country('Australia',            '🇦🇺', '+61'),
  _Country('Netherlands',          '🇳🇱', '+31'),
  _Country('Spain',                '🇪🇸', '+34'),
  _Country('Italy',                '🇮🇹', '+39'),
];

// ---------------------------------------------------------------------------
// Login screen
// ---------------------------------------------------------------------------

enum _PhonePhase { input, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Email login state ---
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // --- Phone login state ---
  final _phoneController = TextEditingController();
  final _otpController   = TextEditingController();
  _PhonePhase _phonePhase = _PhonePhase.input;
  String? _verificationId;
  int? _resendToken;
  _Country _selectedCountry = _kCountries.first;

  // --- Shared ---
  bool _isPhoneMode = false;
  bool _loading     = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- Email login ---
  Future<void> _loginWithEmail() async {
    setState(() { _loading = true; _error = null; });
    final error = await context.read<AuthService>().login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted) {
      setState(() { _loading = false; _error = error; });
      if (error == null) _navigateHome();
    }
  }

  // --- Phone: send OTP ---
  Future<void> _sendOtp() async {
    final l = AppLocalizations.of(context);
    final local = _phoneController.text.trim();
    if (local.isEmpty) {
      setState(() => _error = l.enterPhoneNumber);
      return;
    }
    final localStripped = local.startsWith('0') ? local.substring(1) : local;
    final phone = '${_selectedCountry.dialCode}$localStripped';
    setState(() { _loading = true; _error = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _verifyCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.message ?? AppLocalizations.of(context).verificationFailed;
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _loading     = false;
            _verificationId = verificationId;
            _resendToken    = resendToken;
            _phonePhase     = _PhonePhase.otp;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // --- Phone: verify OTP ---
  Future<void> _verifyOtp() async {
    final l = AppLocalizations.of(context);
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      setState(() => _error = l.enterSixDigitCode);
      return;
    }
    setState(() { _loading = true; _error = null; });

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    await _verifyCredential(credential);
  }

  Future<void> _verifyCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('No token');

      final error = await context.read<AuthService>().loginWithPhone(idToken);
      if (mounted) {
        setState(() { _loading = false; _error = error; });
        if (error == null) _navigateHome();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message ?? AppLocalizations.of(context).invalidCode;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Something went wrong.'; });
      }
    }
  }

  void _navigateHome() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  void _showCountryPicker() {
    final searchController = TextEditingController();
    List<_Country> filtered = List.from(_kCountries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize:     0.4,
              maxChildSize:     0.85,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).selectCountry,
                      style: context.tt.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).searchCountry,
                          prefixIcon: Icon(Icons.search, color: context.textHint, size: 20),
                        ),
                        onChanged: (q) {
                          setSheetState(() {
                            filtered = _kCountries
                                .where((c) =>
                                    c.name.toLowerCase().contains(q.toLowerCase()) ||
                                    c.dialCode.contains(q))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          final selected = c.dialCode == _selectedCountry.dialCode &&
                              c.name == _selectedCountry.name;
                          return ListTile(
                            leading: Text(c.flag,
                                style: const TextStyle(fontSize: 26)),
                            title: Text(c.name,
                                style: context.tt.bodyMedium),
                            trailing: Text(
                              c.dialCode,
                              style: TextStyle(
                                color: selected ? context.primary : context.textSecondary,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () {
                              setState(() => _selectedCountry = c);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _switchMode(bool toPhone) {
    setState(() {
      _isPhoneMode = toPhone;
      _error       = null;
      _phonePhase  = _PhonePhase.input;
      _otpController.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // Build helpers
  // ---------------------------------------------------------------------------

  Widget _buildTabSwitcher() {
    final l = AppLocalizations.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color:        context.borderColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTab(l.email, !_isPhoneMode, () => _switchMode(false)),
          _buildTab(l.phone,  _isPhoneMode, () => _switchMode(true)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? context.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(color: context.borderColor, width: 0.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color:      selected ? context.primary : context.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize:   14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller:   _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText:  l.email,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller:  _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText:  l.password,
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        _buildErrorBox(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _loginWithEmail,
          child: _loading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(l.login),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    final l = AppLocalizations.of(context);

    if (_phonePhase == _PhonePhase.input) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Country picker button
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color:        context.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: context.borderColor, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedCountry.flag,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.dialCode,
                        style: TextStyle(
                          color:      context.textPrimary,
                          fontSize:   14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down,
                          color: context.textHint, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller:   _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:  l.phoneNumber,
                    hintText:   '7x xxx xxxx',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
              ),
            ],
          ),
          _buildErrorBox(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(l.sendCode),
          ),
        ],
      );
    }

    // OTP phase
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _loading
                  ? null
                  : () => setState(() {
                        _phonePhase = _PhonePhase.input;
                        _error      = null;
                        _otpController.clear();
                      }),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: context.textSecondary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.codeSentTo(_phoneController.text.trim()),
                style: TextStyle(color: context.textSecondary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller:   _otpController,
          keyboardType: TextInputType.number,
          textAlign:    TextAlign.center,
          maxLength:    6,
          style: TextStyle(
            color:         context.textPrimary,
            fontSize:      28,
            fontWeight:    FontWeight.bold,
            letterSpacing: 14,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText:    '······',
            hintStyle: TextStyle(
              color:         context.textHint,
              fontSize:      28,
              letterSpacing: 14,
            ),
          ),
        ),
        _buildErrorBox(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _verifyOtp,
          child: _loading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(l.verifyAndLogin),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : _sendOtp,
          child: Text(l.resendCode),
        ),
      ],
    );
  }

  Widget _buildErrorBox() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        context.errorBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.errorBorder),
        ),
        child: Text(
          _error!,
          style: TextStyle(color: context.errorColor, fontSize: 13),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / branding
                Container(
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
                const SizedBox(height: 20),
                Text(
                  l.appName,
                  textAlign: TextAlign.center,
                  style: context.tt.titleLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  l.signInToPlay,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: context.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 36),

                // Login card
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
                      _buildTabSwitcher(),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end:   Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_isPhoneMode
                              ? 'phone_${_phonePhase.name}'
                              : 'email'),
                          child: _isPhoneMode
                              ? _buildPhoneForm()
                              : _buildEmailForm(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(l.dontHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
