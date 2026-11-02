import 'package:flutter/material.dart';

import 'add_exam_screen.dart';
import 'exam_list_screen.dart';
import 'marks_entry_screen.dart';
import 'result_screen.dart';
import 'exam_report_screen.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ExamItem(
        title: 'Add Exam',
        subtitle: 'Create a new examination',
        icon: Icons.add_box_outlined,
        screen: const AddExamScreen(),
      ),
      _ExamItem(
        title: 'Exam List',
        subtitle: 'View all examinations',
        icon: Icons.list_alt_rounded,
        screen: const ExamListScreen(),
      ),
      _ExamItem(
        title: 'Marks Entry',
        subtitle: 'Enter student marks',
        icon: Icons.edit_note_rounded,
        screen: const MarksEntryScreen(),
      ),
      _ExamItem(
        title: 'Results',
        subtitle: 'View examination results',
        icon: Icons.assignment_turned_in_outlined,
        screen: const ResultScreen(),
      ),
      _ExamItem(
        title: 'Exam Reports',
        subtitle: 'View examination reports',
        icon: Icons.bar_chart_rounded,
        screen: const ExamReportScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Exam Management',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int columns = 1;

          if (constraints.maxWidth >= 1050) {
            columns = 3;
          } else if (constraints.maxWidth >= 650) {
            columns = 2;
          }

          final horizontalPadding = constraints.maxWidth >= 900 ? 28.0 : 18.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Header(),

                    const SizedBox(height: 20),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 88,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        return _ExamCard(item: items[index]);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExamItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  const _ExamItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });
}

class _ExamCard extends StatefulWidget {
  final _ExamItem item;

  const _ExamCard({required this.item});

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          hovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, hovering ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hovering ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: hovering
                  ? const Color(0xFF2563EB).withOpacity(0.10)
                  : Colors.black.withOpacity(0.025),
              blurRadius: hovering ? 16 : 8,
              offset: Offset(0, hovering ? 6 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => widget.item.screen),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hovering
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: 21,
                      color: hovering ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.subtitle,
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

                  const SizedBox(width: 8),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: hovering
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: hovering
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examinations',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage exams, marks, results and reports.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
