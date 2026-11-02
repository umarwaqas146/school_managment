import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditUserScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditUserScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  late String _selectedRole;

  bool _isSaving = false;

  final List<String> _roles = const ['admin', 'teacher', 'student', 'parent'];

  String _value(String key) {
    return (widget.userData[key] ?? '').toString().trim();
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: _value('name'));

    _phoneController = TextEditingController(text: _value('phone'));

    final role = _value('role').toLowerCase();

    _selectedRole = _roles.contains(role) ? role : 'student';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }

    final phone = value.trim();

    if (!RegExp(r'^03[0-9]{9}$').hasMatch(phone)) {
      return 'Use Pakistani format: 03001234567';
    }

    return null;
  }

  Future<bool> _isPhoneDuplicate(String phone) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    for (final doc in query.docs) {
      if (doc.id != widget.userId) {
        return true;
      }
    }

    return false;
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      final duplicate = await _isPhoneDuplicate(phone);

      if (duplicate) {
        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Another user already has this phone number.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
            'name': name,
            'phone': phone,
            'role': _selectedRole,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unable to update user.'),
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
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

  @override
  Widget build(BuildContext context) {
    final email = _value('email');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit User',
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
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update User Profile',
                          style: TextStyle(
                            color: Color(0xFF0B1F3A),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Update user information and system role.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),

                        _buildSection(
                          title: 'User Information',
                          icon: Icons.person_outline,
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

                              return Row(
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
                                      controller: _phoneController,
                                      label: 'Phone',
                                      hint: '03001234567',
                                      icon: Icons.phone_outlined,
                                      validator: _validatePhone,
                                      keyboardType: TextInputType.phone,
                                    ),
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
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final twoColumns =
                                      constraints.maxWidth >= 650;

                                  if (!twoColumns) {
                                    return Column(
                                      children: [
                                        _buildField(
                                          controller: TextEditingController(
                                            text: email,
                                          ),
                                          label: 'Email',
                                          hint: 'User email',
                                          icon: Icons.email_outlined,
                                          validator: (value) {
                                            return null;
                                          },
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 14),
                                        _buildRoleDropdown(),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildField(
                                          controller: TextEditingController(
                                            text: email,
                                          ),
                                          label: 'Email',
                                          hint: 'User email',
                                          icon: Icons.email_outlined,
                                          validator: (value) {
                                            return null;
                                          },
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(child: _buildRoleDropdown()),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFD),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Color(0xFF1769E0),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Text(
                                        'Email and password are managed through Firebase Authentication. Password is not changed from this profile screen.',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 11.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
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
                              onPressed: _isSaving ? null : _updateUser,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving ? 'Updating...' : 'Update User',
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
