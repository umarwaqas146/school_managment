import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController subjectController = TextEditingController();

  final TextEditingController qualificationController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  bool isLoading = false;

  // ============================================================
  // CURRENT ADMIN UID
  // ============================================================

  String get adminId {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid.isEmpty) {
      throw Exception('You are not logged in.');
    }

    return user.uid;
  }

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? _nameValidator(String? value, String fieldName) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$fieldName is required';
    }

    if (text.length < 2) {
      return '$fieldName must contain at least 2 characters';
    }

    if (text.length > 50) {
      return '$fieldName is too long';
    }

    final RegExp nameRegex = RegExp(r"^[a-zA-Z]+(?:[ '-][a-zA-Z]+)*$");

    if (!nameRegex.hasMatch(text)) {
      return '$fieldName can contain letters, spaces, apostrophe or hyphen only';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (email.length > 254) {
      return 'Email is too long';
    }

    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9]'
      r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final String phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    final RegExp phoneRegex = RegExp(r'^03[0-9]{9}$');

    if (!phoneRegex.hasMatch(phone)) {
      return 'Enter a valid Pakistani phone number (03XXXXXXXXX)';
    }

    return null;
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must contain at least 2 characters';
    }

    return null;
  }

  // ============================================================
  // DUPLICATE CHECK
  // ============================================================

  Future<bool> _isDuplicateTeacher({
    required String email,
    required String phone,
  }) async {
    final CollectionReference<Map<String, dynamic>> teachers = FirebaseFirestore
        .instance
        .collection('users')
        .doc(adminId)
        .collection('teachers');

    final String normalizedEmail = email.trim().toLowerCase();

    final String normalizedPhone = phone.trim();

    // Check duplicate email
    final QuerySnapshot<Map<String, dynamic>> emailResult = await teachers
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (emailResult.docs.isNotEmpty) {
      return true;
    }

    // Check duplicate phone
    final QuerySnapshot<Map<String, dynamic>> phoneResult = await teachers
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (phoneResult.docs.isNotEmpty) {
      return true;
    }

    return false;
  }

  // ============================================================
  // ADD TEACHER
  // ============================================================

  Future<void> addTeacher() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = emailController.text.trim().toLowerCase();

    final String phone = phoneController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      final bool duplicate = await _isDuplicateTeacher(
        email: email,
        phone: phone,
      );

      if (duplicate) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A teacher with this email or phone number already exists.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      final String teacherId = 'T${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('teachers')
          .doc(teacherId)
          .set({
            'teacherId': teacherId,
            'name': nameController.text.trim(),
            'email': email,
            'phone': phone,
            'subject': subjectController.text.trim(),
            'qualification': qualificationController.text.trim(),
            'address': addressController.text.trim(),
            'role': 'teacher',
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher added successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Something went wrong. Please try again.';

      if (e.code == 'permission-denied') {
        message = 'You do not have permission to add a teacher.';
      } else if (e.code == 'unavailable') {
        message = 'Server is temporarily unavailable. Please try again.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add teacher. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 2),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    subjectController.dispose();
    qualificationController.dispose();
    addressController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Teacher'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.person_add,
                        size: 45,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 25),

                    inputField(
                      label: 'Teacher Name',
                      icon: Icons.person_outline,
                      controller: nameController,
                      validator: (value) =>
                          _nameValidator(value, 'Teacher name'),
                      textCapitalization: TextCapitalization.words,
                    ),

                    inputField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      controller: emailController,
                      validator: _emailValidator,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    inputField(
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      controller: phoneController,
                      validator: _phoneValidator,
                      keyboardType: TextInputType.phone,
                    ),

                    inputField(
                      label: 'Subject',
                      icon: Icons.book_outlined,
                      controller: subjectController,
                      validator: (value) =>
                          _requiredValidator(value, 'Subject'),
                      textCapitalization: TextCapitalization.words,
                    ),

                    inputField(
                      label: 'Qualification',
                      icon: Icons.workspace_premium_outlined,
                      controller: qualificationController,
                      validator: (value) =>
                          _requiredValidator(value, 'Qualification'),
                      textCapitalization: TextCapitalization.words,
                    ),

                    inputField(
                      label: 'Address',
                      icon: Icons.home_outlined,
                      controller: addressController,
                      validator: (value) =>
                          _requiredValidator(value, 'Address'),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : addTeacher,
                        icon: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          isLoading ? 'Adding...' : 'Add Teacher',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
}
