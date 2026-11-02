import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeeListScreen extends StatefulWidget {
  const FeeListScreen({super.key});

  @override
  State<FeeListScreen> createState() => _FeeListScreenState();
}

class _FeeListScreenState extends State<FeeListScreen> {
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

  Future<void> _deleteFee(String id) async {
    try {
      await FirebaseFirestore.instance.collection('fees').doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fee deleted successfully'),
          backgroundColor: Color(0xFFD64545),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete fee: $e'),
          backgroundColor: const Color(0xFFD64545),
        ),
      );
    }
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
          content: Text('Fee marked as paid'),
          backgroundColor: Color(0xFF2E9B68),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update fee: $e'),
          backgroundColor: const Color(0xFFD64545),
        ),
      );
    }
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Fee Record?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
          content: const Text(
            'This fee record will be permanently deleted. Continue?',
            style: TextStyle(color: Color(0xFF667085)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
      final status = (data['status'] ?? '').toString().toLowerCase();

      return studentName.contains(_searchQuery) ||
          studentId.contains(_searchQuery) ||
          className.contains(_searchQuery) ||
          month.contains(_searchQuery) ||
          status.contains(_searchQuery);
    }).toList();
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
          'Fee List',
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
            .orderBy('createdAt', descending: true)
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
              _buildTopSection(
                totalRecords: documents.length,
                visibleRecords: fees.length,
              ),
              Expanded(
                child: fees.isEmpty
                    ? _buildEmptyState(hasRecords: documents.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                        itemCount: fees.length,
                        itemBuilder: (context, index) {
                          final fee =
                              fees[index].data() as Map<String, dynamic>;

                          return _buildFeeCard(fees[index].id, fee);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection({
    required int totalRecords,
    required int visibleRecords,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          Container(
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
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF356AE6),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fee Records',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$visibleRecords of $totalRecords records shown',
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
                    color: const Color(0xFFF3F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$totalRecords Total',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4D596D),
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
              hintText: 'Search student, ID, class, month or status...',
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

  Widget _buildFeeCard(String id, Map<String, dynamic> fee) {
    final studentName = (fee['studentName'] ?? 'Unknown Student').toString();
    final studentId = (fee['studentId'] ?? '').toString();
    final className = (fee['class'] ?? '-').toString();
    final month = (fee['month'] ?? '-').toString();
    final amount = (fee['amount'] ?? 0).toString();
    final status = (fee['status'] ?? 'Pending').toString();

    final bool isPaid = status.toLowerCase() == 'paid';

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
              color: isPaid ? const Color(0xFFEAF8F1) : const Color(0xFFFFF4E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid
                  ? Icons.check_circle_outline_rounded
                  : Icons.pending_actions_rounded,
              color: isPaid ? const Color(0xFF2E9B68) : const Color(0xFFDD8A22),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(status, isPaid),
                  ],
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
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Fee actions',
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF667085)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'paid' && !isPaid) {
                await _markAsPaid(id);
              }

              if (value == 'delete') {
                final confirmed = await _confirmDelete();

                if (confirmed) {
                  await _deleteFee(id);
                }
              }
            },
            itemBuilder: (context) => [
              if (!isPaid)
                const PopupMenuItem<String>(
                  value: 'paid',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 19,
                        color: Color(0xFF2E9B68),
                      ),
                      SizedBox(width: 10),
                      Text('Mark as Paid'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: Color(0xFFD64545),
                    ),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFEAF8F1) : const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isPaid ? const Color(0xFF2E9B68) : const Color(0xFFDD8A22),
        ),
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
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: Color(0xFF356AE6),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              hasRecords ? 'No Matching Fee Records' : 'No Fee Records Found',
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
                  : 'Fee records will appear here after they are added.',
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
                'Unable to Load Fee Records',
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
