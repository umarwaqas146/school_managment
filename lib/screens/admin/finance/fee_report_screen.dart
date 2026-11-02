import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeeReportScreen extends StatelessWidget {
  const FeeReportScreen({super.key});

  double _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString().trim() ?? '') ?? 0;
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
          'Fee Reports',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fees').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF356AE6)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          int totalRecords = 0;
          int paidRecords = 0;
          int pendingRecords = 0;

          double totalAmount = 0;
          double totalCollection = 0;
          double pendingCollection = 0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final amount = _parseAmount(data['amount']);
            final status = (data['status'] ?? 'Pending')
                .toString()
                .trim()
                .toLowerCase();

            totalRecords++;
            totalAmount += amount;

            if (status == 'paid') {
              paidRecords++;
              totalCollection += amount;
            } else {
              pendingRecords++;
              pendingCollection += amount;
            }
          }

          final double collectionPercentage = totalAmount > 0
              ? (totalCollection / totalAmount) * 100
              : 0;

          return RefreshIndicator(
            color: const Color(0xFF356AE6),
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              children: [
                _buildHeader(
                  totalRecords: totalRecords,
                  collectionPercentage: collectionPercentage,
                ),
                const SizedBox(height: 18),
                _buildSummaryGrid(
                  context,
                  totalRecords: totalRecords,
                  paidRecords: paidRecords,
                  pendingRecords: pendingRecords,
                  totalAmount: totalAmount,
                  totalCollection: totalCollection,
                  pendingCollection: pendingCollection,
                ),
                const SizedBox(height: 18),
                _buildCollectionSummary(
                  totalAmount: totalAmount,
                  totalCollection: totalCollection,
                  pendingCollection: pendingCollection,
                  collectionPercentage: collectionPercentage,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required int totalRecords,
    required double collectionPercentage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF356AE6),
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalRecords fee records • '
                  '${collectionPercentage.toStringAsFixed(1)}% collected',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8497),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context, {
    required int totalRecords,
    required int paidRecords,
    required int pendingRecords,
    required double totalAmount,
    required double totalCollection,
    required double pendingCollection,
  }) {
    final width = MediaQuery.of(context).size.width;

    int columns;

    if (width >= 1100) {
      columns = 3;
    } else if (width >= 650) {
      columns = 2;
    } else {
      columns = 1;
    }

    final cards = [
      _SummaryData(
        title: 'Total Fee Records',
        value: totalRecords.toString(),
        subtitle: 'All fee entries',
        icon: Icons.receipt_long_rounded,
        background: const Color(0xFFEEF4FF),
        iconColor: const Color(0xFF356AE6),
      ),
      _SummaryData(
        title: 'Paid Fees',
        value: paidRecords.toString(),
        subtitle: 'Completed payments',
        icon: Icons.check_circle_outline_rounded,
        background: const Color(0xFFEAF8F1),
        iconColor: const Color(0xFF2E9B68),
      ),
      _SummaryData(
        title: 'Pending Fees',
        value: pendingRecords.toString(),
        subtitle: 'Outstanding payments',
        icon: Icons.pending_actions_rounded,
        background: const Color(0xFFFFF4E8),
        iconColor: const Color(0xFFDD8A22),
      ),
      _SummaryData(
        title: 'Total Amount',
        value: 'Rs ${totalAmount.toStringAsFixed(0)}',
        subtitle: 'Expected collection',
        icon: Icons.account_balance_wallet_rounded,
        background: const Color(0xFFF0EEFF),
        iconColor: const Color(0xFF6B5DD3),
      ),
      _SummaryData(
        title: 'Total Collection',
        value: 'Rs ${totalCollection.toStringAsFixed(0)}',
        subtitle: 'Amount received',
        icon: Icons.payments_rounded,
        background: const Color(0xFFEAF8F1),
        iconColor: const Color(0xFF2E9B68),
      ),
      _SummaryData(
        title: 'Pending Collection',
        value: 'Rs ${pendingCollection.toStringAsFixed(0)}',
        subtitle: 'Amount outstanding',
        icon: Icons.money_off_csred_rounded,
        background: const Color(0xFFFFEEEE),
        iconColor: const Color(0xFFD64545),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) {
        return _buildSummaryCard(cards[index]);
      },
    );
  }

  Widget _buildSummaryCard(_SummaryData data) {
    return Container(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: data.iconColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionSummary({
    required double totalAmount,
    required double totalCollection,
    required double pendingCollection,
    required double collectionPercentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Overview of received and outstanding fee amounts.',
            style: TextStyle(fontSize: 11, color: Color(0xFF7A8497)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _amountRow(
                  'Expected',
                  'Rs ${totalAmount.toStringAsFixed(0)}',
                  const Color(0xFF356AE6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _amountRow(
                  'Collected',
                  'Rs ${totalCollection.toStringAsFixed(0)}',
                  const Color(0xFF2E9B68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _amountRow(
            'Outstanding',
            'Rs ${pendingCollection.toStringAsFixed(0)}',
            const Color(0xFFD64545),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Collection Progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667085),
                ),
              ),
              Text(
                '${collectionPercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E9B68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (collectionPercentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE9EDF4),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2E9B68),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8A94A6)),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 35,
                color: Color(0xFF356AE6),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No Fee Data Available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add fee records to generate financial reports.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF7A8497)),
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
                'Unable to Load Fee Report',
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

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color iconColor;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.iconColor,
  });
}
