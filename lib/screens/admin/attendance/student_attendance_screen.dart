import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _classFilter = 'All';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  CollectionReference<Map<String, dynamic>> get _attendanceRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('attendance');
  }

  CollectionReference<Map<String, dynamic>> get _studentsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('students');
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance Records')),
        body: const Center(child: Text('Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF06264F),
        elevation: 0,
        title: const Text(
          'Attendance Records',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _attendanceRef.where('date', isEqualTo: _dateKey).snapshots(),
        builder: (context, attendanceSnapshot) {
          if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (attendanceSnapshot.hasError) {
            return _errorView(attendanceSnapshot.error.toString());
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _studentsRef.snapshots(),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (studentSnapshot.hasError) {
                return _errorView(studentSnapshot.error.toString());
              }

              final attendanceDocs = attendanceSnapshot.data?.docs ?? [];

              final students = studentSnapshot.data?.docs ?? [];

              return _buildContent(attendanceDocs, students);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> attendanceDocs,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final attendanceMap = <String, Map<String, dynamic>>{};

    for (final doc in attendanceDocs) {
      final data = doc.data();

      final studentId = (data['studentId'] ?? '').toString().trim();

      if (studentId.isNotEmpty) {
        attendanceMap[studentId] = data;
      }
    }

    final classes = <String>{};

    for (final student in students) {
      final data = student.data();

      final className = (data['class'] ?? '').toString().trim();

      if (className.isNotEmpty) {
        classes.add(className);
      }
    }

    final sortedClasses = classes.toList()..sort();

    final filteredStudents = students.where((doc) {
      final data = doc.data();

      final studentId = (data['studentId'] ?? doc.id).toString().trim();

      final name = (data['studentName'] ?? data['name'] ?? '').toString();

      final fatherName = (data['fatherName'] ?? '').toString();

      final studentClass = (data['class'] ?? '').toString();

      final section = (data['section'] ?? '').toString();

      final email = (data['email'] ?? '').toString();

      final attendance = attendanceMap[studentId];

      final status = (attendance?['status'] ?? 'Not Marked').toString();

      final search = _searchQuery.trim().toLowerCase();

      final matchesSearch =
          search.isEmpty ||
          name.toLowerCase().contains(search) ||
          fatherName.toLowerCase().contains(search) ||
          studentId.toLowerCase().contains(search) ||
          email.toLowerCase().contains(search) ||
          studentClass.toLowerCase().contains(search) ||
          section.toLowerCase().contains(search);

      final matchesStatus = _statusFilter == 'All' || status == _statusFilter;

      final matchesClass =
          _classFilter == 'All' || studentClass == _classFilter;

      return matchesSearch && matchesStatus && matchesClass;
    }).toList();

    var present = 0;
    var absent = 0;
    var notMarked = 0;

    for (final student in students) {
      final data = student.data();

      final studentId = (data['studentId'] ?? student.id).toString().trim();

      final attendance = attendanceMap[studentId];

      final status = (attendance?['status'] ?? 'Not Marked').toString();

      if (status == 'Present') {
        present++;
      } else if (status == 'Absent') {
        absent++;
      } else {
        notMarked++;
      }
    }

    final total = students.length;

    final percentage = total == 0 ? 0.0 : (present / total) * 100;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            _buildStats(
              total: total,
              present: present,
              absent: absent,
              notMarked: notMarked,
              percentage: percentage,
            ),

            const SizedBox(height: 20),

            _buildFilters(sortedClasses),

            const SizedBox(height: 20),

            _buildTable(filteredStudents, attendanceMap),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Records',
              style: TextStyle(
                color: Color(0xFF06264F),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'View biometric attendance records for students.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        );

        final date = OutlinedButton.icon(
          onPressed: _selectDate,
          icon: const Icon(Icons.calendar_month_rounded, size: 18),
          label: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF06264F),
            side: const BorderSide(color: Color(0xFFD7E0EA)),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), date],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [title, date],
        );
      },
    );
  }

  Widget _buildStats({
    required int total,
    required int present,
    required int absent,
    required int notMarked,
    required double percentage,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1100) {
          columns = 4;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Total Students',
                value: total.toString(),
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF1769E0),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Present',
                value: present.toString(),
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Absent',
                value: absent.toString(),
                icon: Icons.cancel_rounded,
                color: Colors.red,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Attendance %',
                value: '${percentage.toStringAsFixed(1)}%',
                subtitle: '$notMarked not marked',
                icon: Icons.analytics_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(List<String> classes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 750;

          final search = TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search student, ID, father name...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
              ),
            ),
          );

          final status = DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              labelText: 'Status',
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Status')),
              DropdownMenuItem(value: 'Present', child: Text('Present')),
              DropdownMenuItem(value: 'Absent', child: Text('Absent')),
              DropdownMenuItem(value: 'Not Marked', child: Text('Not Marked')),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _statusFilter = value;
              });
            },
          );

          final classDropdown = DropdownButtonFormField<String>(
            value: _classFilter,
            decoration: InputDecoration(
              labelText: 'Class',
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: [
              const DropdownMenuItem(value: 'All', child: Text('All Classes')),
              ...classes.map(
                (className) =>
                    DropdownMenuItem(value: className, child: Text(className)),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _classFilter = value;
              });
            },
          );

          if (compact) {
            return Column(
              children: [
                search,
                const SizedBox(height: 12),
                status,
                const SizedBox(height: 12),
                classDropdown,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: search),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: status),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: classDropdown),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
    Map<String, Map<String, dynamic>> attendanceMap,
  ) {
    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(45),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No attendance records found.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return _buildMobileList(students, attendanceMap);
        }

        return _buildDesktopTable(students, attendanceMap);
      },
    );
  }

  Widget _buildDesktopTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
    Map<String, Map<String, dynamic>> attendanceMap,
  ) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 54,
            dataRowMinHeight: 68,
            dataRowMaxHeight: 80,
            columnSpacing: 25,
            headingTextStyle: const TextStyle(
              color: Color(0xFF536273),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            columns: const [
              DataColumn(label: Text('STUDENT')),
              DataColumn(label: Text('STUDENT ID')),
              DataColumn(label: Text('CLASS')),
              DataColumn(label: Text('SECTION')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('METHOD')),
            ],
            rows: students.map((doc) {
              final data = doc.data();

              final studentId = (data['studentId'] ?? doc.id).toString();

              final attendance = attendanceMap[studentId];

              return DataRow(
                cells: [
                  DataCell(_studentIdentity(data)),
                  DataCell(
                    Text(
                      studentId,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(Text((data['class'] ?? '-').toString())),
                  DataCell(Text((data['section'] ?? '-').toString())),
                  DataCell(_statusBadge(attendance?['status']?.toString())),
                  DataCell(_methodBadge(attendance)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
    Map<String, Map<String, dynamic>> attendanceMap,
  ) {
    return Column(
      children: students.map((doc) {
        final data = doc.data();

        final studentId = (data['studentId'] ?? doc.id).toString();

        final attendance = attendanceMap[studentId];

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _studentAvatar(),
                  const SizedBox(width: 12),
                  Expanded(child: _studentIdentity(data)),
                  _statusBadge(attendance?['status']?.toString()),
                ],
              ),
              const SizedBox(height: 13),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.badge_outlined,
                label: 'Student ID',
                value: studentId,
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.school_outlined,
                label: 'Class',
                value: (data['class'] ?? '-').toString(),
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.grid_view_rounded,
                label: 'Section',
                value: (data['section'] ?? '-').toString(),
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.fingerprint_rounded,
                label: 'Method',
                value: attendance == null ? 'Not Marked' : 'Biometric',
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _studentIdentity(Map<String, dynamic> data) {
    final name = (data['studentName'] ?? data['name'] ?? 'Unnamed Student')
        .toString();

    final email = (data['email'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF06264F),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _studentAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_rounded, color: Color(0xFF1769E0)),
    );
  }

  Widget _statusBadge(String? status) {
    if (status == null || status.isEmpty) {
      status = 'Not Marked';
    }

    final isPresent = status == 'Present';
    final isAbsent = status == 'Absent';

    final color = isPresent
        ? Colors.green
        : isAbsent
        ? Colors.red
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _methodBadge(Map<String, dynamic>? attendance) {
    if (attendance == null) {
      return Text(
        'Not Marked',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      );
    }

    final biometric =
        attendance['biometric'] == true ||
        attendance['verificationMethod']?.toString().toLowerCase() ==
            'biometric';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          biometric ? Icons.fingerprint_rounded : Icons.help_outline_rounded,
          size: 18,
          color: biometric ? const Color(0xFF1769E0) : Colors.grey,
        ),
        const SizedBox(width: 5),
        Text(
          biometric ? 'Biometric' : 'Unknown',
          style: TextStyle(
            color: biometric ? const Color(0xFF1769E0) : Colors.grey.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load attendance.',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE1E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF06264F),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF1769E0)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF06264F),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
