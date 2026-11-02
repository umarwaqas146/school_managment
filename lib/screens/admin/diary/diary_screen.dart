import 'package:flutter/material.dart';

import 'add_diary_screen.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  static const Color _background = Color(0xffF5F7FB);
  static const Color _text = Color(0xff172033);
  static const Color _muted = Color(0xff697386);
  static const Color _primary = Color(0xff1565C0);

  @override
  Widget build(BuildContext context) {
    final diaryItems = [
      const _DiaryItem(
        title: 'Math Homework',
        description: 'Complete Chapter 5 Questions 1-10',
        className: 'Class 10',
        student: 'Ali',
        date: '15 July 2026',
        icon: Icons.calculate_rounded,
        color: Color(0xff1565C0),
      ),
      const _DiaryItem(
        title: 'Science Project',
        description: 'Prepare Physics project',
        className: 'Class 9',
        student: 'Ahmed',
        date: '14 July 2026',
        icon: Icons.science_rounded,
        color: Color(0xff2E7D32),
      ),
    ];

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          'Student Diary',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDiaryScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Diary',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double padding = constraints.maxWidth >= 1100 ? 32 : 20;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, 24, padding, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: _primary,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Diary',
                            style: TextStyle(
                              color: _text,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage homework, projects and student activities',
                            style: TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffE5E9F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: _primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diary Entries',
                              style: TextStyle(
                                color: _text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Recent student diary activities',
                              style: TextStyle(color: _muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${diaryItems.length}',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (diaryItems.isEmpty)
                  _emptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: diaryItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _DiaryCard(item: diaryItems[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E9F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 45, color: Color(0xffA0A8B5)),
          SizedBox(height: 12),
          Text(
            'No diary entries found',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Add a new diary entry to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DiaryItem {
  final String title;
  final String description;
  final String className;
  final String student;
  final String date;
  final IconData icon;
  final Color color;

  const _DiaryItem({
    required this.title,
    required this.description,
    required this.className,
    required this.student,
    required this.date,
    required this.icon,
    required this.color,
  });
}

class _DiaryCard extends StatefulWidget {
  final _DiaryItem item;

  const _DiaryCard({required this.item});

  @override
  State<_DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<_DiaryCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, isHovered ? -2 : 0, 0),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered
                ? item.color.withOpacity(.25)
                : const Color(0xffE5E9F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isHovered ? .065 : .03),
              blurRadius: isHovered ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.color.withOpacity(.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: item.color, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Color(0xff172033),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Color(0xff697386),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.class_rounded,
                        text: item.className,
                      ),
                      _InfoChip(
                        icon: Icons.person_outline_rounded,
                        text: item.student,
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        text: item.date,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.more_horiz_rounded,
              color: isHovered ? item.color : const Color(0xffA0A8B5),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffF5F7FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 1),
          Icon(icon, size: 12, color: Color(0xff697386)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xff697386),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
