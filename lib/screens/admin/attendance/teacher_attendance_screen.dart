import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  bool _biometricInProgress = false;

  String? get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.isEmpty) {
      return null;
    }
    return user.uid;
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  String get _displayDate =>
      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);

  CollectionReference<Map<String, dynamic>> get _teachersRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('teachers');
  }

  CollectionReference<Map<String, dynamic>> get _attendanceRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('teacher_attendance');
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teacher Attendance')),
        body: const Center(
          child: Text(
            'Your session has expired.\nPlease login again.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF06264F),
        title: const Text(
          'Teacher Attendance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Attendance History',
            onPressed: _showAttendanceHistory,
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Monthly Report',
            onPressed: _showMonthlyReport,
            icon: const Icon(Icons.analytics_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _teachersRef.snapshots(),
        builder: (context, teacherSnapshot) {
          if (teacherSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (teacherSnapshot.hasError) {
            return _ErrorView(
              message: 'Unable to load teachers.\n${teacherSnapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          final teachers = teacherSnapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _attendanceRef
                .where('date', isEqualTo: _dateKey)
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (attendanceSnapshot.hasError) {
                return _ErrorView(
                  message:
                      'Unable to load today\'s attendance.\n${attendanceSnapshot.error}',
                  onRetry: () => setState(() {}),
                );
              }

              final attendanceDocs =
                  attendanceSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              return _buildContent(context, teachers, attendanceDocs);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> attendanceDocs,
  ) {
    final attendanceByTeacher = <String, Map<String, dynamic>>{};

    for (final doc in attendanceDocs) {
      final data = doc.data();

      final teacherId = (data['teacherId'] ?? '').toString().trim();

      if (teacherId.isNotEmpty) {
        attendanceByTeacher[teacherId] = data;
      }
    }

    final filteredTeachers = teachers.where((doc) {
      final data = doc.data();

      final name = _teacherName(data).toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final phone = (data['phone'] ?? '').toString().toLowerCase();
      final subject = (data['subject'] ?? '').toString().toLowerCase();
      final teacherId = (data['teacherId'] ?? doc.id).toString().toLowerCase();

      final query = _searchQuery.trim().toLowerCase();

      if (query.isEmpty) {
        return true;
      }

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          subject.contains(query) ||
          teacherId.contains(query);
    }).toList();

    final totalTeachers = teachers.length;

    var present = 0;
    var absent = 0;

    for (final teacherDoc in teachers) {
      final data = teacherDoc.data();

      final teacherId = (data['teacherId'] ?? teacherDoc.id).toString().trim();

      final attendance = attendanceByTeacher[teacherId];

      if (attendance == null) {
        continue;
      }

      final status = (attendance['status'] ?? '').toString();

      if (status == 'Present') {
        present++;
      } else if (status == 'Absent') {
        absent++;
      }
    }

    final marked = present + absent;

    final attendancePercentage = totalTeachers == 0
        ? 0.0
        : (present / totalTeachers) * 100;

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
            _buildHeader(context),
            const SizedBox(height: 20),

            _buildStats(
              context,
              totalTeachers: totalTeachers,
              present: present,
              absent: absent,
              marked: marked,
              percentage: attendancePercentage,
            ),

            const SizedBox(height: 20),

            _buildBiometricNotice(context),

            const SizedBox(height: 20),

            _buildControls(context),

            const SizedBox(height: 20),

            _buildTeacherTable(context, filteredTeachers, attendanceByTeacher),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Attendance',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF06264F),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Biometric verification is required to mark attendance.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        );

        final date = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 19,
                color: Color(0xFF1769E0),
              ),
              const SizedBox(width: 9),
              Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF06264F),
                ),
              ),
            ],
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

  Widget _buildStats(
    BuildContext context, {
    required int totalTeachers,
    required int present,
    required int absent,
    required int marked,
    required double percentage,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1100) {
          columns = 4;
        } else if (width >= 650) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth = columns == 1
            ? width
            : (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Total Teachers',
                value: totalTeachers.toString(),
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFF1769E0),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Today Present',
                value: present.toString(),
                icon: Icons.check_circle_rounded,
                iconColor: Colors.green,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Today Absent',
                value: absent.toString(),
                icon: Icons.cancel_rounded,
                iconColor: Colors.red,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                title: 'Attendance %',
                value: '${percentage.toStringAsFixed(1)}%',
                subtitle: '$marked marked',
                icon: Icons.bar_chart_rounded,
                iconColor: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBiometricNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06264F), Color(0xFF1769E0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Attendance Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Teacher must verify identity using fingerprint, Face ID, or the available device biometric before attendance is saved.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 750;

        final dateButton = OutlinedButton.icon(
          onPressed: _selectDate,
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text(_displayDate, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF06264F),
            side: const BorderSide(color: Color(0xFFD7E0EA)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        );

        final search = SizedBox(
          width: compact ? double.infinity : 300,
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search teacher...',
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFD7E0EA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(
                  color: Color(0xFF1769E0),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [dateButton, const SizedBox(height: 10), search],
          );
        }

        return Row(children: [dateButton, const Spacer(), search]);
      },
    );
  }

  Widget _buildTeacherTable(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers,
    Map<String, Map<String, dynamic>> attendanceByTeacher,
  ) {
    if (teachers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(45),
        decoration: _whiteCardDecoration(),
        child: Column(
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'No teachers found.'
                  : 'No teacher matches your search.',
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
          return _buildMobileTeacherList(teachers, attendanceByTeacher);
        }

        return _buildDesktopTeacherTable(teachers, attendanceByTeacher);
      },
    );
  }

  Widget _buildDesktopTeacherTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers,
    Map<String, Map<String, dynamic>> attendanceByTeacher,
  ) {
    return Container(
      width: double.infinity,
      decoration: _whiteCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 54,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 82,
            columnSpacing: 25,
            headingTextStyle: const TextStyle(
              color: Color(0xFF536273),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            columns: const [
              DataColumn(label: Text('TEACHER')),
              DataColumn(label: Text('TEACHER ID')),
              DataColumn(label: Text('SUBJECT')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('ACTION')),
            ],
            rows: teachers.map((doc) {
              final data = doc.data();

              final teacherId = (data['teacherId'] ?? doc.id).toString().trim();

              final attendance = attendanceByTeacher[teacherId];

              return DataRow(
                cells: [
                  DataCell(_teacherIdentity(data)),
                  DataCell(
                    Text(
                      teacherId.isEmpty ? '-' : teacherId,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text((data['subject'] ?? '-').toString())),
                  DataCell(_statusBadge(attendance?['status']?.toString())),
                  DataCell(_biometricButton(data, doc.id, attendance)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTeacherList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers,
    Map<String, Map<String, dynamic>> attendanceByTeacher,
  ) {
    return Column(
      children: teachers.map((doc) {
        final data = doc.data();

        final teacherId = (data['teacherId'] ?? doc.id).toString().trim();

        final attendance = attendanceByTeacher[teacherId];

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: _whiteCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _teacherAvatar(data),
                  const SizedBox(width: 12),
                  Expanded(child: _teacherIdentity(data)),
                  _statusBadge(attendance?['status']?.toString()),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.badge_outlined,
                label: 'Teacher ID',
                value: teacherId.isEmpty ? '-' : teacherId,
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.menu_book_outlined,
                label: 'Subject',
                value: (data['subject'] ?? '-').toString(),
              ),
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: _biometricButton(data, doc.id, attendance),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _teacherIdentity(Map<String, dynamic> data) {
    final name = _teacherName(data);
    final email = (data['email'] ?? '').toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Unnamed Teacher' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF06264F),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _teacherAvatar(Map<String, dynamic> data) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_rounded, color: Color(0xFF1769E0)),
    );
  }

  Widget _biometricButton(
    Map<String, dynamic> data,
    String docId,
    Map<String, dynamic>? attendance,
  ) {
    final status = attendance?['status']?.toString();

    final alreadyPresent = status == 'Present';
    final alreadyAbsent = status == 'Absent';

    if (alreadyPresent || alreadyAbsent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: alreadyPresent
              ? Colors.green.withOpacity(0.08)
              : Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: alreadyPresent
                ? Colors.green.withOpacity(0.20)
                : Colors.red.withOpacity(0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              alreadyPresent ? Icons.verified_rounded : Icons.cancel_rounded,
              size: 17,
              color: alreadyPresent ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 7),
            Text(
              alreadyPresent ? 'Verified' : 'Absent',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: alreadyPresent ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _biometricInProgress
          ? null
          : () => _markAttendanceBiometric(data, docId),
      icon: const Icon(Icons.fingerprint_rounded, size: 19),
      label: const Text('Verify Biometric'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1769E0),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  Widget _statusBadge(String? status) {
    if (status == null || status.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Not Marked',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    }

    final isPresent = status == 'Present';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPresent
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Future<void> _markAttendanceBiometric(
    Map<String, dynamic> teacher,
    String docId,
  ) async {
    if (_biometricInProgress) return;

    final uid = _uid;

    if (uid == null) {
      _showMessage(
        'Your session has expired. Please login again.',
        isError: true,
      );
      return;
    }

    final teacherId = (teacher['teacherId'] ?? docId).toString().trim();

    final teacherName = _teacherName(teacher);

    if (teacherId.isEmpty) {
      _showMessage('Teacher ID is missing.', isError: true);
      return;
    }

    if (teacherName.isEmpty) {
      _showMessage('Teacher name is missing.', isError: true);
      return;
    }

    setState(() {
      _biometricInProgress = true;
    });

    try {
      final biometricAvailable = await _checkBiometricAvailability();

      if (!biometricAvailable) {
        return;
      }

      final authenticated = await _authenticateBiometric();

      if (!authenticated) {
        _showMessage(
          'Biometric verification was not completed. Attendance was not saved.',
          isError: true,
        );
        return;
      }

      final existing = await _attendanceRef
          .where('teacherId', isEqualTo: teacherId)
          .where('date', isEqualTo: _dateKey)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _showMessage(
          'Attendance for this teacher is already marked for $_dateKey.',
          isError: true,
        );
        return;
      }

      final attendanceId = 'TA_${teacherId}_${_dateKey.replaceAll('-', '')}';

      await _attendanceRef.doc(attendanceId).set({
        'attendanceId': attendanceId,
        'teacherId': teacherId,
        'teacherDocId': docId,
        'teacherName': teacherName,
        'name': teacherName,
        'email': (teacher['email'] ?? '').toString().trim(),
        'phone': (teacher['phone'] ?? '').toString().trim(),
        'subject': (teacher['subject'] ?? '').toString().trim(),
        'qualification': (teacher['qualification'] ?? '').toString().trim(),
        'status': 'Present',
        'biometric': true,
        'verificationMethod': 'biometric',
        'date': _dateKey,
        'markedBy': uid,
        'markedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage(
        '$teacherName biometric verified successfully.\nAttendance marked Present.',
      );
    } on FirebaseException catch (e) {
      _showMessage(
        'Firebase error: ${e.message ?? 'Unable to save attendance.'}',
        isError: true,
      );
    } catch (e) {
      _showMessage('Unable to mark attendance: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _biometricInProgress = false;
        });
      }
    }
  }

  Future<bool> _checkBiometricAvailability() async {
    if (kIsWeb) {
      _showMessage(
        'Browser biometric attendance requires WebAuthn/passkey integration. '
        'The mobile/desktop biometric module uses device biometrics.',
        isError: true,
      );
      return false;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();

      if (!canCheck && !supported) {
        _showMessage(
          'This device does not support biometric authentication.',
          isError: true,
        );
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (!canCheck && availableBiometrics.isEmpty) {
        _showMessage(
          'No biometric method is configured on this device.',
          isError: true,
        );
        return false;
      }

      return true;
    } catch (e) {
      _showMessage(
        'Unable to access biometric authentication: $e',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> _authenticateBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verify your identity to mark teacher attendance.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      _showMessage(
        'Biometric authentication failed or was cancelled.',
        isError: true,
      );
      return false;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select attendance date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1769E0)),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _showAttendanceHistory() async {
    final uid = _uid;

    if (uid == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.history_rounded, color: Color(0xFF1769E0)),
              SizedBox(width: 9),
              Text('Attendance History'),
            ],
          ),
          content: SizedBox(
            width: 650,
            height: 500,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _attendanceRef
                  .orderBy('date', descending: true)
                  .limit(100)
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
                    child: Text('No attendance history found.'),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();

                    final name = (data['teacherName'] ?? data['name'] ?? '-')
                        .toString();

                    final date = (data['date'] ?? '-').toString();

                    final status = (data['status'] ?? '-').toString();

                    final biometric = data['biometric'] == true;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEAF2FF),
                        child: Icon(
                          biometric
                              ? Icons.fingerprint_rounded
                              : Icons.person_rounded,
                          color: const Color(0xFF1769E0),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '$date • ${biometric ? 'Biometric' : 'Unknown'}',
                      ),
                      trailing: _statusBadge(status),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMonthlyReport() async {
    final uid = _uid;

    if (uid == null) return;

    final monthStart = DateTime(_selectedDate.year, _selectedDate.month, 1);

    final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);

    final startKey = DateFormat('yyyy-MM-dd').format(monthStart);
    final endKey = DateFormat('yyyy-MM-dd').format(nextMonth);

    try {
      final attendanceSnapshot = await _attendanceRef
          .where('date', isGreaterThanOrEqualTo: startKey)
          .where('date', isLessThan: endKey)
          .get();

      final teachersSnapshot = await _teachersRef.get();

      final totalTeachers = teachersSnapshot.docs.length;

      final presentByTeacher = <String, int>{};
      final absentByTeacher = <String, int>{};

      for (final doc in attendanceSnapshot.docs) {
        final data = doc.data();

        final teacherId = (data['teacherId'] ?? '').toString();

        final status = (data['status'] ?? '').toString();

        if (teacherId.isEmpty) continue;

        if (status == 'Present') {
          presentByTeacher[teacherId] = (presentByTeacher[teacherId] ?? 0) + 1;
        } else if (status == 'Absent') {
          absentByTeacher[teacherId] = (absentByTeacher[teacherId] ?? 0) + 1;
        }
      }

      final totalPresent = presentByTeacher.values.fold<int>(
        0,
        (a, b) => a + b,
      );

      final totalAbsent = absentByTeacher.values.fold<int>(0, (a, b) => a + b);

      final totalMarked = totalPresent + totalAbsent;

      final percentage = totalMarked == 0
          ? 0.0
          : (totalPresent / totalMarked) * 100;

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(DateFormat('MMMM yyyy').format(_selectedDate)),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ReportRow(
                    title: 'Total Teachers',
                    value: totalTeachers.toString(),
                    icon: Icons.people_alt_rounded,
                  ),
                  _ReportRow(
                    title: 'Present Records',
                    value: totalPresent.toString(),
                    icon: Icons.check_circle_rounded,
                  ),
                  _ReportRow(
                    title: 'Absent Records',
                    value: totalAbsent.toString(),
                    icon: Icons.cancel_rounded,
                  ),
                  _ReportRow(
                    title: 'Total Marked',
                    value: totalMarked.toString(),
                    icon: Icons.fact_check_rounded,
                  ),
                  _ReportRow(
                    title: 'Attendance Rate',
                    value: '${percentage.toStringAsFixed(1)}%',
                    icon: Icons.analytics_rounded,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } on FirebaseException catch (e) {
      _showMessage(
        'Unable to generate report: ${e.message ?? 'Firebase error'}',
        isError: true,
      );
    } catch (e) {
      _showMessage('Unable to generate report: $e', isError: true);
    }
  }

  String _teacherName(Map<String, dynamic> data) {
    final name = (data['teacherName'] ?? data['name'] ?? '').toString().trim();

    return name;
  }

  BoxDecoration _whiteCardDecoration() {
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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
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
              color: iconColor.withOpacity(0.09),
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

class _ReportRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReportRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1769E0)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF06264F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
