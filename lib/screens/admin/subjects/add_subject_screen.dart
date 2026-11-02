import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final subjectNameController = TextEditingController();
  final classNameController = TextEditingController();
  final teacherNameController = TextEditingController();
  final subjectCodeController = TextEditingController();
  final descriptionController = TextEditingController();

  bool isLoading = false;

  String get adminId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? validateSubjectName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Subject name is required';
    }

    if (text.length < 2) {
      return 'Subject name must be at least 2 characters';
    }

    if (text.length > 100) {
      return 'Subject name must not exceed 100 characters';
    }

    if (!RegExp(r"^[a-zA-Z0-9\s&().,'/-]+$").hasMatch(text)) {
      return 'Only letters, numbers and basic symbols are allowed';
    }

    return null;
  }

  String? validateClassName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Class name is required';
    }

    if (text.length > 50) {
      return 'Class name must not exceed 50 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9\s-]+$').hasMatch(text)) {
      return 'Invalid class format';
    }

    return null;
  }

  String? validateTeacherName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Teacher name is required';
    }

    if (text.length < 2) {
      return 'Teacher name must be at least 2 characters';
    }

    if (text.length > 100) {
      return 'Teacher name must not exceed 100 characters';
    }

    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(text)) {
      return 'Teacher name can contain letters and spaces only';
    }

    return null;
  }

  String? validateSubjectCode(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Subject code is required';
    }

    if (text.length < 2) {
      return 'Subject code must be at least 2 characters';
    }

    if (text.length > 20) {
      return 'Subject code must not exceed 20 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(text)) {
      return 'Use letters, numbers and hyphen only';
    }

    return null;
  }

  String? validateDescription(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Description is required';
    }

    if (text.length < 5) {
      return 'Description must be at least 5 characters';
    }

    if (text.length > 500) {
      return 'Description must not exceed 500 characters';
    }

    return null;
  }

  // ============================================================
  // DUPLICATE CHECK
  // ============================================================

  Future<bool> isDuplicateSubject() async {
    if (adminId.isEmpty) {
      return false;
    }

    final subjectName = subjectNameController.text.trim().toLowerCase();

    final className = classNameController.text.trim().toLowerCase();

    final subjectCode = subjectCodeController.text.trim().toLowerCase();

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection('subjects');

    final nameSnapshot = await collection
        .where('subjectNameLower', isEqualTo: subjectName)
        .where('classNameLower', isEqualTo: className)
        .limit(1)
        .get();

    if (nameSnapshot.docs.isNotEmpty) {
      return true;
    }

    final codeSnapshot = await collection
        .where('subjectCodeLower', isEqualTo: subjectCode)
        .limit(1)
        .get();

    return codeSnapshot.docs.isNotEmpty;
  }

  // ============================================================
  // SAVE SUBJECT
  // ============================================================

  Future<void> saveSubject() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (adminId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final duplicate = await isDuplicateSubject();

      if (duplicate) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A subject with the same name/class or subject code already exists.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final subjectRef = FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('subjects')
          .doc();

      final subjectId = subjectRef.id;

      final subjectName = subjectNameController.text.trim();

      final className = classNameController.text.trim();

      final teacherName = teacherNameController.text.trim();

      final subjectCode = subjectCodeController.text.trim().toUpperCase();

      final description = descriptionController.text.trim();

      await subjectRef.set({
        'subjectId': subjectId,
        'subjectName': subjectName,
        'subjectNameLower': subjectName.toLowerCase(),
        'className': className,
        'classNameLower': className.toLowerCase(),
        'teacherName': teacherName,
        'subjectCode': subjectCode,
        'subjectCodeLower': subjectCode.toLowerCase(),
        'description': description,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Failed to add subject';

      if (e.code == 'permission-denied') {
        message = 'You do not have permission to add a subject.';
      } else if (e.code == 'unavailable') {
        message = 'Server is temporarily unavailable. Please try again.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add subject: $e'),
          backgroundColor: Colors.red,
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
  // CLEAR FORM
  // ============================================================

  void _clearForm() {
    subjectNameController.clear();
    classNameController.clear();
    teacherNameController.clear();
    subjectCodeController.clear();
    descriptionController.clear();

    _formKey.currentState?.reset();
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool textCapitalizationWords = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
        textCapitalization: textCapitalizationWords
            ? TextCapitalization.words
            : TextCapitalization.none,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter $label',
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
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
    subjectNameController.dispose();
    classNameController.dispose();
    teacherNameController.dispose();
    subjectCodeController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),

            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.grey.shade200),
              ),

              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Subject Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Enter valid information to create a new subject.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      buildField(
                        controller: subjectNameController,
                        label: 'Subject Name',
                        icon: Icons.menu_book_outlined,
                        validator: validateSubjectName,
                        textCapitalizationWords: true,
                      ),

                      buildField(
                        controller: classNameController,
                        label: 'Class',
                        icon: Icons.class_outlined,
                        validator: validateClassName,
                        textCapitalizationWords: true,
                      ),

                      buildField(
                        controller: teacherNameController,
                        label: 'Teacher Name',
                        icon: Icons.person_outline,
                        validator: validateTeacherName,
                        textCapitalizationWords: true,
                      ),

                      buildField(
                        controller: subjectCodeController,
                        label: 'Subject Code',
                        icon: Icons.code_rounded,
                        validator: validateSubjectCode,
                      ),

                      buildField(
                        controller: descriptionController,
                        label: 'Description',
                        icon: Icons.description_outlined,
                        validator: validateDescription,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: ElevatedButton(
                          onPressed: isLoading ? null : saveSubject,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.blue.shade200,
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
                              : const Text(
                                  'Save Subject',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
