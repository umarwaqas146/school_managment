import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditTeacherScreen extends StatefulWidget {
  final Map<String, dynamic> teacherData;
  final String docId;

  const EditTeacherScreen({
    super.key,
    required this.teacherData,
    required this.docId,
  });

  @override
  State<EditTeacherScreen> createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController subjectController;
  late TextEditingController qualificationController;
  late TextEditingController addressController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  String get adminId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.teacherData["name"]?.toString() ?? '',
    );

    emailController = TextEditingController(
      text: widget.teacherData["email"]?.toString() ?? '',
    );

    phoneController = TextEditingController(
      text: widget.teacherData["phone"]?.toString() ?? '',
    );

    subjectController = TextEditingController(
      text: widget.teacherData["subject"]?.toString() ?? '',
    );

    qualificationController = TextEditingController(
      text: widget.teacherData["qualification"]?.toString() ?? '',
    );

    addressController = TextEditingController(
      text: widget.teacherData["address"]?.toString() ?? '',
    );
  }

  String? validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Teacher name is required';
    }

    if (name.length < 2) {
      return 'Name must contain at least 2 characters';
    }

    if (name.length > 60) {
      return 'Name must not exceed 60 characters';
    }

    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s.'-]+$");

    if (!nameRegex.hasMatch(name)) {
      return 'Name can contain letters, spaces, . , \' and - only';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    if (email.length > 100) {
      return 'Email must not exceed 100 characters';
    }

    return null;
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^03\d{9}$');

    if (!phoneRegex.hasMatch(phone)) {
      return 'Enter a valid Pakistani number (03XXXXXXXXX)';
    }

    return null;
  }

  String? validateRequired(
    String? value,
    String fieldName, {
    int minLength = 1,
    int maxLength = 100,
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$fieldName is required';
    }

    if (text.length < minLength) {
      return '$fieldName must contain at least $minLength characters';
    }

    if (text.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  Future<bool> _isDuplicateEmail(String email) async {
    if (adminId.isEmpty) {
      return false;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection('teachers')
        .where('email', isEqualTo: email)
        .limit(10)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id != widget.docId) {
        return true;
      }
    }

    return false;
  }

  Future<bool> _isDuplicatePhone(String phone) async {
    if (adminId.isEmpty) {
      return false;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection('teachers')
        .where('phone', isEqualTo: phone)
        .limit(10)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id != widget.docId) {
        return true;
      }
    }

    return false;
  }

  Future<void> updateTeacher() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (adminId.isEmpty) {
      _showError('Your account session has expired. Please login again.');
      return;
    }

    final email = emailController.text.trim().toLowerCase();
    final phone = phoneController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      final bool duplicateEmail = await _isDuplicateEmail(email);

      if (duplicateEmail) {
        if (mounted) {
          _showError('This email is already registered for another teacher.');
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final bool duplicatePhone = await _isDuplicatePhone(phone);

      if (duplicatePhone) {
        if (mounted) {
          _showError(
            'This phone number is already registered for another teacher.',
          );
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('teachers')
          .doc(widget.docId)
          .update({
            'name': nameController.text.trim(),
            'email': email,
            'phone': phone,
            'subject': subjectController.text.trim(),
            'qualification': qualificationController.text.trim(),
            'address': addressController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher Updated Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Unable to update teacher. Please try again.';

      if (e.code == 'permission-denied') {
        message = 'You do not have permission to update this teacher.';
      } else if (e.code == 'not-found') {
        message = 'Teacher record was not found.';
      } else if (e.code == 'unavailable') {
        message = 'Server is temporarily unavailable. Try again.';
      }

      _showError(message);
    } catch (e) {
      if (!mounted) return;

      _showError('Something went wrong while updating the teacher.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        readOnly: readOnly,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Edit Teacher',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 34,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Teacher',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Update teacher information carefully.',
                                style: TextStyle(
                                  color: Colors.grey,
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

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField(
                          label: 'Teacher Name',
                          icon: Icons.person_outline,
                          controller: nameController,
                          validator: validateName,
                          textCapitalization: TextCapitalization.words,
                        ),

                        _inputField(
                          label: 'Email',
                          icon: Icons.email_outlined,
                          controller: emailController,
                          validator: validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        _inputField(
                          label: 'Phone',
                          icon: Icons.phone_outlined,
                          controller: phoneController,
                          validator: validatePhone,
                          keyboardType: TextInputType.phone,
                        ),

                        _inputField(
                          label: 'Subject',
                          icon: Icons.book_outlined,
                          controller: subjectController,
                          validator: (value) => validateRequired(
                            value,
                            'Subject',
                            minLength: 2,
                            maxLength: 80,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),

                        _inputField(
                          label: 'Qualification',
                          icon: Icons.workspace_premium_outlined,
                          controller: qualificationController,
                          validator: (value) => validateRequired(
                            value,
                            'Qualification',
                            minLength: 2,
                            maxLength: 100,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),

                        _inputField(
                          label: 'Address',
                          icon: Icons.home_outlined,
                          controller: addressController,
                          validator: (value) => validateRequired(
                            value,
                            'Address',
                            minLength: 5,
                            maxLength: 250,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  onPressed: updateTeacher,
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text(
                                    'Update Teacher',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
