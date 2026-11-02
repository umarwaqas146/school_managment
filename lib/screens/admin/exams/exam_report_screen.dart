import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExamReportScreen extends StatefulWidget {
  const ExamReportScreen({super.key});

  @override
  State<ExamReportScreen> createState() => _ExamReportScreenState();
}

class _ExamReportScreenState extends State<ExamReportScreen> {
  String? selectedExamId;
  String searchText = '';

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _statCard(title: title, value: value, icon: icon, iconColor: color);
  }

  Widget _buildTopperCard(
    String studentName,
    String studentId,
    int marks,
    int totalMarks,
    String grade,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
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
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFFF59E0B),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Performing Student',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentName.isEmpty ? 'Unknown Student' : studentName,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (studentId.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Student ID: $studentId',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$marks / $totalMarks',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                grade.isEmpty ? '-' : grade,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(Map<String, dynamic> data, int index) {
    final studentName = _stringValue(data['studentName']);

    final studentId = _stringValue(data['studentId']);

    final examName = _stringValue(data['examName']);

    final obtainedMarks = _intValue(data['obtainedMarks']);

    final totalMarks = _intValue(data['totalMarks']);

    final percentage = _doubleValue(data['percentage']);

    final grade = _stringValue(data['grade']);

    final status = _stringValue(data['status']);

    final isPass = status.toLowerCase() == 'pass';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName.isEmpty ? 'Unknown Student' : studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  studentId.isEmpty
                      ? examName
                      : '$studentId${examName.isEmpty ? '' : ' • $examName'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$obtainedMarks / $totalMarks',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isPass ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grade.isEmpty ? status : grade,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isPass
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
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
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Exam Reports',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('marks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load exam reports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final allDocuments = snapshot.data?.docs ?? [];

          if (allDocuments.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      size: 55,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'No Report Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Enter student marks first to generate reports.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          final examMap = <String, String>{};

          for (final doc in allDocuments) {
            final data = doc.data();

            final examId = _stringValue(data['examId']);

            final examName = _stringValue(data['examName']);

            if (examId.isNotEmpty) {
              examMap[examId] = examName.isEmpty ? 'Unnamed Exam' : examName;
            }
          }

          final filteredDocuments = allDocuments.where((doc) {
            final data = doc.data();

            final examId = _stringValue(data['examId']);

            final studentName = _stringValue(data['studentName']).toLowerCase();

            final studentId = _stringValue(data['studentId']).toLowerCase();

            final examName = _stringValue(data['examName']).toLowerCase();

            final matchesExam =
                selectedExamId == null || selectedExamId == examId;

            final matchesSearch =
                searchText.isEmpty ||
                studentName.contains(searchText) ||
                studentId.contains(searchText) ||
                examName.contains(searchText);

            return matchesExam && matchesSearch;
          }).toList();

          int totalStudents = filteredDocuments.length;

          int passStudents = 0;
          int failStudents = 0;

          double totalPercentage = 0;
          int highestMarks = -1;

          Map<String, dynamic>? topperData;

          for (final doc in filteredDocuments) {
            final data = doc.data();

            final marks = _intValue(data['obtainedMarks']);

            final percentage = _doubleValue(data['percentage']);

            final status = _stringValue(data['status']).toLowerCase();

            totalPercentage += percentage;

            if (status == 'pass') {
              passStudents++;
            } else {
              failStudents++;
            }

            if (marks > highestMarks) {
              highestMarks = marks;
              topperData = data;
            }
          }

          final averagePercentage = totalStudents == 0
              ? 0
              : totalPercentage / totalStudents;

          final passPercentage = totalStudents == 0
              ? 0
              : (passStudents / totalStudents) * 100;

          final topperName = topperData == null
              ? '-'
              : _stringValue(topperData['studentName']);

          final topperId = topperData == null
              ? ''
              : _stringValue(topperData['studentId']);

          final topperMarks = topperData == null
              ? 0
              : _intValue(topperData['obtainedMarks']);

          final topperTotalMarks = topperData == null
              ? 0
              : _intValue(topperData['totalMarks']);

          final topperGrade = topperData == null
              ? ''
              : _stringValue(topperData['grade']);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1250),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Performance Overview',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Review student performance and examination results.',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selectedExamId != null)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    selectedExamId = null;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 17),
                                label: const Text('Clear Filter'),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildExamDropdown(examMap),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: _buildSearchField()),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildExamDropdown(examMap),
                                    const SizedBox(height: 12),
                                    _buildSearchField(),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 18),

                        GridView.count(
                          crossAxisCount: isWide ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isWide ? 1.65 : 1.45,
                          children: [
                            _buildReportCard(
                              title: 'Students Appeared',
                              value: totalStudents.toString(),
                              icon: Icons.people_outline,
                              color: const Color(0xFF2563EB),
                            ),
                            _buildReportCard(
                              title: 'Passed Students',
                              value: passStudents.toString(),
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF16A34A),
                            ),
                            _buildReportCard(
                              title: 'Failed Students',
                              value: failStudents.toString(),
                              icon: Icons.cancel_outlined,
                              color: const Color(0xFFDC2626),
                            ),
                            _buildReportCard(
                              title: 'Pass Percentage',
                              value: '${passPercentage.toStringAsFixed(1)}%',
                              icon: Icons.percent_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                            _buildReportCard(
                              title: 'Average Percentage',
                              value: '${averagePercentage.toStringAsFixed(1)}%',
                              icon: Icons.bar_chart_outlined,
                              color: const Color(0xFF7C3AED),
                            ),
                            _buildReportCard(
                              title: 'Highest Marks',
                              value: highestMarks < 0
                                  ? '-'
                                  : highestMarks.toString(),
                              icon: Icons.star_outline,
                              color: const Color(0xFF0891B2),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        if (topperData != null)
                          _buildTopperCard(
                            topperName,
                            topperId,
                            topperMarks,
                            topperTotalMarks,
                            topperGrade,
                          ),

                        if (topperData != null) const SizedBox(height: 18),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Student Results',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              '${filteredDocuments.length} records',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        if (filteredDocuments.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 38,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No matching results',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Try another student, exam, or student ID.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...List.generate(filteredDocuments.length, (index) {
                            return _buildResultRow(
                              filteredDocuments[index].data(),
                              index,
                            );
                          }),
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

  Widget _buildExamDropdown(Map<String, String> examMap) {
    return DropdownButtonFormField<String?>(
      value: selectedExamId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Filter by Exam',
        hintText: 'All Exams',
        prefixIcon: const Icon(
          Icons.assignment_outlined,
          size: 20,
          color: Color(0xFF64748B),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.3),
        ),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Exams', style: TextStyle(fontSize: 12.5)),
        ),
        ...examMap.entries.map((entry) {
          return DropdownMenuItem<String?>(
            value: entry.key,
            child: Text(
              entry.value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          selectedExamId = value;
        });
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchText = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        labelText: 'Search Results',
        hintText: 'Student name or student ID',
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: Color(0xFF64748B),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.3),
        ),
      ),
    );
  }
}
