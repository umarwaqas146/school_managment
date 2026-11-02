import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PendingFeeScreen extends StatefulWidget {
  const PendingFeeScreen({super.key});

  @override
  State<PendingFeeScreen> createState() => _PendingFeeScreenState();
}

class _PendingFeeScreenState extends State<PendingFeeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

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

  List<QueryDocumentSnapshot> _filterFees(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) {
      return docs;
    }

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final studentName = (data['studentName'] ?? '').toString().toLowerCase();
      final studentId = (data['studentId'] ?? '').toString().toLowerCase();
      final className = (data['class'] ?? '').toString().toLowerCase();
      final month = (data['month'] ?? '').toString().toLowerCase();

      return studentName.contains(_searchQuery) ||
          studentId.contains(_searchQuery) ||
          className.contains(_searchQuery) ||
          month.contains(_searchQuery);
    }).toList();
  }

  Future<void> _markAsPaid(String id) async {
    try {
      await FirebaseFirestore.instance.collection('fees').doc(id).update({
        'status': 'Paid',
        'paidAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fee marked as Paid successfully'),
          backgroundColor: Color(0xFF2E9B68),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unable to update fee record.'),
          backgroundColor: const Color(0xFFD64545),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Color(0xFFD64545),
        ),
      );
    }
  }

  Future<void> _confirmMarkAsPaid(String id, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Mark Fee as Paid?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
          content: Text(
            'Are you sure you want to mark $studentName\'s fee as paid?',
            style: const TextStyle(color: Color(0xFF667085)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E9B68),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Mark Paid'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _markAsPaid(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 24,
        title: const Text(
          'Pending Fees',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fees')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF356AE6)),
            );
          }

          final documents = snapshot.data?.docs ?? [];
          final fees = _filterFees(documents);

          return Column(
            children: [
              _buildHeader(
                totalPending: documents.length,
                visiblePending: fees.length,
              ),
              Expanded(
                child: fees.isEmpty
                    ? _buildEmptyState(hasRecords: documents.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 2, 24, 28),
                        itemCount: fees.length,
                        itemBuilder: (context, index) {
                          final doc = fees[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return _buildFeeCard(doc.id, data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required int totalPending,
    required int visiblePending,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: Color(0xFFDD8A22),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outstanding Fees',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$visiblePending of $totalPending pending records shown',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A8497),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalPending Pending',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDD8A22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search student, ID, class or month...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF98A2B3),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 21,
                color: Color(0xFF7A8497),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded, size: 19),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE8ECF3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE8ECF3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF356AE6),
                  width: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(String id, Map<String, dynamic> data) {
    final studentName = (data['studentName'] ?? 'Unknown Student').toString();
    final studentId = (data['studentId'] ?? '').toString();
    final className = (data['class'] ?? '-').toString();
    final month = (data['month'] ?? '-').toString();
    final amount = (data['amount'] ?? 0).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8ECF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: Color(0xFFDD8A22),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 14,
                  runSpacing: 5,
                  children: [
                    _infoItem(Icons.class_outlined, 'Class', className),
                    _infoItem(Icons.calendar_month_outlined, 'Month', month),
                    _infoItem(Icons.payments_outlined, 'Amount', 'Rs $amount'),
                    if (studentId.isNotEmpty)
                      _infoItem(Icons.badge_outlined, 'Student ID', studentId),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E9B68),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              _confirmMarkAsPaid(id, studentName);
            },
            icon: const Icon(Icons.check_rounded, size: 17),
            label: const Text(
              'Paid',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF8A94A6)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4D596D),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required bool hasRecords}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 34,
                color: Color(0xFF2E9B68),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              hasRecords ? 'No Matching Pending Fees' : 'No Pending Fees',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasRecords
                  ? 'Try a different search term.'
                  : 'All fee records are currently paid.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8497)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1D5D5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFD64545),
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to Load Pending Fees',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7A8497)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
