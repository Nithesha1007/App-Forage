import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Sign-in fields
  final _signInEmail = TextEditingController();
  final _signInPassword = TextEditingController();

  // Sign-up fields
  final _signUpName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();
  final _signUpConfirm = TextEditingController();

  bool _obscureSignIn = true;
  bool _obscureSignUp = true;
  bool _obscureConfirm = true;

  // ✅ Local loading state (AuthProvider has no isLoading getter)
  bool _loading = false;
  bool _loadingRole = false; // Track role-fetch state

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    _signUpConfirm.dispose();
    super.dispose();
  }

  // ── Role-aware redirect ─────────────────────────────────────────────────
  void _redirectAfterLogin(AuthProvider auth) {
    if (!mounted) return;
    if (auth.status == AuthStatus.authenticated) {
      // ✅ Wait for role to load, then redirect based on role
      if (auth.roleLoaded) {
        setState(() => _loadingRole = false);
        Future.microtask(() {
          if (mounted) context.go(auth.isAdmin ? '/admin' : '/home');
        });
      } else {
        // Role not loaded yet — show loading and wait for it
        setState(() => _loadingRole = true);
        void listen() {
          if (!mounted) return;
          if (auth.roleLoaded) {
            auth.removeListener(listen);
            setState(() => _loadingRole = false);
            Future.microtask(() {
              if (mounted) context.go(auth.isAdmin ? '/admin' : '/home');
            });
          }
        }

        auth.addListener(listen);
      }
    }
  }

  Future<void> _signIn(AuthProvider auth) async {
    setState(() => _loading = true);
    // ✅ signIn(email, password) — correct method name
    await auth.signIn(_signInEmail.text.trim(), _signInPassword.text);
    setState(() => _loading = false);
    _redirectAfterLogin(auth);
  }

  Future<void> _signUp(AuthProvider auth) async {
    if (_signUpPassword.text != _signUpConfirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    // ✅ signUp(email, password, name) — correct method name (was 'register')
    await auth.signUp(
      _signUpEmail.text.trim(),
      _signUpPassword.text,
      _signUpName.text.trim(),
    );
    setState(() => _loading = false);
    _redirectAfterLogin(auth);
  }

  Future<void> _googleSignIn(AuthProvider auth) async {
    setState(() => _loading = true);
    // ✅ signInWithGoogle() — correct method name
    await auth.signInWithGoogle();
    setState(() => _loading = false);
    _redirectAfterLogin(auth);
  }

  Future<void> _forgotPassword(AuthProvider auth) async {
    final email = _signInEmail.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first'),
          backgroundColor: AppTheme.accent,
        ),
      );
      return;
    }
    // ✅ sendPasswordReset directly via FirebaseAuth — AuthProvider has no such method
    try {
      await auth.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset email sent! Check your inbox.'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send reset email. Check address.'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Logo ──────────────────────────────────────────────────────
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('⚡', style: TextStyle(fontSize: 40)),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  const Text(
                    'AppForge',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const Text(
                    'Build apps without code',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),

              const SizedBox(height: 36),

              // ── Tab switcher ──────────────────────────────────────────────
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4F6FFF),
                            AppTheme.primary.withOpacity(0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // ── Role loading indicator ────────────────────────────────────
              if (_loadingRole)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Loading your dashboard...',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              // ── Error banner ──────────────────────────────────────────────
              if (auth.errorMessage != null && !_loadingRole)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().shakeX(),

              // ── Tab forms ─────────────────────────────────────────────────
              if (!_loadingRole)
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _tabs.index == 0
                          ? _SignInForm(
                              key: const ValueKey('signin'),
                              emailCtrl: _signInEmail,
                              passwordCtrl: _signInPassword,
                              obscure: _obscureSignIn,
                              onToggleObscure: () => setState(
                                () => _obscureSignIn = !_obscureSignIn,
                              ),
                              onSignIn: () => _signIn(auth),
                              onForgot: () => _forgotPassword(auth),
                              // ✅ uses local _loading, not auth.isLoading
                              loading: _loading,
                            )
                          : _SignUpForm(
                              key: const ValueKey('signup'),
                              nameCtrl: _signUpName,
                              emailCtrl: _signUpEmail,
                              passwordCtrl: _signUpPassword,
                              confirmCtrl: _signUpConfirm,
                              obscurePass: _obscureSignUp,
                              obscureConfirm: _obscureConfirm,
                              onTogglePass: () => setState(
                                () => _obscureSignUp = !_obscureSignUp,
                              ),
                              onToggleConfirm: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              onSignUp: () => _signUp(auth),
                              loading: _loading,
                            ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Divider ───────────────────────────────────────────────────
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: const Divider(
                          thickness: 1,
                          color: AppTheme.darkBorder,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: const Divider(
                          thickness: 1,
                          color: AppTheme.darkBorder,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Google Sign-In ────────────────────────────────────────────
              if (!_loadingRole)
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _googleSignIn(auth),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.darkBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign In form (improved layout) ─────────────────────────────────────────────
class _SignInForm extends StatelessWidget {
  final TextEditingController emailCtrl, passwordCtrl;
  final bool obscure, loading;
  final VoidCallback onToggleObscure, onSignIn, onForgot;

  const _SignInForm({
    super.key,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onSignIn,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: _Field(
            ctrl: emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            type: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: _Field(
            ctrl: passwordCtrl,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscure: obscure,
            suffix: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgot,
              child: const Text(
                'Forgot password?',
                style: TextStyle(color: AppTheme.primary, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: ElevatedButton(
            onPressed: loading ? null : onSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F6FFF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    ),
  );
}

// ── Sign Up form (improved layout) ────────────────────────────────────────────
class _SignUpForm extends StatelessWidget {
  final TextEditingController nameCtrl, emailCtrl, passwordCtrl, confirmCtrl;
  final bool obscurePass, obscureConfirm, loading;
  final VoidCallback onTogglePass, onToggleConfirm, onSignUp;

  const _SignUpForm({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.loading,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: _Field(
            ctrl: nameCtrl,
            hint: 'Full name',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: _Field(
            ctrl: emailCtrl,
            hint: 'Email address',
            icon: Icons.email_outlined,
            type: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: _Field(
            ctrl: passwordCtrl,
            hint: 'Password (min 6 chars)',
            icon: Icons.lock_outline,
            obscure: obscurePass,
            suffix: IconButton(
              icon: Icon(
                obscurePass
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: onTogglePass,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: _Field(
            ctrl: confirmCtrl,
            hint: 'Confirm password',
            icon: Icons.lock_outline,
            obscure: obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppTheme.textMuted,
              ),
              onPressed: onToggleConfirm,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: ElevatedButton(
            onPressed: loading ? null : onSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F6FFF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    ),
  );
}

// ── Reusable text field (unchanged UI) ────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType type;
  final Widget? suffix;

  const _Field({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.type = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: obscure,
    keyboardType: type,
    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppTheme.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    ),
  );
}
