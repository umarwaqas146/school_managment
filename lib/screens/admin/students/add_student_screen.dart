import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSaving = false;

  final Color navy = const Color(0xFF06264F);
  final Color blue = const Color(0xFF1769E0);

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _cnicController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  String? _nameValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }

    final nameRegex = RegExp(r"^[A-Za-zÀ-ÿ]+(?:[\s'-][A-Za-zÀ-ÿ]+)*$");

    if (!nameRegex.hasMatch(value.trim())) {
      return '$field can contain letters and spaces only';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }

    final phoneRegex = RegExp(r'^03\d{9}$');

    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Use format 03001234567';
    }

    return null;
  }

  String? _cnicValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'B-Form / CNIC is required';
    }

    final cnicRegex = RegExp(r'^\d{5}-\d{7}-\d$');

    if (!cnicRegex.hasMatch(value.trim())) {
      return 'Use format XXXXX-XXXXXXX-X';
    }

    return null;
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Admin session not found. Please login again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final studentsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('students');

      final email = _emailController.text.trim().toLowerCase();
      final phone = _phoneController.text.trim();
      final cnic = _cnicController.text.trim();
      final studentId = _studentIdController.text.trim();

      // Check duplicate email
      final emailQuery = await studentsRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        _showMessage(
          'A student with this email already exists.',
          isError: true,
        );
        return;
      }

      // Check duplicate phone
      final phoneQuery = await studentsRef
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        _showMessage(
          'A student with this phone number already exists.',
          isError: true,
        );
        return;
      }

      // Check duplicate CNIC / B-Form
      final cnicQuery = await studentsRef
          .where('cnic', isEqualTo: cnic)
          .limit(1)
          .get();

      if (cnicQuery.docs.isNotEmpty) {
        _showMessage(
          'A student with this B-Form / CNIC already exists.',
          isError: true,
        );
        return;
      }

      // Check duplicate Student ID
      final studentIdQuery = await studentsRef
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (studentIdQuery.docs.isNotEmpty) {
        _showMessage(
          'A student with this Student ID already exists.',
          isError: true,
        );
        return;
      }

      final studentDoc = studentsRef.doc();

      await studentDoc.set({
        'studentId': studentId,
        'studentName': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),

        // Single field for both B-Form and CNIC
        'cnic': cnic,

        'email': email,
        'phone': phone,
        'class': _classController.text.trim(),
        'section': _sectionController.text.trim(),
        'address': _addressController.text.trim(),
        'role': 'student',

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Student added successfully.', isError: false);

      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Firebase error occurred while saving student.',
        isError: true,
      );
    } catch (e) {
      _showMessage('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: blue),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon, hint: hint),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: blue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: blue, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'Add Student',
          style: TextStyle(color: navy, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: navy),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 28 : 16,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [navy, blue]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Student Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Enter accurate student information below.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildFormCard(
                      title: 'Personal Information',
                      icon: Icons.person_outline_rounded,
                      children: [
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _nameController,
                                  label: 'Student Name',
                                  icon: Icons.person_outline,
                                  validator: (value) =>
                                      _nameValidator(value, 'Student Name'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _fatherNameController,
                                  label: 'Father Name',
                                  icon: Icons.person_outline,
                                  validator: (value) =>
                                      _nameValidator(value, 'Father Name'),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _field(
                            controller: _nameController,
                            label: 'Student Name',
                            icon: Icons.person_outline,
                            validator: (value) =>
                                _nameValidator(value, 'Student Name'),
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _fatherNameController,
                            label: 'Father Name',
                            icon: Icons.person_outline,
                            validator: (value) =>
                                _nameValidator(value, 'Father Name'),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ⭐ B-FORM / CNIC FIELD
                        _field(
                          controller: _cnicController,
                          label: 'B-Form / CNIC',
                          icon: Icons.badge_outlined,
                          hint: 'XXXXX-XXXXXXX-X',
                          keyboardType: TextInputType.number,
                          validator: _cnicValidator,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildFormCard(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_outlined,
                      children: [
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  icon: Icons.phone_outlined,
                                  hint: '03001234567',
                                  keyboardType: TextInputType.phone,
                                  validator: _phoneValidator,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _field(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _phoneController,
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            hint: '03001234567',
                            keyboardType: TextInputType.phone,
                            validator: _phoneValidator,
                          ),
                        ],

                        const SizedBox(height: 16),

                        _field(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                          validator: (value) =>
                              _requiredValidator(value, 'Address'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildFormCard(
                      title: 'Academic Information',
                      icon: Icons.school_outlined,
                      children: [
                        if (isDesktop)
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _studentIdController,
                                  label: 'Student ID',
                                  icon: Icons.numbers_outlined,
                                  validator: (value) =>
                                      _requiredValidator(value, 'Student ID'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _classController,
                                  label: 'Class',
                                  icon: Icons.class_outlined,
                                  validator: (value) =>
                                      _requiredValidator(value, 'Class'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _sectionController,
                                  label: 'Section',
                                  icon: Icons.grid_view_rounded,
                                  validator: (value) =>
                                      _requiredValidator(value, 'Section'),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _field(
                            controller: _studentIdController,
                            label: 'Student ID',
                            icon: Icons.numbers_outlined,
                            validator: (value) =>
                                _requiredValidator(value, 'Student ID'),
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _classController,
                            label: 'Class',
                            icon: Icons.class_outlined,
                            validator: (value) =>
                                _requiredValidator(value, 'Class'),
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _sectionController,
                            label: 'Section',
                            icon: Icons.grid_view_rounded,
                            validator: (value) =>
                                _requiredValidator(value, 'Section'),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveStudent,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'Saving Student...' : 'Save Student',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
