import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  double _calculatePercentage(Map<String, dynamic> data) {
    final obtained = _toDouble(data['obtainedMarks']);

    final total = _toDouble(data['totalMarks'] ?? data['examTotalMarks']);

    if (total > 0) {
      return (obtained / total) * 100;
    }

    // Backward compatibility:
    // If total marks are not stored, assume the value is already a percentage.
    return obtained;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pass':
        return Colors.green;
      case 'fail':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pass':
        return Icons.check_circle_rounded;
      case 'fail':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Student Results',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('marks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 52,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load results.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 58, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No Results Found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }

          final results = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];

              final data = result.data() as Map<String, dynamic>;

              final studentId = (data['studentId'] ?? 'N/A').toString();

              final examId = (data['examId'] ?? 'N/A').toString();

              final obtainedMarks = _toDouble(data['obtainedMarks']);

              final totalMarks = _toDouble(
                data['totalMarks'] ?? data['examTotalMarks'],
              );

              final percentage = _calculatePercentage(data);

              final grade = (data['grade'] ?? 'N/A').toString();

              final status = (data['status'] ?? 'Unknown').toString();

              final statusColor = _statusColor(status);

              final statusIcon = _statusIcon(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1.5,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in_rounded,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Student Result',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Student ID: $studentId',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 16, color: statusColor),
                                const SizedBox(width: 5),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      _InfoRow(
                        icon: Icons.assignment_outlined,
                        label: 'Exam ID',
                        value: examId,
                      ),

                      const SizedBox(height: 8),

                      _InfoRow(
                        icon: Icons.score_outlined,
                        label: 'Marks',
                        value: totalMarks > 0
                            ? '${_formatNumber(obtainedMarks)} / ${_formatNumber(totalMarks)}'
                            : _formatNumber(obtainedMarks),
                      ),

                      const SizedBox(height: 8),

                      _InfoRow(
                        icon: Icons.percent_rounded,
                        label: 'Percentage',
                        value: '${percentage.toStringAsFixed(1)}%',
                      ),

                      const SizedBox(height: 8),

                      _InfoRow(
                        icon: Icons.grade_outlined,
                        label: 'Grade',
                        value: grade,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.blueGrey),
        const SizedBox(width: 9),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
