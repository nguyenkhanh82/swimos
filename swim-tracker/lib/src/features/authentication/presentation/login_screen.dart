import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool isSignUp; // Accepts optional initial state
  const LoginScreen({super.key, this.isSignUp = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late bool _isSignUp;
  bool _isLoading = false;
  bool _rememberMe = false;
  String _selectedRole = 'parent'; // 'parent' or 'swimmer'

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();

      // Basic validation
      if (email.isEmpty) {
        throw const AuthException('Email is required');
      }
      if (password.isEmpty) {
        throw const AuthException('Password is required');
      }
      if (!_isValidEmail(email)) {
        throw const AuthException('Please enter a valid email address');
      }

      if (_isSignUp) {
        if (name.isEmpty) throw const AuthException('Name is required');
        if (password.length < 6) {
          throw const AuthException('Password must be at least 6 characters');
        }

        final response = await authRepo.signUpWithEmailAndPassword(
          email,
          password,
          name,
          role: _selectedRole,
        );

        // If session is null, check if it's email confirmation or duplicate
        if (response.session == null && mounted) {
          // Check if user was actually created (not a duplicate)
          if (response.user != null) {
            // This could be either:
            // 1. Email confirmation required (new account)
            // 2. Duplicate email (but we should have caught this in the repository)
            // For safety, show email confirmation message
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Account Created',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Text(
                  'Please check your email ($email) to confirm your account before logging in.',
                  style: GoogleFonts.outfit(),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(
                          () => _isSignUp = false); // Switch to Sign In tab
                    },
                    child: Text('OK',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        } else if (mounted) {
          // Account created successfully with session
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await authRepo.signInWithEmailAndPassword(email, password);
      }
    } on AuthException catch (e) {
      if (mounted) {
        // Show user-friendly error message
        String errorMessage = e.message;
        final isDuplicateEmail =
            errorMessage.toLowerCase().contains('already exists') ||
                errorMessage.toLowerCase().contains('already registered');

        if (isDuplicateEmail) {
          // Show dialog with options for duplicate email
          _showDuplicateEmailDialog(context, _emailController.text.trim());
        } else if (errorMessage.toLowerCase().contains('invalid login')) {
          errorMessage = 'Invalid email or password. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (errorMessage.toLowerCase().contains('email not confirmed')) {
          errorMessage =
              'Please check your email and confirm your account before signing in.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred. Please try again.';
        final errorStr = e.toString().toLowerCase();
        final isDuplicateEmail = errorStr.contains('already exists') ||
            errorStr.contains('already registered');

        if (isDuplicateEmail) {
          // Show dialog with options for duplicate email
          _showDuplicateEmailDialog(context, _emailController.text.trim());
        } else if (errorStr.contains('network') ||
            errorStr.contains('connection')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9), // Slate 100
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Color(0xFF0F172A), size: 18),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/welcome'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4), // Cyan 500
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.pool, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Sign up to start your journey'
                      : 'Sign in to continue your training journey',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),

                // Form
                if (_isSignUp) ...[
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    hint: 'Alex Johnson',
                  ),
                  const SizedBox(height: 20),
                  // Role Selection
                  _buildRoleSelector(),
                  const SizedBox(height: 20),
                ],

                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  hint: 'alex.johnson@email.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                if (!_isSignUp) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) =>
                                  setState(() => _rememberMe = val ?? false),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              activeColor: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: GoogleFonts.outfit(
                                color: const Color(0xFF334155),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _handleForgotPassword(
                            context, _emailController.text.trim()),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.outfit(
                              color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isSignUp ? 'Sign Up' : 'Sign In',
                            style: GoogleFonts.outfit(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[200])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style:
                            GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[200])),
                  ],
                ),
                const SizedBox(height: 32),

                // Social Buttons
                Row(
                  children: [
                    Expanded(
                        child: _buildSocialButton('Google',
                            Icons.g_mobiledata)), // Get actual Google Logo
                    const SizedBox(width: 16),
                    Expanded(child: _buildSocialButton('Apple', Icons.apple)),
                  ],
                ),

                const SizedBox(height: 32),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp
                          ? 'Already have an account?'
                          : "Don't have an account?",
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp ? 'Sign In' : 'Sign Up',
                        style: GoogleFonts.outfit(
                            color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Slate 50
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.transparent), // No border by default
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  color: const Color(0xFF94A3B8),
                  size: 20), // Icon Color Slate 400
              suffixIcon: isPassword
                  ? const Icon(Icons.visibility_outlined,
                      color: Color(0xFF94A3B8))
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData icon) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.black87, size: 24),
        label: Text(label,
            style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                label: 'Parent',
                icon: Icons.family_restroom,
                value: 'parent',
                description: 'Track multiple swimmers',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleOption(
                label: 'Swimmer',
                icon: Icons.person,
                value: 'swimmer',
                description: 'Track yourself',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String label,
    required IconData icon,
    required String value,
    required String description,
  }) {
    final isSelected = _selectedRole == value;
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFF94A3B8),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF0F172A),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDuplicateEmailDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Account Already Exists',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'An account with this email ($email) already exists. Would you like to sign in or reset your password?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isSignUp = false); // Switch to Sign In tab
            },
            child: Text(
              'Sign In',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _handleForgotPassword(context, email);
            },
            child: Text(
              'Reset Password',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0EA5E9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForgotPassword(BuildContext context, String email) async {
    // Validate email
    if (email.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your email address'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_isValidEmail(email)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(email);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Password Reset Email Sent',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'We\'ve sent a password reset link to $email. Please check your email and follow the instructions to reset your password.',
              style: GoogleFonts.outfit(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_isSignUp) {
                    setState(() => _isSignUp = false); // Switch to Sign In tab
                  }
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reset email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
