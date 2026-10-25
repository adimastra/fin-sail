import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/expense_provider.dart';

enum AuthFormMode { signIn, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  AuthFormMode _mode = AuthFormMode.signIn;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    var cleaned = input.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+62${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+62$cleaned';
    }
    return cleaned;
  }

  Future<void> _handlePhoneAuthSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _normalizePhone(_phoneController.text.trim());
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    setState(() => _isLoading = true);
    final provider = context.read<ExpenseProvider>();
    bool success = false;

    if (_mode == AuthFormMode.register) {
      success = await provider.signUpWithPhone(
        phone: phone,
        password: password,
        displayName: name.isNotEmpty ? name : null,
      );
    } else {
      success = await provider.signInWithPhone(
        phone: phone,
        password: password,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (success && _mode == AuthFormMode.register) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account registered successfully! Welcome to Fin Sail.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.seaBlue,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final provider = context.read<ExpenseProvider>();
    final success = await provider.signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() => _isLoading = true);
    final provider = context.read<ExpenseProvider>();
    final success = await provider.signInAsGuest();
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5);
    final inputBorderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C0E) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Brand App Logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.seaBlue.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sailing_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // App Title
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Fin ',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                        ),
                        const TextSpan(
                          text: 'Sail',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppTheme.seaBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Smart Expense Tracking & Receipt OCR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : AppTheme.grayTextMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Form Container: Mode Switcher + Phone/Password Inputs
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: inputBorderColor),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Segmented Mode Selector: Sign In vs Register
                          Container(
                            height: 44,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF09090B) : const Color(0xFFE4E4E7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (_mode != AuthFormMode.signIn) {
                                        setState(() => _mode = AuthFormMode.signIn);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _mode == AuthFormMode.signIn
                                            ? (isDark ? const Color(0xFF27272A) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: _mode == AuthFormMode.signIn
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.1),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _mode == AuthFormMode.signIn
                                              ? (isDark ? Colors.white : AppTheme.pureBlack)
                                              : (isDark ? Colors.white54 : AppTheme.grayTextMuted),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (_mode != AuthFormMode.register) {
                                        setState(() => _mode = AuthFormMode.register);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _mode == AuthFormMode.register
                                            ? (isDark ? const Color(0xFF27272A) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: _mode == AuthFormMode.register
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.1),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _mode == AuthFormMode.register
                                              ? (isDark ? Colors.white : AppTheme.pureBlack)
                                              : (isDark ? Colors.white54 : AppTheme.grayTextMuted),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Full Name Field (Only in Register mode)
                          if (_mode == AuthFormMode.register) ...[
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : AppTheme.pureBlack,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                hintText: 'Full Name',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF09090B) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: inputBorderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: inputBorderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.seaBlue, width: 1.6),
                                ),
                              ),
                              validator: (val) {
                                if (_mode == AuthFormMode.register && (val == null || val.trim().isEmpty)) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Phone Number Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                margin: const EdgeInsets.only(right: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+62',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white70 : AppTheme.pureBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              hintText: '812 3456 7890',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF09090B) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.seaBlue, width: 1.6),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              final digits = val.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 8) {
                                return 'Phone number must be at least 8 digits';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : AppTheme.pureBlack,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 19,
                                  color: isDark ? Colors.white54 : AppTheme.grayTextMuted,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              hintText: 'Password (min. 6 characters)',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF09090B) : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppTheme.seaBlue, width: 1.6),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          // Confirm Password Field (Only in Register mode)
                          if (_mode == AuthFormMode.register) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : AppTheme.pureBlack,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 19,
                                    color: isDark ? Colors.white54 : AppTheme.grayTextMuted,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                hintText: 'Confirm Password',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF09090B) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: inputBorderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: inputBorderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.seaBlue, width: 1.6),
                                ),
                              ),
                              validator: (val) {
                                if (_mode == AuthFormMode.register && val != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Submit Action Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handlePhoneAuthSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.seaBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _mode == AuthFormMode.signIn
                                          ? 'Sign In with Phone'
                                          : 'Create Fin Sail Account',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider OR
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white38 : AppTheme.grayTextMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Google SSO Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : AppTheme.pureBlack,
                        foregroundColor: isDark ? AppTheme.pureBlack : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGoogleIcon(),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Instant Demo / Guest access button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleGuestSignIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : AppTheme.pureBlack,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: isDark ? Colors.white : AppTheme.pureBlack,
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Quick Demo / Guest Access',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subtle footer note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: AppTheme.grayTextMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Secured with Supabase Auth & PostgreSQL Row-Level Security',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : AppTheme.grayTextMuted,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Image.asset(
      'assets/images/google_logo.png',
      width: 18,
      height: 18,
      fit: BoxFit.contain,
    );
  }
}
