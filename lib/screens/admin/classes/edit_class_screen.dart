import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditClassScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final String docId;

  const EditClassScreen({
    super.key,
    required this.classData,
    required this.docId,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController classNameController;
  late TextEditingController sectionController;
  late TextEditingController teacherController;
  late TextEditingController roomController;
  late TextEditingController studentsController;

  bool isLoading = false;

  String? get adminId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid.isEmpty) {
      return null;
    }

    return user.uid;
  }

  @override
  void initState() {
    super.initState();

    classNameController = TextEditingController(
      text: widget.classData['className']?.toString() ?? '',
    );

    sectionController = TextEditingController(
      text: widget.classData['section']?.toString() ?? '',
    );

    teacherController = TextEditingController(
      text: widget.classData['teacherName']?.toString() ?? '',
    );

    roomController = TextEditingController(
      text: widget.classData['roomNumber']?.toString() ?? '',
    );

    studentsController = TextEditingController(
      text: widget.classData['totalStudents']?.toString() ?? '',
    );
  }

  String? _validateClassName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Class Name is required';
    }

    if (text.length > 50) {
      return 'Class Name is too long';
    }

    final validClassName = RegExp(r'^[a-zA-Z0-9\s-]+$');

    if (!validClassName.hasMatch(text)) {
      return 'Class Name contains invalid characters';
    }

    return null;
  }

  String? _validateSection(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Section is required';
    }

    if (text.length > 30) {
      return 'Section is too long';
    }

    final validSection = RegExp(r'^[a-zA-Z0-9\s-]+$');

    if (!validSection.hasMatch(text)) {
      return 'Section contains invalid characters';
    }

    return null;
  }

  String? _validateTeacherName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Teacher Name is required';
    }

    if (text.length < 2) {
      return 'Teacher Name must be at least 2 characters';
    }

    if (text.length > 100) {
      return 'Teacher Name is too long';
    }

    final validName = RegExp(r"^[a-zA-Z\s.'-]+$");

    if (!validName.hasMatch(text)) {
      return 'Teacher Name can contain only letters and spaces';
    }

    return null;
  }

  String? _validateRoom(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Room Number is required';
    }

    if (text.length > 30) {
      return 'Room Number is too long';
    }

    final validRoom = RegExp(r'^[a-zA-Z0-9\s/-]+$');

    if (!validRoom.hasMatch(text)) {
      return 'Enter a valid room number';
    }

    return null;
  }

  String? _validateStudents(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Total Students is required';
    }

    final number = int.tryParse(text);

    if (number == null) {
      return 'Total Students must be a whole number';
    }

    if (number < 0) {
      return 'Total Students cannot be negative';
    }

    if (number > 10000) {
      return 'Enter a valid number of students';
    }

    return null;
  }

  Future<bool> _checkDuplicateClass(String currentAdminId) async {
    final className = classNameController.text.trim();
    final section = sectionController.text.trim();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentAdminId)
        .collection('classes')
        .where('className', isEqualTo: className)
        .where('section', isEqualTo: section)
        .limit(10)
        .get();

    return snapshot.docs.any((doc) => doc.id != widget.docId);
  }

  Future<void> updateClass() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentAdminId = adminId;

    if (currentAdminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final duplicate = await _checkDuplicateClass(currentAdminId);

      if (duplicate) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Another class with the same Class Name and Section already exists.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentAdminId)
          .collection('classes')
          .doc(widget.docId)
          .update({
            'className': classNameController.text.trim(),
            'section': sectionController.text.trim(),
            'teacherName': teacherController.text.trim(),
            'roomNumber': roomController.text.trim(),
            'totalStudents': studentsController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class Updated Successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Unable to update class. Please try again.';

      if (e.code == 'permission-denied') {
        message = 'You do not have permission to update this class.';
      } else if (e.code == 'not-found') {
        message = 'This class no longer exists.';
      } else if (e.code == 'unavailable') {
        message = 'Server is temporarily unavailable. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9DEE8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD9DEE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _inputDecoration(label, icon),
    );
  }

  @override
  void dispose() {
    classNameController.dispose();
    sectionController.dispose();
    teacherController.dispose();
    roomController.dispose();
    studentsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Edit Class',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.class_outlined,
                            color: Color(0xFF2563EB),
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Class',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF172033),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Update the class information with valid details.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          label: 'Class Name',
                          icon: Icons.school_outlined,
                          controller: classNameController,
                          validator: _validateClassName,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Section',
                          icon: Icons.groups_outlined,
                          controller: sectionController,
                          validator: _validateSection,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Teacher Name',
                          icon: Icons.person_outline,
                          controller: teacherController,
                          validator: _validateTeacherName,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Room Number',
                          icon: Icons.room_outlined,
                          controller: roomController,
                          validator: _validateRoom,
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          label: 'Total Students',
                          icon: Icons.people_outline,
                          controller: studentsController,
                          validator: _validateStudents,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : updateClass,
                            icon: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              isLoading ? 'Updating...' : 'Update Class',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF93C5FD),
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
