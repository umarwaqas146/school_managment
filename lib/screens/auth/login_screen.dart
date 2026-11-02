import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin/dashboard/admin_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import '../student/student_dashboard.dart';
import '../parent/parent_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool hidePassword = true;
  bool rememberMe = false;

  static const Color navy = Color(0xFF06264F);
  static const Color primaryBlue = Color(0xFF1769E0);
  static const Color lightBackground = Color(0xFFF5F8FC);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF172B4D);
  static const Color textGrey = Color(0xFF718096);

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (email.length > 254) {
      return 'Email address is too long';
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9.!#$%&’*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must contain at least 6 characters';
    }

    return null;
  }

  void _showMessage(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(User user) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');

    final uidDoc = await usersCollection.doc(user.uid).get();

    if (uidDoc.exists && uidDoc.data() != null) {
      return uidDoc.data();
    }

    if (user.email != null && user.email!.trim().isNotEmpty) {
      final email = user.email!.trim();

      final exactEmailQuery = await usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (exactEmailQuery.docs.isNotEmpty) {
        return exactEmailQuery.docs.first.data();
      }

      final lowerEmailQuery = await usersCollection
          .where('emailLower', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (lowerEmailQuery.docs.isNotEmpty) {
        return lowerEmailQuery.docs.first.data();
      }
    }

    return null;
  }

  Widget _getDashboardForRole(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();

      case 'teacher':
        return const TeacherDashboard();

      case 'student':
        return const StudentDashboard();

      case 'parent':
        return const ParentDashboard();

      default:
        throw Exception('Invalid user role');
    }
  }

  Future<void> loginUser() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw Exception('Unable to authenticate your account.');
      }

      final data = await _getUserProfile(user);

      if (data == null) {
        await auth.signOut();

        if (!mounted) return;

        _showMessage(
          'Your account is authenticated, but no school profile was found. '
          'Please contact the administrator.',
        );

        return;
      }

      final roleValue = data['role'];

      if (roleValue == null || roleValue.toString().trim().isEmpty) {
        await auth.signOut();

        if (!mounted) return;

        _showMessage(
          'Your school profile does not have a valid role. '
          'Please contact the administrator.',
        );

        return;
      }

      final role = roleValue.toString().trim().toLowerCase();

      const validRoles = {'admin', 'teacher', 'student', 'parent'};

      if (!validRoles.contains(role)) {
        await auth.signOut();

        if (!mounted) return;

        _showMessage('Invalid account role. Please contact the administrator.');

        return;
      }

      final Widget nextScreen = _getDashboardForRole(role);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account exists with this email address.';
          break;

        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;

        case 'user-disabled':
          message =
              'This account has been disabled. '
              'Please contact the administrator.';
          break;

        case 'too-many-requests':
          message =
              'Too many unsuccessful attempts. '
              'Please try again later.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        case 'operation-not-allowed':
          message = 'Email/password login is not enabled in Firebase.';
          break;

        default:
          message = e.message?.trim().isNotEmpty == true
              ? e.message!.trim()
              : 'Login failed. Please try again.';
      }

      _showMessage(message);
    } on FirebaseException catch (e) {
      String message;

      switch (e.code) {
        case 'permission-denied':
          message = 'You do not have permission to access your school profile.';
          break;

        case 'unavailable':
          message = 'Server is temporarily unavailable. Please try again.';
          break;

        default:
          message = e.message?.trim().isNotEmpty == true
              ? e.message!.trim()
              : 'Unable to load your school profile.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Something went wrong while logging in. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();

    final emailError = _validateEmail(email);

    if (emailError != null) {
      _showMessage(emailError);
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email: email);

      _showMessage(
        'Password reset email has been sent. Check your inbox.',
        backgroundColor: Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account exists with this email address.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;

        default:
          message = e.message?.trim().isNotEmpty == true
              ? e.message!.trim()
              : 'Unable to send password reset email.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Unable to send password reset email. Please try again.');
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryBlue),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: Color(0xFF9AA5B1)),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      width: 390,
      decoration: const BoxDecoration(color: navy),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.035),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.035),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset(
                      'assets/images/icons/logos/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'The Sapient\nSchool',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'School Management\nSystem',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 17,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 42),

                  Container(
                    width: 55,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C9AFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    'Manage students, teachers,\nclasses and school operations\nfrom one powerful platform.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.62),
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 45),

                  Row(
                    children: [
                      _brandFeature(Icons.people_outline, 'Students'),
                      const SizedBox(width: 18),
                      _brandFeature(Icons.school_outlined, 'Teachers'),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      _brandFeature(Icons.analytics_outlined, 'Reports'),
                      const SizedBox(width: 18),
                      _brandFeature(Icons.security_outlined, 'Secure'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandFeature(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF73B5FF), size: 19),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPanel() {
    return Expanded(
      child: Container(
        color: lightBackground,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 35),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 15,
                                color: primaryBlue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Secure Portal',
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'v1.0.0',
                          style: TextStyle(color: textGrey, fontSize: 12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 55),

                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Sign in to access your school management portal.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 38),

                    const Text(
                      'Email Address',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 9),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      decoration: _inputDecoration(
                        label: 'Email',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Password',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 9),

                    TextFormField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!isLoading) {
                          loginUser();
                        }
                      },
                      validator: _validatePassword,
                      decoration: _inputDecoration(
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: textGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: Checkbox(
                            value: rememberMe,
                            activeColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            onChanged: isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      rememberMe = value ?? false;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: isLoading ? null : resetPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 27),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: const Color(0xFF9DB9E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 9),
                                  Icon(Icons.arrow_forward_rounded, size: 19),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            'AUTHORIZED ACCESS',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure & Protected',
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your school data is protected.',
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    Center(
                      child: Text(
                        '© 2026 The Sapient School • All rights reserved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(children: [_buildBrandPanel(), _buildLoginPanel()]);
  }

  Widget _buildMobileLayout() {
    return Container(
      color: lightBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/icons/logos/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Center(
                  child: Text(
                    'The Sapient School',
                    style: TextStyle(
                      color: navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                const Center(
                  child: Text(
                    'School Management System',
                    style: TextStyle(color: textGrey, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 38),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sign in to continue to your portal.',
                        style: TextStyle(color: textGrey, fontSize: 13),
                      ),

                      const SizedBox(height: 28),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                        decoration: _inputDecoration(
                          label: 'Email',
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!isLoading) {
                            loginUser();
                          }
                        },
                        validator: _validatePassword,
                        decoration: _inputDecoration(
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      hidePassword = !hidePassword;
                                    });
                                  },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textGrey,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Checkbox(
                              value: rememberMe,
                              activeColor: primaryBlue,
                              onChanged: isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        rememberMe = value ?? false;
                                      });
                                    },
                            ),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(color: textGrey, fontSize: 12),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: isLoading ? null : resetPassword,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Center(
                  child: Text(
                    '© 2026 The Sapient School',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 900;

          return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
        },
      ),
    );
  }
}
