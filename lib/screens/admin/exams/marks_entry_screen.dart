import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MarksEntryScreen extends StatefulWidget {
  const MarksEntryScreen({super.key});

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController obtainedMarksController = TextEditingController();

  String? selectedStudent;
  String? selectedExam;

  bool isLoading = false;

  String? selectedStudentName;
  String? selectedExamName;
  int? selectedTotalMarks;

  CollectionReference<Map<String, dynamic>> get _studentsCollection {
    return FirebaseFirestore.instance.collection('students');
  }

  CollectionReference<Map<String, dynamic>> get _examsCollection {
    return FirebaseFirestore.instance.collection('exams');
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _calculateGrade(int marks, int totalMarks) {
    if (totalMarks <= 0) return 'N/A';

    final percentage = (marks / totalMarks) * 100;

    if (percentage >= 90) {
      return 'A+';
    } else if (percentage >= 80) {
      return 'A';
    } else if (percentage >= 70) {
      return 'B';
    } else if (percentage >= 60) {
      return 'C';
    } else if (percentage >= 50) {
      return 'D';
    } else {
      return 'F';
    }
  }

  String _calculateStatus(int marks, int totalMarks) {
    if (totalMarks <= 0) return 'Fail';

    final percentage = (marks / totalMarks) * 100;
    return percentage >= 50 ? 'Pass' : 'Fail';
  }

  Future<void> saveMarks() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedStudent == null || selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both student and exam.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final obtainedMarks = int.tryParse(obtainedMarksController.text.trim());

    if (obtainedMarks == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid obtained marks.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final totalMarks = selectedTotalMarks ?? 0;

    if (totalMarks <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected exam has invalid total marks.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (obtainedMarks > totalMarks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Obtained marks cannot be greater than $totalMarks.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final duplicateQuery = await FirebaseFirestore.instance
          .collection('marks')
          .where('studentId', isEqualTo: selectedStudent)
          .where('examId', isEqualTo: selectedExam)
          .limit(1)
          .get();

      if (duplicateQuery.docs.isNotEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks for this student and exam already exist.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      final grade = _calculateGrade(obtainedMarks, totalMarks);

      final status = _calculateStatus(obtainedMarks, totalMarks);

      final percentage = (obtainedMarks / totalMarks) * 100;

      await FirebaseFirestore.instance.collection('marks').add({
        'studentId': selectedStudent,
        'studentName': selectedStudentName ?? '',
        'examId': selectedExam,
        'examName': selectedExamName ?? '',
        'obtainedMarks': obtainedMarks,
        'totalMarks': totalMarks,
        'percentage': double.parse(percentage.toStringAsFixed(2)),
        'grade': grade,
        'status': status,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      obtainedMarksController.clear();

      setState(() {
        selectedStudent = null;
        selectedExam = null;
        selectedStudentName = null;
        selectedExamName = null;
        selectedTotalMarks = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks saved successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to save marks.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while saving marks.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _studentsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorBox('Unable to load students.');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildErrorBox(
            'No students found. Please add students first.',
          );
        }

        return DropdownButtonFormField<String>(
          value: selectedStudent,
          isExpanded: true,
          decoration: _inputDecoration(
            label: 'Select Student',
            hint: 'Choose a student',
            icon: Icons.person_outline,
          ),
          items: docs.map((doc) {
            final data = doc.data();

            final name = _stringValue(data['name']).trim();

            final studentId = _stringValue(data['studentId']).trim();

            final displayName = name.isEmpty ? 'Unnamed Student' : name;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                studentId.isEmpty ? displayName : '$displayName  •  $studentId',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: isLoading
              ? null
              : (value) {
                  if (value == null) return;

                  final selectedDoc = docs.firstWhere((doc) => doc.id == value);

                  final data = selectedDoc.data();

                  setState(() {
                    selectedStudent = value;
                    selectedStudentName = _stringValue(data['name']);
                  });
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a student';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildExamDropdown() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _examsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorBox('Unable to load exams.');
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildErrorBox('No exams found. Please add an exam first.');
        }

        return DropdownButtonFormField<String>(
          value: selectedExam,
          isExpanded: true,
          decoration: _inputDecoration(
            label: 'Select Exam',
            hint: 'Choose an exam',
            icon: Icons.assignment_outlined,
          ),
          items: docs.map((doc) {
            final data = doc.data();

            final examName = _stringValue(data['examName']).trim();

            final totalMarks = _intValue(data['totalMarks']);

            final displayName = examName.isEmpty ? 'Unnamed Exam' : examName;

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                '$displayName  •  Total: $totalMarks',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: isLoading
              ? null
              : (value) {
                  if (value == null) return;

                  final selectedDoc = docs.firstWhere((doc) => doc.id == value);

                  final data = selectedDoc.data();

                  setState(() {
                    selectedExam = value;
                    selectedExamName = _stringValue(data['examName']);
                    selectedTotalMarks = _intValue(data['totalMarks']);
                  });

                  obtainedMarksController.clear();
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select an exam';
            }
            return null;
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }

  Widget _buildMarksField() {
    return TextFormField(
      controller: obtainedMarksController,
      enabled: !isLoading,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: _inputDecoration(
        label: 'Obtained Marks',
        hint: selectedTotalMarks == null
            ? 'Enter obtained marks'
            : 'Maximum ${selectedTotalMarks!}',
        icon: Icons.grade_outlined,
      ).copyWith(counterText: ''),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Obtained marks are required';
        }

        final marks = int.tryParse(text);

        if (marks == null) {
          return 'Enter numbers only';
        }

        if (marks < 0) {
          return 'Marks cannot be negative';
        }

        if (selectedTotalMarks != null && marks > selectedTotalMarks!) {
          return 'Cannot exceed ${selectedTotalMarks!}';
        }

        return null;
      },
    );
  }

  Widget _buildExamSummary() {
    if (selectedExam == null || selectedTotalMarks == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${selectedExamName ?? 'Selected Exam'} • Total Marks: ${selectedTotalMarks!}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF166534),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    obtainedMarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Marks Entry',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      'Enter Student Marks',
                      'Select a student and exam, then enter the obtained marks.',
                      Icons.edit_note_outlined,
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Student',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildStudentDropdown(),

                    const SizedBox(height: 18),

                    const Text(
                      'Exam',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildExamDropdown(),

                    _buildExamSummary(),

                    const SizedBox(height: 20),

                    const Text(
                      'Obtained Marks',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildMarksField(),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : saveMarks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF93C5FD),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_outlined, size: 19),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Marks',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
