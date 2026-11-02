import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_teacher_screen.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> teacherData;
  final String docId;

  const TeacherDetailsScreen({
    super.key,
    required this.teacherData,
    required this.docId,
  });

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  bool _deleting = false;

  String _value(String key, [String fallback = 'Not provided']) {
    final value = widget.teacherData[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  String get _teacherName {
    return _value('name', _value('teacherName', 'Teacher'));
  }

  String get _teacherId {
    return _value('teacherId', widget.docId);
  }

  String? get _adminUid {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _editTeacher() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTeacherScreen(
          teacherData: widget.teacherData,
          docId: widget.docId,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteTeacher() async {
    final adminUid = _adminUid;

    if (adminUid == null) {
      _showMessage('Please login again.', isError: true);
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Teacher'),
          content: Text(
            'Are you sure you want to delete $_teacherName?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _deleting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .collection('teachers')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher deleted successfully.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      _showMessage(e.message ?? 'Failed to delete teacher.', isError: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deleting = false;
      });

      _showMessage('Something went wrong. Please try again.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF1769E0),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF6B7A90)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8798),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF172B4D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 58 : 70,
            height: compact ? 58 : 70,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, size: 34, color: Color(0xFF1769E0)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teacherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 19 : 23,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Teacher ID: $_teacherId',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _deleting ? null : _editTeacher,
            icon: const Icon(Icons.edit_outlined, size: 19),
            label: const Text('Edit Teacher'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1769E0),
              side: const BorderSide(color: Color(0xFF1769E0)),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _deleting ? null : _deleteTeacher,
            icon: _deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline, size: 19),
            label: Text(_deleting ? 'Deleting...' : 'Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 650;

    final email = _value('email');
    final phone = _value('phone');
    final subject = _value('subject');
    final qualification = _value('qualification');
    final address = _value('address');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Teacher Details',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172B4D)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 14 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(compact),
                  const SizedBox(height: 18),
                  _buildActionButtons(),
                  const SizedBox(height: 20),

                  if (compact)
                    Column(
                      children: [
                        _buildInfoCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline,
                          children: [
                            _buildInfoRow(
                              label: 'Teacher Name',
                              value: _teacherName,
                              icon: Icons.badge_outlined,
                            ),
                            _buildInfoRow(
                              label: 'Qualification',
                              value: qualification,
                              icon: Icons.school_outlined,
                            ),
                            _buildInfoRow(
                              label: 'Subject',
                              value: subject,
                              icon: Icons.menu_book_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          title: 'Contact Information',
                          icon: Icons.contact_phone_outlined,
                          children: [
                            _buildInfoRow(
                              label: 'Email',
                              value: email,
                              icon: Icons.email_outlined,
                            ),
                            _buildInfoRow(
                              label: 'Phone',
                              value: phone,
                              icon: Icons.phone_outlined,
                            ),
                            _buildInfoRow(
                              label: 'Address',
                              value: address,
                              icon: Icons.location_on_outlined,
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: 'Personal Information',
                            icon: Icons.person_outline,
                            children: [
                              _buildInfoRow(
                                label: 'Teacher Name',
                                value: _teacherName,
                                icon: Icons.badge_outlined,
                              ),
                              _buildInfoRow(
                                label: 'Qualification',
                                value: qualification,
                                icon: Icons.school_outlined,
                              ),
                              _buildInfoRow(
                                label: 'Subject',
                                value: subject,
                                icon: Icons.menu_book_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _buildInfoCard(
                            title: 'Contact Information',
                            icon: Icons.contact_phone_outlined,
                            children: [
                              _buildInfoRow(
                                label: 'Email',
                                value: email,
                                icon: Icons.email_outlined,
                              ),
                              _buildInfoRow(
                                label: 'Phone',
                                value: phone,
                                icon: Icons.phone_outlined,
                              ),
                              _buildInfoRow(
                                label: 'Address',
                                value: address,
                                icon: Icons.location_on_outlined,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 18),

                  _buildInfoCard(
                    title: 'Record Information',
                    icon: Icons.info_outline,
                    children: [
                      _buildInfoRow(
                        label: 'Teacher Document ID',
                        value: widget.docId,
                        icon: Icons.fingerprint,
                      ),
                      _buildInfoRow(
                        label: 'Status',
                        value: 'Active',
                        icon: Icons.check_circle_outline,
                      ),
                    ],
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
