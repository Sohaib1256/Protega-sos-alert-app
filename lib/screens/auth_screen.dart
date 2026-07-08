
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/theme.dart';
import '../widgets/animated_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  int _signupStep = 0;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.user;
  String? _error;
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _error = null);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (!email.toLowerCase().endsWith('.com')) {
      setState(() => _error = 'Email must end with .com');
      return;
    }

    setState(() => _loading = true);
    // Remove artificial delay, use real auth delay
    final provider = context.read<AppProvider>();
    final result = await provider.login(email, password);
    
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result;
    });
  }

  void _nextSignupStep() {
    HapticFeedback.selectionClick();
    if (_signupStep == 1) {
      _handleSignup();
      return;
    }
    setState(() => _signupStep++);
  }

  void _prevSignupStep() {
    if (_signupStep > 0) {
      setState(() => _signupStep--);
    } else {
      setState(() => _isLogin = true);
    }
  }

  void _handleSignup() async {
    setState(() => _error = null);
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    if (RegExp(r'[0-9]').hasMatch(name)) {
      setState(() => _error = 'Name cannot contain numbers.');
      return;
    }
    if (name.length > 15) {
      setState(() => _error = 'Name must be 15 characters or less.');
      return;
    }
    if (!email.toLowerCase().endsWith('.com')) {
      setState(() => _error = 'Email must end with .com');
      return;
    }
    if (_selectedRole == UserRole.user) {
      final guardianPhone = _guardianPhoneCtrl.text.trim();
      if (guardianPhone.isEmpty) {
        setState(
                () => _error = 'Guardian contact is required for users.');
        return;
      }
      if (guardianPhone.length != 10) {
        setState(
                () => _error = 'Guardian phone must be exactly 10 digits.');
        return;
      }
    }
    if (phone.isNotEmpty && phone.length != 10) {
      setState(() => _error = 'Phone number must be exactly 10 digits.');
      return;
    }

    setState(() => _loading = true);
    // Remove artificial delay
    final provider = context.read<AppProvider>();
    final result = await provider.signup(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
      guardianPhone: _guardianPhoneCtrl.text.trim(),
      phone: phone,
    );
    
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 36),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _isLogin
                        ? _buildLoginForm()
                        : _buildSignupWizard(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accent,
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 36,
          ),
        )
            .animate()
            .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        Text(
          'PROTEGA',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [AppTheme.accent, AppTheme.accentCyan],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
        const SizedBox(height: 6),
        Text(
          'Your Safety Guardian',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey('login'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue monitoring',
                style: TextStyle(
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _glassField(
                controller: _emailCtrl,
                hint: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _glassField(
                controller: _passwordCtrl,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePass,
                maxLength: 15,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.danger.withAlpha(40),
                    ),
                  ),
                  child: Row(
                    children: [
                       const Icon(Icons.error_outline_rounded,
                          color: AppTheme.dangerSoft, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style:  const TextStyle(
                            color: AppTheme.dangerSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildPrimaryButton(
                label: _loading ? 'Signing in...' : 'Sign In',
                onPressed: _loading ? null : _handleLogin,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account? ',
                    style: TextStyle(
                      
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isLogin = false;
                        _signupStep = 0;
                        _error = null;
                      });
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
    );
  }

  Widget _buildSignupWizard() {
    return Container(
      key: const ValueKey('signup'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _prevSignupStep,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Step ${_signupStep + 1} of 2',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStepIndicator(),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: child,
                  );
                },
                child: _buildCurrentStep(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.danger.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                       const Icon(Icons.error_outline_rounded,
                          color: AppTheme.dangerSoft, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style:  const TextStyle(
                            color: AppTheme.dangerSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildPrimaryButton(
                label: _signupStep == 1
                    ? (_loading ? 'Creating account...' : 'Create Account')
                    : 'Continue',
                onPressed: _loading ? null : _nextSignupStep,
              ),
            ],
          ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(2, (i) {
        final isActive = i == _signupStep;
        final isDone = i < _signupStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isDone
                  ? AppTheme.accent
                  : isActive
                  ? AppTheme.accent.withAlpha(180)
                  : Colors.white.withAlpha(15),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_signupStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who are you?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _roleChip('User (Self)', Icons.person_rounded, UserRole.user),
            _roleChip('Guardian', Icons.shield_rounded, UserRole.guardian),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Details',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        _glassField(
          controller: _nameCtrl,
          hint: 'Full Name',
          icon: Icons.person_outline_rounded,
          maxLength: 15,
        ),
        const SizedBox(height: 12),
        _glassField(
          controller: _emailCtrl,
          hint: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _glassField(
          controller: _passwordCtrl,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePass,
          maxLength: 15,
          suffix: IconButton(
            icon: Icon(
              _obscurePass
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        const SizedBox(height: 12),
        _glassField(
          controller: _phoneCtrl,
          hint: 'Phone Number (10 digits)',
          icon: Icons.phone_outlined,
          prefix: _countryCodePrefix(),
          keyboardType: TextInputType.number,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        if (_selectedRole == UserRole.user) ...[
          const SizedBox(height: 12),
          _glassField(
            controller: _guardianPhoneCtrl,
            hint: 'Guardian Phone (10 digits)',
            icon: Icons.shield_outlined,
            prefix: _countryCodePrefix(),
            keyboardType: TextInputType.number,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
        ],
      ],
    );
  }

  Widget _countryCodePrefix() {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6),
      child: const Text(
        '+92',
        style: TextStyle(
          color: AppTheme.accent,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }


  Widget _roleChip(String label, IconData icon, UserRole role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withAlpha(25)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent.withAlpha(120)
                : Colors.white.withAlpha(15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.accent : Theme.of(context).textTheme.bodySmall!.color!,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Theme.of(context).textTheme.bodyLarge!.color!
                    : Theme.of(context).textTheme.bodyMedium!.color!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    int? maxLength,
    TextInputType? keyboardType,
    Widget? suffix,
    Widget? prefix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: TextStyle( fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: prefix ??
            Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: onPressed != null
              ? AppTheme.accent
              : AppTheme.bgField,
        ),
        child: Center(
          child: _loading
              ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: onPressed != null
                  ? Colors.white
                  : Theme.of(context).textTheme.bodySmall!.color!,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}