import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_student_screen.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String docId;

  const StudentDetailsScreen({
    super.key,
    required this.studentData,
    required this.docId,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  bool _deleting = false;

  String _text(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _name() {
    final studentName = _text(widget.studentData['studentName']);

    if (studentName.isNotEmpty) {
      return studentName;
    }

    return _text(widget.studentData['name']);
  }

  String _fatherName() {
    return _text(widget.studentData['fatherName']);
  }

  String _email() {
    return _text(widget.studentData['email']);
  }

  String _phone() {
    return _text(widget.studentData['phone']);
  }

  String _studentId() {
    return _text(widget.studentData['studentId']);
  }

  String _className() {
    return _text(widget.studentData['class']);
  }

  String _section() {
    return _text(widget.studentData['section']);
  }

  String _cnic() {
    final cnic = _text(widget.studentData['cnic']);

    if (cnic.isNotEmpty) {
      return cnic;
    }

    final bForm = _text(widget.studentData['bForm']);

    if (bForm.isNotEmpty) {
      return bForm;
    }

    return _text(widget.studentData['cnicBForm']);
  }

  String _address() {
    return _text(widget.studentData['address']);
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _createdAt() {
    return _formatDate(widget.studentData['createdAt']);
  }

  String _updatedAt() {
    return _formatDate(widget.studentData['updatedAt']);
  }

  String _initials() {
    final name = _name();

    if (name.isEmpty) {
      return '?';
    }

    return name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  Future<void> _editStudent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStudentScreen(
          studentData: widget.studentData,
          docId: widget.docId,
        ),
      ),
    );
  }

  Future<void> _deleteStudent() async {
    final name = _name();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: Text(
            name.isEmpty
                ? 'Are you sure you want to delete this student?'
                : 'Are you sure you want to delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('students')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully.')),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unable to delete student.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while deleting student.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF102A43)),
        title: const Text(
          'Student Details',
          style: TextStyle(
            color: Color(0xFF102A43),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Student',
            onPressed: _deleting ? null : _editStudent,
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1769E0)),
          ),
          IconButton(
            tooltip: 'Delete Student',
            onPressed: _deleting ? null : _deleteStudent,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 30,
              24,
              isMobile ? 16 : 30,
              40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(isMobile),
                    const SizedBox(height: 20),
                    _buildInformationSection(
                      title: 'Personal Information',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _infoItem(
                          'Student Name',
                          _name(),
                          Icons.person_outline_rounded,
                        ),
                        _infoItem(
                          'Father Name',
                          _fatherName(),
                          Icons.family_restroom_outlined,
                        ),
                        _infoItem(
                          'B-Form / CNIC',
                          _cnic(),
                          Icons.badge_outlined,
                        ),
                        _infoItem(
                          'Student ID',
                          _studentId(),
                          Icons.fingerprint_rounded,
                        ),
                      ],
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),
                    _buildInformationSection(
                      title: 'Academic Information',
                      icon: Icons.school_outlined,
                      children: [
                        _infoItem('Class', _className(), Icons.class_outlined),
                        _infoItem(
                          'Section',
                          _section(),
                          Icons.grid_view_rounded,
                        ),
                      ],
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),
                    _buildInformationSection(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_outlined,
                      children: [
                        _infoItem('Email', _email(), Icons.email_outlined),
                        _infoItem('Phone', _phone(), Icons.phone_outlined),
                        _infoItem(
                          'Address',
                          _address(),
                          Icons.location_on_outlined,
                        ),
                      ],
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),
                    _buildInformationSection(
                      title: 'Record Information',
                      icon: Icons.history_rounded,
                      children: [
                        _infoItem(
                          'Created At',
                          _createdAt(),
                          Icons.calendar_today_outlined,
                        ),
                        _infoItem(
                          'Last Updated',
                          _updatedAt(),
                          Icons.update_rounded,
                        ),
                      ],
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 24),
                    _buildBottomActions(isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8EF)),
      ),
      child: isMobile
          ? Column(
              children: [
                _profileAvatar(),
                const SizedBox(height: 14),
                _profileText(centered: true),
              ],
            )
          : Row(
              children: [
                _profileAvatar(),
                const SizedBox(width: 18),
                Expanded(child: _profileText()),
                _statusBadge(),
              ],
            ),
    );
  }

  Widget _profileAvatar() {
    return CircleAvatar(
      radius: 38,
      backgroundColor: const Color(0xFFEAF2FF),
      child: Text(
        _initials(),
        style: const TextStyle(
          color: Color(0xFF1769E0),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _profileText({bool centered = false}) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          _name().isEmpty ? 'Unnamed Student' : _name(),
          textAlign: centered ? TextAlign.center : null,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _studentId().isEmpty
              ? 'Student ID not available'
              : 'Student ID: ${_studentId()}',
          textAlign: centered ? TextAlign.center : null,
          style: const TextStyle(
            color: Color(0xFF627D98),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (centered) _statusBadge(),
      ],
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: Color(0xFF2E7D32),
          ),
          SizedBox(width: 6),
          Text(
            'Active',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1769E0), size: 20),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isMobile)
            Column(
              children: children
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: child,
                    ),
                  )
                  .toList(),
            )
          else
            Wrap(
              spacing: 20,
              runSpacing: 18,
              children: children.map((child) {
                return SizedBox(width: 320, child: child);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    final displayValue = value.isEmpty ? '-' : value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF829AB1)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF829AB1),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF243B53),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _deleting ? null : _editStudent,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Student'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _deleting ? null : _deleteStudent,
            icon: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(_deleting ? 'Deleting...' : 'Delete Student'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _deleting ? null : _editStudent,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Student'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _deleting ? null : _deleteStudent,
          icon: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.delete_outline_rounded),
          label: Text(_deleting ? 'Deleting...' : 'Delete Student'),
        ),
      ],
    );
  }
}
