import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_parent_screen.dart';

class ParentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> parentData;
  final String docId;

  const ParentDetailsScreen({
    super.key,
    required this.parentData,
    required this.docId,
  });

  @override
  State<ParentDetailsScreen> createState() => _ParentDetailsScreenState();
}

class _ParentDetailsScreenState extends State<ParentDetailsScreen> {
  bool _isDeleting = false;

  String _text(String key) {
    return (widget.parentData[key] ?? '').toString().trim();
  }

  String get _parentName {
    final parentName = _text('parentName');

    if (parentName.isNotEmpty) {
      return parentName;
    }

    return _text('name');
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _initials() {
    final name = _parentName;

    if (name.isEmpty) {
      return 'P';
    }

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return '-';
  }

  Future<void> _deleteParent() async {
    if (_uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login again.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Parent'),
          content: Text(
            'Are you sure you want to delete '
            '${_parentName.isEmpty ? 'this parent' : _parentName}?',
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

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('parents')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parent deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unable to delete parent.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _editParent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditParentScreen(
          parentData: widget.parentData,
          docId: widget.docId,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF1769E0)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0B1F3A),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF1769E0)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: children
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: child,
                        ),
                      )
                      .toList(),
                );
              }

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3.5,
                children: children,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final relation = _text('relation');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06264F), Color(0xFF1769E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final avatar = CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Text(
              _initials(),
              style: const TextStyle(
                color: Color(0xFF1769E0),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          );

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _parentName.isEmpty ? 'Unnamed Parent' : _parentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                relation.isEmpty ? 'Parent' : relation,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _isDeleting ? null : _editParent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 9),
              OutlinedButton.icon(
                onPressed: _isDeleting ? null : _deleteParent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(child: information),
                  ],
                ),
                const SizedBox(height: 18),
                actions,
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 15),
              Expanded(child: information),
              actions,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _text('email');
    final phone = _text('phone');
    final studentName = _text('studentName');
    final studentId = _text('studentId');
    final relation = _text('relation');
    final address = _text('address');
    final createdAt = _formatTimestamp(widget.parentData['createdAt']);
    final updatedAt = _formatTimestamp(widget.parentData['updatedAt']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Parent Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0B1F3A),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _sectionCard(
                    title: 'Parent Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _infoTile(
                        'Parent Name',
                        _parentName,
                        Icons.person_outline,
                      ),
                      _infoTile(
                        'Relation',
                        relation,
                        Icons.family_restroom_outlined,
                      ),
                      _infoTile('Email', email, Icons.email_outlined),
                      _infoTile('Phone', phone, Icons.phone_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Student Information',
                    icon: Icons.school_outlined,
                    children: [
                      _infoTile(
                        'Student Name',
                        studentName,
                        Icons.person_outline,
                      ),
                      _infoTile('Student ID', studentId, Icons.badge_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Contact Information',
                    icon: Icons.location_on_outlined,
                    children: [
                      _infoTile('Address', address, Icons.home_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Record Information',
                    icon: Icons.history_rounded,
                    children: [
                      _infoTile(
                        'Created At',
                        createdAt,
                        Icons.calendar_today_outlined,
                      ),
                      _infoTile('Updated At', updatedAt, Icons.update_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
