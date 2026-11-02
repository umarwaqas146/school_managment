import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaidFeeScreen extends StatefulWidget {
  const PaidFeeScreen({super.key});

  @override
  State<PaidFeeScreen> createState() => _PaidFeeScreenState();
}

class _PaidFeeScreenState extends State<PaidFeeScreen> {
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

  double _getAmount(Map<String, dynamic> data) {
    final amount = data['amount'];

    if (amount is num) {
      return amount.toDouble();
    }

    return double.tryParse(amount?.toString() ?? '') ?? 0;
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
          'Paid Fees',
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
          final fees = _filterFees(documents);

          double totalCollection = 0;

          for (final doc in documents) {
            final data = doc.data() as Map<String, dynamic>;
            totalCollection += _getAmount(data);
          }

          double visibleCollection = 0;

          for (final doc in fees) {
            final data = doc.data() as Map<String, dynamic>;
            visibleCollection += _getAmount(data);
          }

          return Column(
            children: [
              _buildHeader(
                totalRecords: documents.length,
                visibleRecords: fees.length,
                totalCollection: totalCollection,
                visibleCollection: visibleCollection,
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

                          return _buildFeeCard(data);
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
    required double totalCollection,
    required double visibleCollection,
  }) {
    final bool isSearching = _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF2E9B68),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paid Fee Records',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSearching
                            ? '$visibleRecords of $totalRecords records shown'
                            : '$totalRecords completed payments',
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rs ${totalCollection.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
          if (isSearching) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Filtered collection: Rs ${visibleCollection.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667085),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeCard(Map<String, dynamic> data) {
    final studentName = (data['studentName'] ?? 'Unknown Student').toString();

    final studentId = (data['studentId'] ?? '').toString();

    final className = (data['class'] ?? '-').toString();

    final month = (data['month'] ?? '-').toString();

    final amount = _getAmount(data);

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
              Icons.check_circle_rounded,
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
                    _infoItem(
                      Icons.payments_outlined,
                      'Amount',
                      'Rs ${amount.toStringAsFixed(0)}',
                    ),
                    if (studentId.isNotEmpty)
                      _infoItem(Icons.badge_outlined, 'Student ID', studentId),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PAID',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E9B68),
              ),
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
              hasRecords ? 'No Matching Paid Fees' : 'No Paid Fees Found',
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
                  : 'Completed fee payments will appear here.',
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
                'Unable to Load Paid Fees',
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
