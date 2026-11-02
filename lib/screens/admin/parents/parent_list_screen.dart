import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_parent_screen.dart';
import 'edit_parent_screen.dart';
import 'parent_details_screen.dart';

class ParentListScreen extends StatefulWidget {
  const ParentListScreen({super.key});

  @override
  State<ParentListScreen> createState() => _ParentListScreenState();
}

class _ParentListScreenState extends State<ParentListScreen> {
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

  String _parentName(Map<String, dynamic> data) {
    final parentName = _text(data, 'parentName');

    if (parentName.isNotEmpty) {
      return parentName;
    }

    return _text(data, 'name');
  }

  String _studentName(Map<String, dynamic> data) {
    return _text(data, 'studentName');
  }

  String _relation(Map<String, dynamic> data) {
    return _text(data, 'relation');
  }

  bool _matchesSearch(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final data = doc.data();

    final searchableText = [
      _text(data, 'name'),
      _text(data, 'parentName'),
      _text(data, 'email'),
      _text(data, 'phone'),
      _text(data, 'studentName'),
      _text(data, 'studentId'),
      _text(data, 'relation'),
      _text(data, 'address'),
    ].join(' ').toLowerCase();

    return searchableText.contains(_searchQuery.toLowerCase());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _parentStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('parents')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _deleteParent(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final name = _parentName(data);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Parent',
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
          .collection('parents')
          .doc(doc.id)
          .delete();

      if (mounted) {
        _showMessage('Parent deleted successfully.');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(e.message ?? 'Failed to delete parent.', error: true);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Something went wrong while deleting the parent.',
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

  void _openAddParent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddParentScreen()),
    );
  }

  void _openEditParent(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditParentScreen(parentData: doc.data(), docId: doc.id),
      ),
    );
  }

  void _openParentDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ParentDetailsScreen(parentData: doc.data(), docId: doc.id),
      ),
    );
  }

  Widget _avatar(String name, {double size = 46}) {
    final letter = name.trim().isEmpty ? 'P' : name.trim()[0].toUpperCase();

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
            hintText: 'Search parents...',
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
      onPressed: _openAddParent,
      style: FilledButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text(
        'Add Parent',
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
                  'Parents',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage parents and student relationships',
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
            'Parents',
            style: TextStyle(
              color: darkText,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage parents and student relationships',
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

  Widget _stats(List<QueryDocumentSnapshot<Map<String, dynamic>>> parents) {
    final total = parents.length;

    final studentsLinked = parents
        .where(
          (doc) =>
              _studentName(doc.data()).isNotEmpty ||
              _text(doc.data(), 'studentId').isNotEmpty,
        )
        .length;

    final relations = parents
        .map((doc) => _relation(doc.data()).toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        _statCard(
          title: 'Total Parents',
          value: total.toString(),
          icon: Icons.family_restroom_rounded,
          iconColor: blue,
          iconBackground: blue.withOpacity(0.10),
        ),
        const SizedBox(width: 14),
        _statCard(
          title: 'Students Linked',
          value: studentsLinked.toString(),
          icon: Icons.child_care_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBackground: const Color(0xFFF1EAFE),
        ),
        const SizedBox(width: 14),
        _statCard(
          title: 'Relationships',
          value: relations.toString(),
          icon: Icons.people_alt_outlined,
          iconColor: const Color(0xFF059669),
          iconBackground: const Color(0xFFE8F8F1),
        ),
      ],
    );
  }

  Widget _mobileStats(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> parents,
  ) {
    final total = parents.length;

    final linked = parents
        .where(
          (doc) =>
              _studentName(doc.data()).isNotEmpty ||
              _text(doc.data(), 'studentId').isNotEmpty,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _smallStat(
            title: 'Parents',
            value: total.toString(),
            icon: Icons.family_restroom_rounded,
            color: blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStat(
            title: 'Linked Students',
            value: linked.toString(),
            icon: Icons.child_care_rounded,
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

  Widget _table(List<QueryDocumentSnapshot<Map<String, dynamic>>> parents) {
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
            columnSpacing: 28,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFD)),
            columns: const [
              DataColumn(
                label: Text(
                  'PARENT',
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
                  'RELATION',
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
            rows: parents.map((doc) {
              final data = doc.data();

              final name = _parentName(data);
              final email = _text(data, 'email');
              final phone = _text(data, 'phone');
              final student = _studentName(data);
              final studentId = _text(data, 'studentId');
              final relation = _relation(data);

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        _avatar(name, size: 40),
                        const SizedBox(width: 11),
                        SizedBox(
                          width: 155,
                          child: Text(
                            name.isEmpty ? 'Unnamed Parent' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
                                color: greyText,
                                fontSize: 12,
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
                    SizedBox(
                      width: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.isEmpty ? '-' : student,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (studentId.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                studentId,
                                style: const TextStyle(
                                  color: greyText,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    relation.isEmpty
                        ? const Text('-', style: TextStyle(color: greyText))
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: blue.withOpacity(.08),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              relation,
                              style: const TextStyle(
                                color: blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
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
                          onPressed: () => _openParentDetails(doc),
                        ),
                        _actionButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          onPressed: () => _openEditParent(doc),
                        ),
                        _actionButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete',
                          color: Colors.red,
                          onPressed: () => _deleteParent(doc),
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

  Widget _mobileParentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final name = _parentName(data);
    final email = _text(data, 'email');
    final phone = _text(data, 'phone');
    final student = _studentName(data);
    final relation = _relation(data);

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
                      name.isEmpty ? 'Unnamed Parent' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (relation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          relation,
                          style: const TextStyle(
                            color: blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    _openParentDetails(doc);
                  } else if (value == 'edit') {
                    _openEditParent(doc);
                  } else {
                    _deleteParent(doc);
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
          if (email.isNotEmpty) _mobileInfo(Icons.email_outlined, email),
          if (phone.isNotEmpty) _mobileInfo(Icons.phone_outlined, phone),
          if (student.isNotEmpty)
            _mobileInfo(Icons.person_outline_rounded, student),
        ],
      ),
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
              searching
                  ? Icons.search_off_rounded
                  : Icons.family_restroom_rounded,
              color: blue,
              size: 32,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            searching ? 'No parents found' : 'No parents added yet',
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
                : 'Start by adding your first parent.',
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
              'Unable to load parents',
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
                'Parent Management',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            )
          : null,
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: _openAddParent,
              backgroundColor: blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Parent',
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
                stream: _parentStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: blue),
                    );
                  }

                  if (snapshot.hasError) {
                    return _errorState(snapshot.error!);
                  }

                  final allParents = snapshot.data?.docs ?? [];

                  final filteredParents = allParents
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
                          _mobileStats(allParents)
                        else
                          _stats(allParents),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'All Parents',
                                    style: TextStyle(
                                      color: darkText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Parent records and student relationships',
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
                        if (filteredParents.isEmpty)
                          _emptyState()
                        else if (isMobile)
                          Column(
                            children: filteredParents
                                .map((doc) => _mobileParentCard(doc))
                                .toList(),
                          )
                        else
                          _table(filteredParents),
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
