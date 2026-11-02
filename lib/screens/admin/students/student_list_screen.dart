import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_student_screen.dart';
import 'edit_student_screen.dart';
import 'student_details_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  static const Color navy = Color(0xFF06264F);
  static const Color blue = Color(0xFF1769E0);
  static const Color background = Color(0xFFF4F7FB);
  static const Color border = Color(0xFFE3E9F1);
  static const Color darkText = Color(0xFF172033);
  static const Color greyText = Color(0xFF718096);

  String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value == null ? '' : value.toString().trim();
  }

  String _studentName(Map<String, dynamic> data) {
    final studentName = _text(data, 'studentName');

    if (studentName.isNotEmpty) {
      return studentName;
    }

    return _text(data, 'name');
  }

  String _cnic(Map<String, dynamic> data) {
    final cnic = _text(data, 'cnic');

    if (cnic.isNotEmpty) {
      return cnic;
    }

    final bForm = _text(data, 'bForm');

    if (bForm.isNotEmpty) {
      return bForm;
    }

    return _text(data, 'cnicBForm');
  }

  bool _matchesSearch(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final data = doc.data();

    final searchableText = [
      _text(data, 'name'),
      _text(data, 'studentName'),
      _text(data, 'fatherName'),
      _text(data, 'email'),
      _text(data, 'phone'),
      _text(data, 'studentId'),
      _text(data, 'class'),
      _text(data, 'section'),
      _text(data, 'address'),
      _cnic(data),
    ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery.toLowerCase());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _studentStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _deleteStudent(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final name = _studentName(doc.data());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Student',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete "$name"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      _showMessage('Admin session not found.', error: true);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('students')
          .doc(doc.id)
          .delete();

      if (mounted) {
        _showMessage('Student deleted successfully.');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(e.message ?? 'Failed to delete student.', error: true);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Something went wrong while deleting the student.',
          error: true,
        );
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red : navy,
      ),
    );
  }

  void _openAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddStudentScreen()),
    );
  }

  void _openEditStudent(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditStudentScreen(studentData: doc.data(), docId: doc.id),
      ),
    );
  }

  void _openStudentDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentDetailsScreen(studentData: doc.data(), docId: doc.id),
      ),
    );
  }

  Widget _avatar(String name, {double size = 46}) {
    final letter = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: blue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: blue,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _searchBox({double? width}) {
    return SizedBox(
      width: width,
      height: 45,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search students...',
            hintStyle: const TextStyle(color: greyText, fontSize: 13),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: greyText,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _addButton() {
    return FilledButton.icon(
      onPressed: _openAddStudent,
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text(
        'Add Student',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage student records and academic information',
                  style: TextStyle(color: greyText, fontSize: 13),
                ),
              ],
            ),
          ),
          _searchBox(width: 300),
          const SizedBox(width: 14),
          _addButton(),
        ],
      ),
    );
  }

  Widget _mobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Students',
            style: TextStyle(
              color: darkText,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage student records and academic information',
            style: TextStyle(color: greyText, fontSize: 13),
          ),
          const SizedBox(height: 15),
          _searchBox(),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(List<QueryDocumentSnapshot<Map<String, dynamic>>> students) {
    final total = students.length;

    final classes = students
        .map((doc) => _text(doc.data(), 'class').toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    final sections = students
        .map((doc) => _text(doc.data(), 'section').toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        _statCard(
          title: 'Total Students',
          value: total.toString(),
          icon: Icons.groups_rounded,
          iconColor: blue,
          iconBackground: blue.withOpacity(0.10),
        ),
        const SizedBox(width: 14),
        _statCard(
          title: 'Classes',
          value: classes.toString(),
          icon: Icons.class_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBackground: const Color(0xFFF1EAFE),
        ),
        const SizedBox(width: 14),
        _statCard(
          title: 'Sections',
          value: sections.toString(),
          icon: Icons.category_outlined,
          iconColor: const Color(0xFF059669),
          iconBackground: const Color(0xFFE8F8F1),
        ),
      ],
    );
  }

  Widget _mobileStats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final total = students.length;

    final classes = students
        .map((doc) => _text(doc.data(), 'class').toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _smallStat(
            title: 'Students',
            value: total.toString(),
            icon: Icons.groups_rounded,
            color: blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStat(
            title: 'Classes',
            value: classes.toString(),
            icon: Icons.class_rounded,
            color: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }

  Widget _smallStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: greyText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(List<QueryDocumentSnapshot<Map<String, dynamic>>> students) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 50,
            dataRowMinHeight: 68,
            dataRowMaxHeight: 78,
            horizontalMargin: 20,
            columnSpacing: 26,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFD)),
            columns: const [
              DataColumn(
                label: Text(
                  'STUDENT',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'CLASS',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'CONTACT',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'B-FORM / CNIC',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'SECTION',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTION',
                  style: TextStyle(
                    color: greyText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            rows: students.map((doc) {
              final data = doc.data();

              final name = _studentName(data);
              final email = _text(data, 'email');
              final phone = _text(data, 'phone');
              final fatherName = _text(data, 'fatherName');
              final studentId = _text(data, 'studentId');
              final className = _text(data, 'class');
              final section = _text(data, 'section');
              final cnic = _cnic(data);

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        _avatar(name, size: 40),
                        const SizedBox(width: 11),
                        SizedBox(
                          width: 180,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'Unnamed Student' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: darkText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (fatherName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    'F: $fatherName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: greyText,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              if (studentId.isNotEmpty)
                                Text(
                                  studentId,
                                  style: const TextStyle(
                                    color: greyText,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: blue.withOpacity(.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        className.isEmpty ? '-' : className,
                        style: const TextStyle(
                          color: blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                                color: greyText,
                                fontSize: 11,
                              ),
                            ),
                          if (phone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                phone,
                                style: const TextStyle(
                                  color: greyText,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      cnic.isEmpty ? '-' : cnic,
                      style: const TextStyle(color: greyText, fontSize: 11),
                    ),
                  ),
                  DataCell(
                    Text(
                      section.isEmpty ? '-' : section,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionButton(
                          icon: Icons.visibility_outlined,
                          tooltip: 'View',
                          onPressed: () => _openStudentDetails(doc),
                        ),
                        _actionButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          onPressed: () => _openEditStudent(doc),
                        ),
                        _actionButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete',
                          color: Colors.red,
                          onPressed: () => _deleteStudent(doc),
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

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = greyText,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 20,
      icon: Icon(icon, color: color, size: 19),
    );
  }

  Widget _mobileStudentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final name = _studentName(data);
    final fatherName = _text(data, 'fatherName');
    final email = _text(data, 'email');
    final phone = _text(data, 'phone');
    final className = _text(data, 'class');
    final section = _text(data, 'section');
    final studentId = _text(data, 'studentId');
    final cnic = _cnic(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Unnamed Student' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (fatherName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Father: $fatherName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: greyText, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    _openStudentDetails(doc);
                  } else if (value == 'edit') {
                    _openEditStudent(doc);
                  } else {
                    _deleteStudent(doc);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text('View Details')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _mobileValue('Class', className)),
              Expanded(child: _mobileValue('Section', section)),
              Expanded(child: _mobileValue('Student ID', studentId)),
            ],
          ),
          if (cnic.isNotEmpty) ...[
            const SizedBox(height: 12),
            _mobileInfo(Icons.badge_outlined, cnic),
          ],
          if (phone.isNotEmpty) _mobileInfo(Icons.phone_outlined, phone),
          if (email.isNotEmpty) _mobileInfo(Icons.email_outlined, email),
        ],
      ),
    );
  }

  Widget _mobileValue(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: greyText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: darkText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _mobileInfo(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: greyText),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: greyText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final searching = _searchQuery.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: blue.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching ? Icons.search_off_rounded : Icons.school_outlined,
              color: blue,
              size: 32,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            searching ? 'No students found' : 'No students added yet',
            style: const TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try a different search term.'
                : 'Start by adding your first student.',
            style: const TextStyle(color: greyText, fontSize: 12),
          ),
          if (!searching) ...[const SizedBox(height: 18), _addButton()],
        ],
      ),
    );
  }

  Widget _errorState(Object error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load students',
              style: TextStyle(
                color: darkText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: greyText, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: background,
        body: const Center(
          child: Text(
            'Admin session not found.',
            style: TextStyle(color: darkText, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: isMobile
          ? AppBar(
              elevation: 0,
              backgroundColor: navy,
              foregroundColor: Colors.white,
              title: const Text(
                'Student Management',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            )
          : null,
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: _openAddStudent,
              backgroundColor: blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Student',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!isMobile) _header(),
            if (isMobile) _mobileHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _studentStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: blue),
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorState(snapshot.error!);
                  }

                  final allStudents = snapshot.data?.docs ?? [];

                  final filteredStudents = allStudents
                      .where(_matchesSearch)
                      .toList();

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 28,
                      20,
                      isMobile ? 16 : 28,
                      100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile)
                          _mobileStats(allStudents)
                        else
                          _stats(allStudents),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'All Students',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Student records and academic information',
                                    style: TextStyle(
                                      color: greyText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile) _addButton(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (filteredStudents.isEmpty)
                          _emptyState()
                        else if (isMobile)
                          Column(
                            children: filteredStudents
                                .map((doc) => _mobileStudentCard(doc))
                                .toList(),
                          )
                        else
                          _table(filteredStudents),
                      ],
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
