import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_class_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final String docId;

  const ClassDetailsScreen({
    super.key,
    required this.classData,
    required this.docId,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  bool _isDeleting = false;

  String? get _adminId => FirebaseAuth.instance.currentUser?.uid;

  String _value(String key) {
    final value = widget.classData[key];

    if (value == null) {
      return 'N/A';
    }

    final text = value.toString().trim();

    return text.isEmpty ? 'N/A' : text;
  }

  Future<void> _deleteClass() async {
    if (_adminId == null) {
      _showSnackBar(
        'Account session not found. Please sign in again.',
        Colors.orange,
      );
      return;
    }

    final className = _value('className');
    final section = _value('section');

    final displayName = section == 'N/A' ? className : '$className - $section';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Class',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete "$displayName"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_adminId)
          .collection('classes')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;

      _showSnackBar('Class deleted successfully.', Colors.green);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Failed to delete class.';

      switch (e.code) {
        case 'permission-denied':
          message =
              'Permission denied. You do not have access to delete this class.';
          break;

        case 'not-found':
          message = 'This class no longer exists.';
          break;

        case 'unavailable':
          message = 'Server is temporarily unavailable. Please try again.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        default:
          if (e.message != null && e.message!.trim().isNotEmpty) {
            message = e.message!;
          }
      }

      _showSnackBar(message, Colors.red);
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Something went wrong. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final className = _value('className');
    final section = _value('section');

    final displayName = section == 'N/A' ? className : '$className - $section';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text(
          'Class Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Class',
            onPressed: _isDeleting
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditClassScreen(
                          classData: widget.classData,
                          docId: widget.docId,
                        ),
                      ),
                    );

                    if (mounted) {
                      setState(() {});
                    }
                  },
            icon: const Icon(Icons.edit_outlined, size: 21),
          ),
          IconButton(
            tooltip: 'Delete Class',
            onPressed: _isDeleting ? null : _deleteClass,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 21,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 850;

          return SingleChildScrollView(
            padding: EdgeInsets.all(desktop ? 28 : 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  children: [
                    _buildProfileHeader(displayName, section),
                    const SizedBox(height: 18),
                    _buildDetailsCard(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String displayName, String section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.class_outlined,
              color: Color(0xFF1565C0),
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  section == 'N/A' ? 'Class information' : 'Section $section',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Class Information',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Basic information about this class.',
            style: TextStyle(color: Color(0xFF7A8494), fontSize: 11.5),
          ),
          const SizedBox(height: 18),
          _buildInfoTile(
            icon: Icons.school_outlined,
            title: 'Class Name',
            value: _value('className'),
          ),
          _buildInfoTile(
            icon: Icons.groups_outlined,
            title: 'Section',
            value: _value('section'),
          ),
          _buildInfoTile(
            icon: Icons.person_outline_rounded,
            title: 'Teacher Name',
            value: _value('teacherName'),
          ),
          _buildInfoTile(
            icon: Icons.meeting_room_outlined,
            title: 'Room Number',
            value: _value('roomNumber'),
          ),
          _buildInfoTile(
            icon: Icons.people_outline_rounded,
            title: 'Total Students',
            value: _value('totalStudents'),
            last: true,
          ),
          if (_isDeleting) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(
              color: Color(0xFF1565C0),
              backgroundColor: Color(0xFFE2E8F0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEFF2F5))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
