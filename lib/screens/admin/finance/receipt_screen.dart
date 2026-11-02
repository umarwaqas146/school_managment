import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
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

  List<QueryDocumentSnapshot> _filterReceipts(
    List<QueryDocumentSnapshot> docs,
  ) {
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

  String _formatAmount(dynamic amount) {
    if (amount is num) {
      return amount.toStringAsFixed(0);
    }

    final parsed = double.tryParse(amount?.toString() ?? '');

    if (parsed != null) {
      return parsed.toStringAsFixed(0);
    }

    return '0';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    if (timestamp is DateTime) {
      return '${timestamp.day.toString().padLeft(2, '0')}/'
          '${timestamp.month.toString().padLeft(2, '0')}/'
          '${timestamp.year}';
    }

    return '-';
  }

  void _showReceiptPreview(Map<String, dynamic> data) {
    final studentName = (data['studentName'] ?? 'Unknown Student').toString();

    final studentId = (data['studentId'] ?? '').toString();

    final className = (data['class'] ?? '-').toString();

    final month = (data['month'] ?? '-').toString();

    final amount = _formatAmount(data['amount']);

    final paidDate = _formatDate(data['paidAt']);

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: const BoxDecoration(
                      color: Color(0xFF356AE6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'THE SAPIENT SCHOOL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'OFFICIAL FEE RECEIPT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        _receiptRow('Student Name', studentName),
                        if (studentId.isNotEmpty)
                          _receiptRow('Student ID', studentId),
                        _receiptRow('Class', className),
                        _receiptRow('Fee Month', month),
                        _receiptRow('Payment Date', paidDate),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_rounded,
                                color: Color(0xFF2E9B68),
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Amount Paid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                              ),
                              Text(
                                'Rs $amount',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E9B68),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF2E9B68),
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'PAID',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E9B68),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Receipt download feature coming soon.',
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Download Receipt',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172033),
              ),
            ),
          ),
        ],
      ),
    );
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
          'Fee Receipts',
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
            .where('status', isEqualTo: 'Paid')
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

          final receipts = _filterReceipts(documents);

          return Column(
            children: [
              _buildHeader(
                totalRecords: documents.length,
                visibleRecords: receipts.length,
              ),
              Expanded(
                child: receipts.isEmpty
                    ? _buildEmptyState(hasRecords: documents.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 2, 24, 28),
                        itemCount: receipts.length,
                        itemBuilder: (context, index) {
                          final data =
                              receipts[index].data() as Map<String, dynamic>;

                          return _buildReceiptCard(data);
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
    required int totalRecords,
    required int visibleRecords,
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
                    color: const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF2E9B68),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Receipts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$visibleRecords of '
                        '$totalRecords paid records shown',
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
                    color: const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PAID',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E9B68),
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

  Widget _buildReceiptCard(Map<String, dynamic> data) {
    final studentName = (data['studentName'] ?? 'Unknown Student').toString();

    final studentId = (data['studentId'] ?? '').toString();

    final className = (data['class'] ?? '-').toString();

    final month = (data['month'] ?? '-').toString();

    final amount = _formatAmount(data['amount']);

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
              color: const Color(0xFFEAF8F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: Color(0xFF2E9B68),
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
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'View Receipt',
            onPressed: () {
              _showReceiptPreview(data);
            },
            icon: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF356AE6),
              size: 21,
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
                Icons.receipt_long_outlined,
                size: 34,
                color: Color(0xFF2E9B68),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              hasRecords ? 'No Matching Receipts' : 'No Receipts Available',
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
                  : 'Paid fee receipts will appear here.',
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
                'Unable to Load Receipts',
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
