import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_class_screen.dart';
import 'class_details_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  String? get _adminId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentSnapshot> _filterClasses(List<DocumentSnapshot> classes) {
    if (_searchQuery.isEmpty) {
      return classes;
    }

    return classes.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      final className = (data['className'] ?? '').toString().toLowerCase();

      final section = (data['section'] ?? '').toString().toLowerCase();

      final teacherName = (data['teacherName'] ?? '').toString().toLowerCase();

      final roomNumber = (data['roomNumber'] ?? '').toString().toLowerCase();

      return className.contains(_searchQuery) ||
          section.contains(_searchQuery) ||
          teacherName.contains(_searchQuery) ||
          roomNumber.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final adminId = _adminId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text(
          'Classes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: adminId == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddClassScreen()),
                );
              },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Class',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: adminId == null
          ? _buildAccountError()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(adminId)
                  .collection('classes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  );
                }

                final allClasses = snapshot.data?.docs ?? [];

                final classes = _filterClasses(allClasses);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop = constraints.maxWidth >= 900;

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        desktop ? 28 : 18,
                        desktop ? 28 : 18,
                        desktop ? 28 : 18,
                        100,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(allClasses.length),
                              const SizedBox(height: 18),
                              _buildSearch(),
                              const SizedBox(height: 18),
                              _buildContent(classes, allClasses.isNotEmpty),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildHeader(int totalClasses) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.class_outlined,
            color: Color(0xFF1565C0),
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Classes',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$totalClasses class'
                '${totalClasses == 1 ? '' : 'es'} registered',
                style: const TextStyle(color: Color(0xFF697386), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by class, section, teacher or room...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 21,
          color: Color(0xFF64748B),
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 19,
                  color: Color(0xFF64748B),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildContent(List<DocumentSnapshot> classes, bool hasAnyClasses) {
    if (!hasAnyClasses) {
      return _buildEmptyState(
        icon: Icons.class_outlined,
        title: 'No Classes Found',
        message: 'Create your first class using the Add Class button.',
      );
    }

    if (classes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Matching Classes',
        message: 'Try searching with another class, teacher or section.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns = 1;

        if (width >= 1000) {
          columns = 3;
        } else if (width >= 650) {
          columns = 2;
        }

        final cardWidth = (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: classes.map((doc) {
            return SizedBox(width: cardWidth, child: _buildClassCard(doc));
          }).toList(),
        );
      },
    );
  }

  Widget _buildClassCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final className = (data['className'] ?? 'Unknown Class').toString();

    final section = (data['section'] ?? '').toString();

    final teacherName = (data['teacherName'] ?? 'Not assigned').toString();

    final roomNumber = (data['roomNumber'] ?? 'Not assigned').toString();

    final totalStudents = (data['totalStudents'] ?? 0).toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ClassDetailsScreen(classData: data, docId: doc.id),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 155),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
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
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_outlined,
                      color: Color(0xFF1565C0),
                      size: 23,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      section.isEmpty ? 'No Section' : 'Section $section',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                section.isEmpty ? className : '$className - $section',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              _buildInfoRow(Icons.person_outline_rounded, teacherName),
              const SizedBox(height: 5),
              _buildInfoRow(Icons.meeting_room_outlined, 'Room: $roomNumber'),
              const SizedBox(height: 5),
              _buildInfoRow(Icons.groups_outlined, 'Students: $totalStudents'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 29, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7A8494), fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to Load Classes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please check your internet connection or '
                'Firestore permissions and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF7A8494),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 17),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: Color(0xFF64748B),
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'Account Session Not Found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Please sign in again before managing classes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Color(0xFF7A8494)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
