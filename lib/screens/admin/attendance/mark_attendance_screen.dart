import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  String status = 'Present';

  bool isSaving = false;
  String? savingStudentId;

  final List<String> attendanceStatuses = const ['Present', 'Absent', 'Leave'];

  String _today() {
    final now = DateTime.now();

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  Color statusColor() {
    switch (status) {
      case 'Present':
        return Colors.green;

      case 'Absent':
        return Colors.red;

      case 'Leave':
        return Colors.orange;

      default:
        return Colors.blue;
    }
  }

  Future<void> saveAttendance(Map<String, dynamic> student) async {
    if (isSaving) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage('Your session has expired. Please login again.', Colors.red);
      return;
    }

    final adminId = currentUser.uid;

    final studentId = student['studentId']?.toString().trim() ?? '';
    final studentName = student['name']?.toString().trim() ?? '';
    final studentClass = student['class']?.toString().trim() ?? '';
    final section = student['section']?.toString().trim() ?? '';

    if (studentId.isEmpty) {
      _showMessage(
        'This student does not have a valid Student ID.',
        Colors.red,
      );
      return;
    }

    if (studentName.isEmpty) {
      _showMessage('This student does not have a valid name.', Colors.red);
      return;
    }

    if (studentClass.isEmpty) {
      _showMessage('This student does not have a valid class.', Colors.red);
      return;
    }

    if (!attendanceStatuses.contains(status)) {
      _showMessage('Please select a valid attendance status.', Colors.red);
      return;
    }

    setState(() {
      isSaving = true;
      savingStudentId = studentId;
    });

    try {
      final today = _today();

      final attendanceCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('attendance');

      final alreadyMarked = await attendanceCollection
          .where('studentId', isEqualTo: studentId)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (alreadyMarked.docs.isNotEmpty) {
        if (!mounted) return;

        _showMessage(
          'Attendance for $studentName has already been marked today.',
          Colors.orange,
        );

        return;
      }

      final attendanceRef = attendanceCollection.doc();

      await attendanceRef.set({
        'attendanceId': attendanceRef.id,
        'studentId': studentId,
        'studentName': studentName,
        'class': studentClass,
        'section': section,
        'status': status,
        'date': today,
        'markedBy': currentUser.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Attendance saved successfully.', Colors.green);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Failed to save attendance.';

      switch (e.code) {
        case 'permission-denied':
          message =
              'Permission denied. You are not allowed to save attendance.';
          break;

        case 'unavailable':
          message = 'Server is temporarily unavailable. Please try again.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        case 'failed-precondition':
          message =
              'Firestore query requires an index. Please check Firebase configuration.';
          break;

        default:
          if (e.message != null && e.message!.trim().isNotEmpty) {
            message = e.message!.trim();
          }
      }

      _showMessage(message, Colors.red);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Something went wrong while saving attendance.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
          savingStudentId = null;
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return DropdownButtonFormField<String>(
      initialValue: status,
      decoration: InputDecoration(
        labelText: 'Attendance Status',
        prefixIcon: Icon(Icons.fact_check_outlined, color: statusColor()),
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
          borderSide: BorderSide(color: statusColor(), width: 1.5),
        ),
      ),
      items: attendanceStatuses.map((value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value == 'Present'
                      ? Colors.green
                      : value == 'Absent'
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Text(value),
            ],
          ),
        );
      }).toList(),
      onChanged: isSaving
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                status = value;
              });
            },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final studentId = student['studentId']?.toString().trim() ?? '';
    final name = student['name']?.toString().trim() ?? 'Unknown Student';
    final studentClass = student['class']?.toString().trim() ?? '';
    final section = student['section']?.toString().trim() ?? '';

    final isThisStudentSaving = isSaving && savingStudentId == studentId;

    final classSection = [
      studentClass,
      section,
    ].where((value) => value.isNotEmpty).join(' • ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classSection.isEmpty
                        ? 'Class information unavailable'
                        : classSection,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: isSaving || studentId.isEmpty
                    ? null
                    : () => saveAttendance(student),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor(),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: isThisStudentSaving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  isThisStudentSaving ? 'Saving' : 'Save',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text('Mark Attendance'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Please login again to mark attendance.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final adminId = currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mark Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _today(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusSelector(),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(adminId)
                  .collection('students')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 44,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load students.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final students = snapshot.data?.docs ?? [];

                if (students.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No Students Found',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add students before marking attendance.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(students[index].data());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
