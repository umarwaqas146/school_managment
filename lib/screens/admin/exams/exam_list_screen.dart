import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      DateTime? date;

      if (value is Timestamp) {
        date = value.toDate();
      } else if (value is DateTime) {
        date = value;
      } else if (value is String) {
        date = DateTime.tryParse(value);
      }

      if (date == null) {
        return value.toString();
      }

      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchText.isEmpty) return true;

    final examName = _getString(data['examName']).toLowerCase();
    final className = _getString(data['class']).toLowerCase();
    final subject = _getString(data['subject']).toLowerCase();
    final totalMarks = _getString(data['totalMarks']).toLowerCase();

    return examName.contains(_searchText) ||
        className.contains(_searchText) ||
        subject.contains(_searchText) ||
        totalMarks.contains(_searchText);
  }

  Future<void> _deleteExam(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('exams').doc(docId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to delete exam'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(String docId, String examName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Exam',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text('Are you sure you want to delete "$examName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteExam(docId);
    }
  }

  Widget _buildInfo(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF1E293B),
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

  Widget _buildExamCard(String docId, Map<String, dynamic> data) {
    final examName = _getString(data['examName']);
    final className = _getString(data['class']);
    final subject = _getString(data['subject']);
    final totalMarks = _getString(data['totalMarks']);
    final examDate = _formatDate(data['date']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF2563EB),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        examName.isEmpty ? 'Unnamed Exam' : examName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject.isEmpty ? 'Subject not specified' : subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(
                        docId,
                        examName.isEmpty ? 'this exam' : examName,
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 19,
                              color: Colors.red,
                            ),
                            SizedBox(width: 9),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildInfo(Icons.school_outlined, 'Class', className),
                const SizedBox(width: 12),
                _buildInfo(Icons.calendar_today_outlined, 'Date', examDate),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfo(Icons.grade_outlined, 'Total Marks', totalMarks),
                const SizedBox(width: 12),
                _buildInfo(Icons.menu_book_outlined, 'Subject', subject),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 34,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Exam List',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Exams',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exam, class, subject...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 21,
                      color: Color(0xFF64748B),
                    ),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear, size: 19),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
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
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('exams')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    title: 'Unable to load exams',
                    message:
                        'Please check your Firebase connection and try again.',
                  );
                }

                final documents = snapshot.data?.docs ?? [];

                final filteredDocuments = documents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return _matchesSearch(data);
                }).toList();

                if (documents.isEmpty) {
                  return _buildEmptyState(
                    title: 'No Exams Found',
                    message: 'Add an exam to see it listed here.',
                  );
                }

                if (filteredDocuments.isEmpty) {
                  return _buildEmptyState(
                    title: 'No Matching Exams',
                    message:
                        'Try searching with another exam, class, or subject.',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int columns = 1;

                    if (constraints.maxWidth >= 1100) {
                      columns = 3;
                    } else if (constraints.maxWidth >= 700) {
                      columns = 2;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: columns == 1 ? 2.0 : 1.55,
                      ),
                      itemCount: filteredDocuments.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocuments[index];

                        final data = doc.data() as Map<String, dynamic>;

                        return _buildExamCard(doc.id, data);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
