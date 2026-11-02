import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'teacher';

  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _roles = const ['admin', 'teacher', 'student', 'parent'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    final name = value.trim();

    if (name.length < 3) {
      return 'Name must be at least 3 characters';
    }

    if (name.length > 60) {
      return 'Name is too long';
    }

    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(name)) {
      return 'Only letters, spaces, apostrophe and hyphen are allowed';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@'
      r'[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );

    if (!regex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }

    if (!RegExp(r'^03[0-9]{9}$').hasMatch(value.trim())) {
      return 'Use Pakistani format: 03001234567';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Future<bool> _checkDuplicateUser({
    required String email,
    required String phone,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final emailQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (emailQuery.docs.isNotEmpty) {
      return true;
    }

    final phoneQuery = await firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    return phoneQuery.docs.isNotEmpty;
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final role = _selectedRole;

    final currentAdmin = FirebaseAuth.instance.currentUser;

    if (currentAdmin == null) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin session not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    try {
      final duplicate = await _checkDuplicateUser(email: email, phone: phone);

      if (duplicate) {
        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A user with this email or phone already exists.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      /*
       * Create Firebase Authentication account.
       *
       * IMPORTANT:
       * Password is only sent to Firebase Authentication.
       * It is NOT stored in Firestore.
       */
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final newUser = credential.user;

      if (newUser == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Firebase Authentication user was not created.',
        );
      }

      /*
       * IMPORTANT:
       * Profile document uses Firebase Auth UID.
       *
       * users/{newAuthUid}
       */
      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUser.uid)
          .set({
            'uid': newUser.uid,
            'name': name,
            'email': email,
            'phone': phone,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'createdBy': currentAdmin.uid,
          });

      /*
       * Sign out newly-created account so the admin
       * session does not get replaced by the new user's session.
       *
       * NOTE:
       * This approach can require the admin to login again.
       * A production architecture should preferably use
       * Firebase Admin SDK / Cloud Functions for account creation.
       */
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User created successfully. Please login again as admin.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'invalid-email':
          message = 'The email address is invalid.';
          break;

        case 'weak-password':
          message = 'The password is too weak.';
          break;

        case 'operation-not-allowed':
          message = 'Email/password authentication is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        default:
          message = e.message ?? 'Unable to create user.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Firebase error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: const InputDecoration(
        labelText: 'Role',
        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
      ),
      items: _roles.map((role) {
        return DropdownMenuItem<String>(
          value: role,
          child: Text(role[0].toUpperCase() + role.substring(1)),
        );
      }).toList(),
      onChanged: _isSaving
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                _selectedRole = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Role is required';
        }

        return null;
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: const Color(0xFF1769E0), size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0B1F3A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildPasswordHint() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Text(
        'Password: minimum 8 characters, including uppercase, lowercase and number.',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add User',
          style: TextStyle(
            color: Color(0xFF0B1F3A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create System User',
                          style: TextStyle(
                            color: Color(0xFF0B1F3A),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create a new Firebase Authentication account and user profile.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),

                        _buildSection(
                          title: 'Basic Information',
                          icon: Icons.person_outline_rounded,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final twoColumns = constraints.maxWidth >= 650;

                              if (!twoColumns) {
                                return Column(
                                  children: [
                                    _buildField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      hint: 'Enter full name',
                                      icon: Icons.person_outline,
                                      validator: _validateName,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'example@gmail.com',
                                      icon: Icons.email_outlined,
                                      validator: _validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildField(
                                      controller: _phoneController,
                                      label: 'Phone',
                                      hint: '03001234567',
                                      icon: Icons.phone_outlined,
                                      validator: _validatePhone,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildField(
                                          controller: _nameController,
                                          label: 'Full Name',
                                          hint: 'Enter full name',
                                          icon: Icons.person_outline,
                                          validator: _validateName,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildField(
                                          controller: _emailController,
                                          label: 'Email',
                                          hint: 'example@gmail.com',
                                          icon: Icons.email_outlined,
                                          validator: _validateEmail,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _phoneController,
                                    label: 'Phone',
                                    hint: '03001234567',
                                    icon: Icons.phone_outlined,
                                    validator: _validatePhone,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildSection(
                          title: 'Account Settings',
                          icon: Icons.security_outlined,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final twoColumns = constraints.maxWidth >= 650;

                              if (!twoColumns) {
                                return Column(
                                  children: [
                                    _buildRoleDropdown(),
                                    const SizedBox(height: 14),
                                    _buildField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'Create strong password',
                                      icon: Icons.lock_outline,
                                      validator: _validatePassword,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    _buildPasswordHint(),
                                    const SizedBox(height: 14),
                                    _buildField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      hint: 'Re-enter password',
                                      icon: Icons.lock_reset_outlined,
                                      validator: _validateConfirmPassword,
                                      obscureText: _obscureConfirmPassword,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildRoleDropdown()),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildField(
                                          controller: _passwordController,
                                          label: 'Password',
                                          hint: 'Create strong password',
                                          icon: Icons.lock_outline,
                                          validator: _validatePassword,
                                          obscureText: _obscurePassword,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildPasswordHint(),
                                  const SizedBox(height: 14),
                                  _buildField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Re-enter password',
                                    icon: Icons.lock_reset_outlined,
                                    validator: _validateConfirmPassword,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 22),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD5E5FF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF1769E0),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'The password is stored securely by Firebase Authentication and is not saved in Firestore.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade800,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _isSaving ? null : _createUser,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1_rounded),
                              label: Text(
                                _isSaving ? 'Creating...' : 'Create User',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
