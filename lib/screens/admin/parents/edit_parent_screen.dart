import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditParentScreen extends StatefulWidget {
  final Map<String, dynamic> parentData;
  final String docId;

  const EditParentScreen({
    super.key,
    required this.parentData,
    required this.docId,
  });

  @override
  State<EditParentScreen> createState() => _EditParentScreenState();
}

class _EditParentScreenState extends State<EditParentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _parentNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _studentNameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _relationController;
  late final TextEditingController _addressController;

  bool _isSaving = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _parentsCollection {
    final uid = _uid;

    if (uid == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('parents');
  }

  String _value(String primaryKey, String fallbackKey) {
    final primary = (widget.parentData[primaryKey] ?? '').toString().trim();

    if (primary.isNotEmpty) {
      return primary;
    }

    return (widget.parentData[fallbackKey] ?? '').toString().trim();
  }

  @override
  void initState() {
    super.initState();

    _parentNameController = TextEditingController(
      text: _value('parentName', 'name'),
    );

    _emailController = TextEditingController(
      text: (widget.parentData['email'] ?? '').toString(),
    );

    _phoneController = TextEditingController(
      text: (widget.parentData['phone'] ?? '').toString(),
    );

    _studentNameController = TextEditingController(
      text: (widget.parentData['studentName'] ?? '').toString(),
    );

    _studentIdController = TextEditingController(
      text: (widget.parentData['studentId'] ?? '').toString(),
    );

    _relationController = TextEditingController(
      text: (widget.parentData['relation'] ?? '').toString(),
    );

    _addressController = TextEditingController(
      text: (widget.parentData['address'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentNameController.dispose();
    _studentIdController.dispose();
    _relationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    return null;
  }

  String? _validateName(String? value) {
    final required = _required(value, 'Parent name');

    if (required != null) {
      return required;
    }

    final name = value!.trim();

    if (name.length < 3) {
      return 'Parent name must be at least 3 characters';
    }

    if (name.length > 60) {
      return 'Parent name is too long';
    }

    final regex = RegExp(r"^[a-zA-Z\s.'-]+$");

    if (!regex.hasMatch(name)) {
      return 'Only letters, spaces, apostrophe and hyphen are allowed';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final required = _required(value, 'Email');

    if (required != null) {
      return required;
    }

    final email = value!.trim();

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
    final required = _required(value, 'Phone');

    if (required != null) {
      return required;
    }

    final phone = value!.trim();

    if (!RegExp(r'^03[0-9]{9}$').hasMatch(phone)) {
      return 'Use Pakistani format: 03001234567';
    }

    return null;
  }

  String? _validateStudentName(String? value) {
    final required = _required(value, 'Student name');

    if (required != null) {
      return required;
    }

    final name = value!.trim();

    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(name)) {
      return 'Only letters, spaces, apostrophe and hyphen are allowed';
    }

    return null;
  }

  String? _validateStudentId(String? value) {
    final required = _required(value, 'Student ID');

    if (required != null) {
      return required;
    }

    if (value!.trim().length < 2) {
      return 'Enter a valid student ID';
    }

    return null;
  }

  String? _validateRelation(String? value) {
    final required = _required(value, 'Relation');

    if (required != null) {
      return required;
    }

    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value!.trim())) {
      return 'Enter a valid relation';
    }

    return null;
  }

  String? _validateAddress(String? value) {
    final required = _required(value, 'Address');

    if (required != null) {
      return required;
    }

    if (value!.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }

    return null;
  }

  Future<bool> _isDuplicate({
    required String email,
    required String phone,
  }) async {
    final collection = _parentsCollection;

    if (collection == null) {
      return false;
    }

    final emailQuery = await collection.where('email', isEqualTo: email).get();

    for (final doc in emailQuery.docs) {
      if (doc.id != widget.docId) {
        return true;
      }
    }

    final phoneQuery = await collection.where('phone', isEqualTo: phone).get();

    for (final doc in phoneQuery.docs) {
      if (doc.id != widget.docId) {
        return true;
      }
    }

    return false;
  }

  Future<void> _updateParent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final collection = _parentsCollection;

    if (collection == null) {
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

    final parentName = _parentNameController.text.trim();

    final email = _emailController.text.trim().toLowerCase();

    final phone = _phoneController.text.trim();

    final studentName = _studentNameController.text.trim();

    final studentId = _studentIdController.text.trim();

    final relation = _relationController.text.trim();

    final address = _addressController.text.trim();

    try {
      final duplicate = await _isDuplicate(email: email, phone: phone);

      if (duplicate) {
        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Another parent already has this email or phone.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      await collection.doc(widget.docId).update({
        'parentName': parentName,
        'name': parentName,
        'email': email,
        'phone': phone,
        'studentName': studentName,
        'studentId': studentId,
        'relation': relation,
        'address': address,
        'role': 'parent',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parent updated successfully.'),
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
          content: Text(e.message ?? 'Unable to update parent.'),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Parent',
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
                          'Update Parent Profile',
                          style: TextStyle(
                            color: Color(0xFF0B1F3A),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Update the parent information below.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 22),

                        _buildSection(
                          title: 'Parent Information',
                          icon: Icons.person_outline_rounded,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final twoColumns = constraints.maxWidth >= 650;

                              if (!twoColumns) {
                                return Column(
                                  children: [
                                    _buildField(
                                      controller: _parentNameController,
                                      label: 'Parent Name',
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
                                    const SizedBox(height: 14),
                                    _buildField(
                                      controller: _relationController,
                                      label: 'Relation',
                                      hint: 'Father, Mother, Guardian...',
                                      icon: Icons.family_restroom,
                                      validator: _validateRelation,
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
                                          controller: _parentNameController,
                                          label: 'Parent Name',
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
                                  Row(
                                    children: [
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
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildField(
                                          controller: _relationController,
                                          label: 'Relation',
                                          hint: 'Father, Mother, Guardian...',
                                          icon: Icons.family_restroom,
                                          validator: _validateRelation,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildSection(
                          title: 'Student Information',
                          icon: Icons.school_outlined,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final twoColumns = constraints.maxWidth >= 650;

                              if (!twoColumns) {
                                return Column(
                                  children: [
                                    _buildField(
                                      controller: _studentNameController,
                                      label: 'Student Name',
                                      hint: 'Enter student full name',
                                      icon: Icons.person_outline,
                                      validator: _validateStudentName,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildField(
                                      controller: _studentIdController,
                                      label: 'Student ID',
                                      hint: 'Enter student ID',
                                      icon: Icons.badge_outlined,
                                      validator: _validateStudentId,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      controller: _studentNameController,
                                      label: 'Student Name',
                                      hint: 'Enter student full name',
                                      icon: Icons.person_outline,
                                      validator: _validateStudentName,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildField(
                                      controller: _studentIdController,
                                      label: 'Student ID',
                                      hint: 'Enter student ID',
                                      icon: Icons.badge_outlined,
                                      validator: _validateStudentId,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildSection(
                          title: 'Address',
                          icon: Icons.location_on_outlined,
                          child: _buildField(
                            controller: _addressController,
                            label: 'Address',
                            hint: 'Enter complete residential address',
                            icon: Icons.home_outlined,
                            validator: _validateAddress,
                            maxLines: 3,
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
                              onPressed: _isSaving ? null : _updateParent,
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
                                _isSaving ? 'Updating...' : 'Update Parent',
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
