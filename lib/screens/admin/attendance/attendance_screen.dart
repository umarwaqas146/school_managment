import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'teacher_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();

  String selectedClass = 'All Classes';
  String selectedSection = 'All Sections';

  bool isSaving = false;

  final Map<String, String> _attendanceStatus = {};

  final Color navy = const Color(0xFF06264F);
  final Color blue = const Color(0xFF1769E0);
  final Color background = const Color(0xFFF5F8FC);
  final Color border = const Color(0xFFE4EAF2);

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String get adminUid => currentUser?.uid ?? '';

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool get isToday {
    final now = DateTime.now();

    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  CollectionReference<Map<String, dynamic>> get studentsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(adminUid)
        .collection('students');
  }

  CollectionReference<Map<String, dynamic>> get attendanceRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(adminUid)
        .collection('attendance');
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: navy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
      _attendanceStatus.clear();
    });
  }

  Future<void> _saveAttendance(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) async {
    if (students.isEmpty) {
      _showMessage(
        'No students available for the selected filters.',
        Colors.orange,
      );
      return;
    }

    if (isSaving) return;

    final user = currentUser;

    if (user == null) {
      _showMessage('Your session has expired. Please login again.', Colors.red);
      return;
    }

    final incompleteStudents = students.where((doc) {
      final id = doc.data()['studentId']?.toString().trim() ?? '';
      return id.isEmpty || !_attendanceStatus.containsKey(id);
    }).toList();

    if (incompleteStudents.isNotEmpty) {
      _showMessage(
        'Please mark Present or Absent for all visible students before saving.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final date = _dateKey(selectedDate);

      final existingSnapshot = await attendanceRef
          .where('date', isEqualTo: date)
          .get();

      final existingByStudentId =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

      for (final doc in existingSnapshot.docs) {
        final studentId = doc.data()['studentId']?.toString().trim() ?? '';

        if (studentId.isNotEmpty) {
          existingByStudentId[studentId] = doc;
        }
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final studentDoc in students) {
        final student = studentDoc.data();

        final studentId =
            student['studentId']?.toString().trim() ?? studentDoc.id;

        final studentName =
            student['name']?.toString().trim() ??
            student['studentName']?.toString().trim() ??
            'Unknown Student';

        final studentClass = student['class']?.toString().trim() ?? '';

        final section = student['section']?.toString().trim() ?? '';

        final status = _attendanceStatus[studentId];

        if (status == null) continue;

        final existingDoc = existingByStudentId[studentId];

        final data = {
          'attendanceId': existingDoc?.id ?? '',
          'studentId': studentId,
          'studentName': studentName,
          'name': studentName,
          'class': studentClass,
          'section': section,
          'status': status,
          'date': date,
          'markedBy': user.email ?? user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (existingDoc != null) {
          batch.update(existingDoc.reference, data);
        } else {
          final newRef = attendanceRef.doc();

          data['attendanceId'] = newRef.id;
          data['createdAt'] = FieldValue.serverTimestamp();

          batch.set(newRef, data);
        }
      }

      await batch.commit();

      if (!mounted) return;

      _showMessage(
        'Attendance saved successfully for ${_displayDate(selectedDate)}.',
        Colors.green,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Failed to save attendance.';

      switch (e.code) {
        case 'permission-denied':
          message =
              'Permission denied. You are not allowed to save attendance.';
          break;

        case 'unavailable':
          message =
              'Firebase server is temporarily unavailable. Please try again.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        case 'failed-precondition':
          message = 'Firestore configuration/index requirement is missing.';
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
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (_) {
        return _AttendanceHistoryDialog(
          attendanceRef: attendanceRef,
          selectedDate: selectedDate,
          dateKey: _dateKey(selectedDate),
          displayDate: _displayDate(selectedDate),
          blue: blue,
          navy: navy,
        );
      },
    );
  }

  void _showMonthlyReport() {
    showDialog(
      context: context,
      builder: (_) {
        return _MonthlyAttendanceDialog(
          attendanceRef: attendanceRef,
          studentsRef: studentsRef,
          selectedDate: selectedDate,
          blue: blue,
          navy: navy,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final classes = <String>{};
    final sections = <String>{};

    for (final doc in students) {
      final data = doc.data();

      final className = data['class']?.toString().trim() ?? '';
      final section = data['section']?.toString().trim() ?? '';

      if (className.isNotEmpty) {
        classes.add(className);
      }

      if (section.isNotEmpty) {
        sections.add(section);
      }
    }

    final classList = ['All Classes', ...classes.toList()..sort()];
    final sectionList = ['All Sections', ...sections.toList()..sort()];

    if (!classList.contains(selectedClass)) {
      selectedClass = 'All Classes';
    }

    if (!sectionList.contains(selectedSection)) {
      selectedSection = 'All Sections';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: compact
              ? Column(
                  children: [
                    _buildDateButton(),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Class',
                      value: selectedClass,
                      items: classList,
                      icon: Icons.class_outlined,
                      onChanged: (value) {
                        setState(() {
                          selectedClass = value ?? 'All Classes';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Section',
                      value: selectedSection,
                      items: sectionList,
                      icon: Icons.grid_view_rounded,
                      onChanged: (value) {
                        setState(() {
                          selectedSection = value ?? 'All Sections';
                        });
                      },
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildDateButton()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Class',
                        value: selectedClass,
                        items: classList,
                        icon: Icons.class_outlined,
                        onChanged: (value) {
                          setState(() {
                            selectedClass = value ?? 'All Classes';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Section',
                        value: selectedSection,
                        items: sectionList,
                        icon: Icons.grid_view_rounded,
                        onChanged: (value) {
                          setState(() {
                            selectedSection = value ?? 'All Sections';
                          });
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDateButton() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: blue, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Date',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _displayDate(selectedDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: blue, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: blue, width: 1.3),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildStudentTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
    Map<String, dynamic> attendanceByStudent,
  ) {
    final filtered = students.where((doc) {
      final data = doc.data();

      final className = data['class']?.toString().trim() ?? '';

      final section = data['section']?.toString().trim() ?? '';

      final classMatch =
          selectedClass == 'All Classes' || className == selectedClass;

      final sectionMatch =
          selectedSection == 'All Sections' || section == selectedSection;

      return classMatch && sectionMatch;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 46,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 12),
            Text(
              'No students found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing the class or section filter.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          if (isMobile) {
            return Column(
              children: filtered.map((doc) {
                return _buildMobileStudentRow(doc, attendanceByStudent);
              }).toList(),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 50,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 70,
              horizontalMargin: 18,
              columnSpacing: 28,
              headingTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4B5563),
              ),
              columns: const [
                DataColumn(label: Text('STUDENT')),
                DataColumn(label: Text('CLASS')),
                DataColumn(label: Text('SECTION')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTION')),
              ],
              rows: filtered.map((doc) {
                return _buildDesktopStudentRow(doc, attendanceByStudent);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildDesktopStudentRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> attendanceByStudent,
  ) {
    final data = doc.data();

    final studentId = data['studentId']?.toString().trim() ?? doc.id;

    final name =
        data['name']?.toString().trim() ??
        data['studentName']?.toString().trim() ??
        'Unknown Student';

    final className = data['class']?.toString().trim() ?? '-';

    final section = data['section']?.toString().trim() ?? '-';

    final existingStatus = attendanceByStudent[studentId]?.toString();

    final currentStatus = _attendanceStatus[studentId] ?? existingStatus ?? '';

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 19,
                  color: blue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172033),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(className, style: const TextStyle(fontSize: 12))),
        DataCell(Text(section, style: const TextStyle(fontSize: 12))),
        DataCell(_statusBadge(currentStatus)),
        DataCell(_buildStatusButtons(studentId, currentStatus)),
      ],
    );
  }

  Widget _buildMobileStudentRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> attendanceByStudent,
  ) {
    final data = doc.data();

    final studentId = data['studentId']?.toString().trim() ?? doc.id;

    final name =
        data['name']?.toString().trim() ??
        data['studentName']?.toString().trim() ??
        'Unknown Student';

    final className = data['class']?.toString().trim() ?? '-';

    final section = data['section']?.toString().trim() ?? '-';

    final existingStatus = attendanceByStudent[studentId]?.toString();

    final currentStatus = _attendanceStatus[studentId] ?? existingStatus ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.person_outline_rounded, color: blue),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$className • $section',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(currentStatus),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusButtons(studentId, currentStatus, expanded: true),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    if (status.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Not Marked',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    final isPresent = status == 'Present';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isPresent ? const Color(0xFFEAF8F0) : const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isPresent ? const Color(0xFF16834D) : const Color(0xFFD12F2F),
        ),
      ),
    );
  }

  Widget _buildStatusButtons(
    String studentId,
    String currentStatus, {
    bool expanded = false,
  }) {
    final presentSelected = currentStatus == 'Present';
    final absentSelected = currentStatus == 'Absent';

    final children = [
      Expanded(
        child: _statusButton(
          label: 'Present',
          icon: Icons.check_rounded,
          selected: presentSelected,
          color: const Color(0xFF16834D),
          onTap: () {
            setState(() {
              _attendanceStatus[studentId] = 'Present';
            });
          },
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _statusButton(
          label: 'Absent',
          icon: Icons.close_rounded,
          selected: absentSelected,
          color: const Color(0xFFD12F2F),
          onTap: () {
            setState(() {
              _attendanceStatus[studentId] = 'Absent';
            });
          },
        ),
      ),
    ];

    if (expanded) {
      return Row(children: children);
    }

    return SizedBox(width: 190, child: Row(children: children));
  }

  Widget _statusButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: isSaving ? null : onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? Colors.white : color,
          backgroundColor: selected ? color : Colors.transparent,
          side: BorderSide(color: selected ? color : color.withOpacity(.35)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }

  Widget _buildDashboardBody() {
    if (adminUid.isEmpty) {
      return const Center(
        child: Text(
          'Please login again.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    final selectedDateKey = _dateKey(selectedDate);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: studentsRef.snapshots(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (studentSnapshot.hasError) {
          return _errorView(
            'Unable to load students.',
            studentSnapshot.error.toString(),
          );
        }

        final students = studentSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: attendanceRef
              .where('date', isEqualTo: selectedDateKey)
              .snapshots(),
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (attendanceSnapshot.hasError) {
              return _errorView(
                'Unable to load attendance.',
                attendanceSnapshot.error.toString(),
              );
            }

            final attendanceDocs = attendanceSnapshot.data?.docs ?? [];

            final attendanceByStudent = <String, dynamic>{};

            for (final doc in attendanceDocs) {
              final data = doc.data();

              final studentId = data['studentId']?.toString().trim() ?? '';

              if (studentId.isEmpty) continue;

              attendanceByStudent[studentId] = data['status']?.toString() ?? '';
            }

            final filteredStudents = students.where((doc) {
              final data = doc.data();

              final className = data['class']?.toString().trim() ?? '';

              final section = data['section']?.toString().trim() ?? '';

              final classMatch =
                  selectedClass == 'All Classes' || className == selectedClass;

              final sectionMatch =
                  selectedSection == 'All Sections' ||
                  section == selectedSection;

              return classMatch && sectionMatch;
            }).toList();

            int present = 0;
            int absent = 0;

            for (final doc in filteredStudents) {
              final data = doc.data();

              final studentId = data['studentId']?.toString().trim() ?? doc.id;

              final status =
                  _attendanceStatus[studentId] ??
                  attendanceByStudent[studentId]?.toString() ??
                  '';

              if (status == 'Present') {
                present++;
              } else if (status == 'Absent') {
                absent++;
              }
            }

            final total = filteredStudents.length;

            final marked = present + absent;

            final percentage = marked == 0 ? 0.0 : (present / marked) * 100;

            return RefreshIndicator(
              color: blue,
              onRefresh: () async {
                setState(() {});
                await Future<void>.delayed(const Duration(milliseconds: 300));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        int columns = 1;

                        if (constraints.maxWidth >= 1100) {
                          columns = 4;
                        } else if (constraints.maxWidth >= 700) {
                          columns = 2;
                        }

                        return GridView.count(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: columns == 1 ? 2.6 : 1.7,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatCard(
                              title: 'Today\'s Present',
                              value: '$present',
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF16834D),
                              subtitle: isToday
                                  ? 'Present today'
                                  : 'Selected date',
                            ),
                            _buildStatCard(
                              title: 'Today\'s Absent',
                              value: '$absent',
                              icon: Icons.cancel_rounded,
                              iconColor: const Color(0xFFD12F2F),
                              subtitle: isToday
                                  ? 'Absent today'
                                  : 'Selected date',
                            ),
                            _buildStatCard(
                              title: 'Attendance %',
                              value: '${percentage.toStringAsFixed(1)}%',
                              icon: Icons.percent_rounded,
                              iconColor: blue,
                              subtitle: '$marked of $total marked',
                            ),
                            _buildStatCard(
                              title: 'Total Students',
                              value: '$total',
                              icon: Icons.groups_rounded,
                              iconColor: const Color(0xFF7C3AED),
                              subtitle: 'Current filter',
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    _buildFilters(students),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student Attendance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mark attendance for ${_displayDate(selectedDate)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _showHistory,
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: const Text('History'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: navy,
                            side: BorderSide(color: border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => _saveAttendance(filteredStudents),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            isSaving ? 'Saving...' : 'Save Attendance',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildStudentTable(filteredStudents, attendanceByStudent),

                    const SizedBox(height: 20),

                    _buildReportsSection(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;

        final titleSection = Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.fact_check_rounded, color: blue, size: 26),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Dashboard',
                    style: TextStyle(
                      color: navy,
                      fontSize: mobile ? 20 : 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage daily student attendance and reports.',
                    style: const TextStyle(
                      color: Color(0xFF697386),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final teacherButton = OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherAttendanceScreen(),
              ),
            );
          },
          icon: const Icon(Icons.person_outline_rounded, size: 18),
          label: const Text('Teacher Attendance'),
          style: OutlinedButton.styleFrom(
            foregroundColor: navy,
            side: BorderSide(color: border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (mobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleSection, const SizedBox(height: 12), teacherButton],
          );
        }

        return Row(
          children: [
            Expanded(child: titleSection),
            teacherButton,
          ],
        );
      },
    );
  }

  Widget _buildReportsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;

        final history = _reportButton(
          icon: Icons.history_rounded,
          title: 'Attendance History',
          subtitle: 'View daily attendance records and status.',
          onTap: _showHistory,
        );

        final monthly = _reportButton(
          icon: Icons.calendar_month_rounded,
          title: 'Monthly Attendance Report',
          subtitle: 'View monthly attendance percentage.',
          onTap: _showMonthlyReport,
        );

        if (mobile) {
          return Column(
            children: [history, const SizedBox(height: 12), monthly],
          );
        }

        return Row(
          children: [
            Expanded(child: history),
            const SizedBox(width: 12),
            Expanded(child: monthly),
          ],
        );
      },
    );
  }

  Widget _reportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String title, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: Text(
          'Attendance',
          style: TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildDashboardBody(),
    );
  }
}

// ============================================================
// ATTENDANCE HISTORY
// ============================================================

class _AttendanceHistoryDialog extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> attendanceRef;
  final DateTime selectedDate;
  final String dateKey;
  final String displayDate;
  final Color blue;
  final Color navy;

  const _AttendanceHistoryDialog({
    required this.attendanceRef,
    required this.selectedDate,
    required this.dateKey,
    required this.displayDate,
    required this.blue,
    required this.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 900,
        height: 650,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Attendance History • $displayDate',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: attendanceRef
                    .where('date', isEqualTo: dateKey)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load history.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 46,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No attendance records found.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }

                  docs.sort((a, b) {
                    final nameA = a.data()['studentName']?.toString() ?? '';

                    final nameB = b.data()['studentName']?.toString() ?? '';

                    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                  });

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();

                      final name =
                          data['studentName']?.toString() ??
                          data['name']?.toString() ??
                          'Unknown';

                      final studentId = data['studentId']?.toString() ?? '-';

                      final className = data['class']?.toString() ?? '-';

                      final section = data['section']?.toString() ?? '-';

                      final status = data['status']?.toString() ?? 'Unknown';

                      final present = status == 'Present';

                      return Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: const Color(0xFFEAF2FF),
                              child: Icon(
                                Icons.person_outline,
                                color: blue,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$studentId • $className • $section',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: present
                                    ? const Color(0xFFEAF8F0)
                                    : const Color(0xFFFFEEEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: present
                                      ? const Color(0xFF16834D)
                                      : const Color(0xFFD12F2F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MONTHLY REPORT
// ============================================================

class _MonthlyAttendanceDialog extends StatelessWidget {
  final CollectionReference<Map<String, dynamic>> attendanceRef;
  final CollectionReference<Map<String, dynamic>> studentsRef;
  final DateTime selectedDate;
  final Color blue;
  final Color navy;

  const _MonthlyAttendanceDialog({
    required this.attendanceRef,
    required this.studentsRef,
    required this.selectedDate,
    required this.blue,
    required this.navy,
  });

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);

    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    final start = _dateKey(firstDay);
    final end = _dateKey(lastDay);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: 950,
        height: 680,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_monthName(selectedDate)} ${selectedDate.year} Attendance Report',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: attendanceRef
                    .where('date', isGreaterThanOrEqualTo: start)
                    .where('date', isLessThanOrEqualTo: end)
                    .snapshots(),
                builder: (context, attendanceSnapshot) {
                  if (attendanceSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (attendanceSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Unable to load monthly report.\n${attendanceSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final attendanceDocs = attendanceSnapshot.data?.docs ?? [];

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: studentsRef.snapshots(),
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (studentSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Unable to load students.\n${studentSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final students = studentSnapshot.data?.docs ?? [];

                      final report = <String, Map<String, dynamic>>{};

                      for (final student in students) {
                        final data = student.data();

                        final id =
                            data['studentId']?.toString().trim() ?? student.id;

                        final name =
                            data['name']?.toString().trim() ??
                            data['studentName']?.toString().trim() ??
                            'Unknown Student';

                        report[id] = {
                          'studentId': id,
                          'name': name,
                          'class': data['class']?.toString() ?? '-',
                          'section': data['section']?.toString() ?? '-',
                          'present': 0,
                          'absent': 0,
                        };
                      }

                      for (final attendance in attendanceDocs) {
                        final data = attendance.data();

                        final id = data['studentId']?.toString().trim() ?? '';

                        if (!report.containsKey(id)) {
                          continue;
                        }

                        final status = data['status']?.toString() ?? '';

                        if (status == 'Present') {
                          report[id]!['present'] =
                              (report[id]!['present'] as int) + 1;
                        } else if (status == 'Absent') {
                          report[id]!['absent'] =
                              (report[id]!['absent'] as int) + 1;
                        }
                      }

                      final rows = report.values.toList();

                      rows.sort((a, b) {
                        return a['name'].toString().toLowerCase().compareTo(
                          b['name'].toString().toLowerCase(),
                        );
                      });

                      int totalPresent = 0;
                      int totalAbsent = 0;

                      for (final row in rows) {
                        totalPresent += row['present'] as int;
                        totalAbsent += row['absent'] as int;
                      }

                      final totalMarked = totalPresent + totalAbsent;

                      final percentage = totalMarked == 0
                          ? 0.0
                          : totalPresent / totalMarked * 100;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _reportStat(
                                    'Present',
                                    '$totalPresent',
                                    const Color(0xFF16834D),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _reportStat(
                                    'Absent',
                                    '$totalAbsent',
                                    const Color(0xFFD12F2F),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _reportStat(
                                    'Attendance',
                                    '${percentage.toStringAsFixed(1)}%',
                                    blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: rows.isEmpty
                                ? const Center(
                                    child: Text('No students found.'),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: rows.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final row = rows[index];

                                      final present = row['present'] as int;

                                      final absent = row['absent'] as int;

                                      final marked = present + absent;

                                      final studentPercentage = marked == 0
                                          ? 0.0
                                          : present / marked * 100;

                                      return Container(
                                        padding: const EdgeInsets.all(13),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 19,
                                              backgroundColor: const Color(
                                                0xFFEAF2FF,
                                              ),
                                              child: Icon(
                                                Icons.person_outline,
                                                color: blue,
                                                size: 19,
                                              ),
                                            ),
                                            const SizedBox(width: 11),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    row['name'].toString(),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    '${row['studentId']} • ${row['class']} • ${row['section']}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${studentPercentage.toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: blue,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'P: $present  A: $absent',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportStat(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
