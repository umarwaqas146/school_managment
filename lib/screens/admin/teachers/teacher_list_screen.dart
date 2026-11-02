import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_teacher_screen.dart';
import 'edit_teacher_screen.dart';
import 'teacher_details_screen.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final Color _navy = const Color(0xFF06264F);
  final Color _blue = const Color(0xFF1769E0);
  final Color _background = const Color(0xFFF5F8FC);

  String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value == null ? '' : value.toString();
  }

  bool _matchesSearch(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (_searchQuery.trim().isEmpty) {
      return true;
    }

    final searchableText = [
      _text(data, 'name'),
      _text(data, 'teacherName'),
      _text(data, 'email'),
      _text(data, 'phone'),
      _text(data, 'subject'),
      _text(data, 'qualification'),
      _text(data, 'address'),
      _text(data, 'teacherId'),
    ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery.toLowerCase());
  }

  String _teacherName(Map<String, dynamic> data) {
    final name = _text(data, 'teacherName');
    if (name.isNotEmpty) return name;

    return _text(data, 'name');
  }

  Future<void> _deleteTeacher(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final teacherName = _teacherName(doc.data());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Teacher',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete "$teacherName"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final adminId = FirebaseAuth.instance.currentUser?.uid;

    if (adminId == null) {
      _showMessage('Admin session not found.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .collection('teachers')
          .doc(doc.id)
          .delete();

      if (mounted) {
        _showMessage('Teacher deleted successfully.');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(e.message ?? 'Failed to delete teacher.', isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Something went wrong while deleting the teacher.',
          isError: true,
        );
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : _navy,
      ),
    );
  }

  void _openAddTeacher() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTeacherScreen()),
    );
  }

  void _openEditTeacher(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditTeacherScreen(teacherData: doc.data(), docId: doc.id),
      ),
    );
  }

  void _openDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TeacherDetailsScreen(teacherData: doc.data(), docId: doc.id),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search teachers...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _blue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 28,
            vertical: 20,
          ),
          color: Colors.white,
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildTitle()),
                    _buildSearchBar(),
                    const SizedBox(width: 14),
                    _buildAddButton(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.school_rounded, color: _blue, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teachers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Manage school teachers and faculty',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return FilledButton.icon(
      onPressed: _openAddTeacher,
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Add Teacher',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildMobileAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(width: double.infinity, child: _buildAddButton()),
    );
  }

  Widget _buildTeacherCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final name = _teacherName(data);
    final email = _text(data, 'email');
    final phone = _text(data, 'phone');
    final subject = _text(data, 'subject');
    final qualification = _text(data, 'qualification');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5EAF1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildAvatar(name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Unnamed Teacher' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (subject.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subject,
                          style: TextStyle(
                            fontSize: 13,
                            color: _blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view') {
                      _openDetails(doc);
                    } else if (value == 'edit') {
                      _openEditTeacher(doc);
                    } else if (value == 'delete') {
                      _deleteTeacher(doc);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.visibility_outlined),
                        title: Text('View Details'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _infoRow(Icons.email_outlined, 'Email', email),
            _infoRow(Icons.phone_outlined, 'Phone', phone),
            _infoRow(
              Icons.workspace_premium_outlined,
              'Qualification',
              qualification,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final letter = name.trim().isEmpty
        ? 'T'
        : name.trim().substring(0, 1).toUpperCase();

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 9),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 52,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 82,
            horizontalMargin: 20,
            columnSpacing: 28,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFD)),
            columns: const [
              DataColumn(
                label: Text(
                  'Teacher',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Subject',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Qualification',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
            rows: teachers.map((doc) {
              final data = doc.data();

              final name = _teacherName(data);
              final email = _text(data, 'email');
              final phone = _text(data, 'phone');
              final subject = _text(data, 'subject');
              final qualification = _text(data, 'qualification');

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAvatar(name),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 170,
                          child: Text(
                            name.isEmpty ? 'Unnamed Teacher' : name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty)
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                              ),
                            ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      subject.isEmpty ? '-' : subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      qualification.isEmpty ? '-' : qualification,
                      style: const TextStyle(color: Color(0xFF475569)),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'View Details',
                          onPressed: () => _openDetails(doc),
                          icon: const Icon(Icons.visibility_outlined, size: 20),
                          color: _blue,
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openEditTeacher(doc),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: const Color(0xFF475569),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _deleteTeacher(doc),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.school_outlined,
              size: 34,
              color: _blue,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasSearch ? 'No teachers found' : 'No teachers added yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasSearch
                ? 'Try another search term.'
                : 'Add your first teacher to start managing faculty.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          if (!hasSearch) ...[const SizedBox(height: 20), _buildAddButton()],
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E9F1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            'Unable to load teachers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminId = FirebaseAuth.instance.currentUser?.uid;

    if (adminId == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('Teachers'),
          backgroundColor: Colors.white,
          foregroundColor: _navy,
        ),
        body: const Center(child: Text('Admin session not found.')),
      );
    }

    final teacherStream = FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection('teachers')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: _background,
      appBar: MediaQuery.of(context).size.width < 700
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: _navy,
              title: const Text(
                'Teachers',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      floatingActionButton: MediaQuery.of(context).size.width < 700
          ? FloatingActionButton.extended(
              onPressed: _openAddTeacher,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Teacher',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (MediaQuery.of(context).size.width >= 700) _buildHeader(),
            if (MediaQuery.of(context).size.width < 700)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: _buildSearchBar(),
              ),
            if (MediaQuery.of(context).size.width < 700)
              _buildMobileAddButton(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: teacherStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildErrorState(snapshot.error!),
                    );
                  }

                  final teachers =
                      snapshot.data?.docs.where(_matchesSearch).toList() ?? [];

                  if (teachers.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: _buildEmptyState(),
                    );
                  }

                  final isMobile = MediaQuery.of(context).size.width < 850;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 28,
                      8,
                      isMobile ? 16 : 28,
                      24,
                    ),
                    child: isMobile
                        ? ListView.builder(
                            itemCount: teachers.length,
                            itemBuilder: (context, index) {
                              return _buildTeacherCard(teachers[index]);
                            },
                          )
                        : SingleChildScrollView(
                            child: _buildDesktopTable(teachers),
                          ),
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
