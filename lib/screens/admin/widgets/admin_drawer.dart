import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../auth/login_screen.dart';
import '../attendance/attendance_screen.dart';
import '../classes/class_list_screen.dart';
import '../diary/diary_screen.dart';
import '../exams/exam_screen.dart';
import '../finance/finance_screen.dart';
import '../notifications/notification_screen.dart' as notifications;
import '../parents/parent_list_screen.dart';
import '../settings/settings_screen.dart';
import '../students/student_list_screen.dart';
import '../subjects/subject_list_screen.dart';
import '../teachers/teacher_list_screen.dart';
import '../users/user_list_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9363E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context);

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 9, right: 9, bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Container(
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? Colors.white : Colors.white.withOpacity(0.72),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.72),
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String email = user?.email ?? 'Administrator';

    return Drawer(
      width: 250,
      backgroundColor: AppTheme.navy,
      child: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------------
            // LOGO
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/icons/logos/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sapient',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'School Management System',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // ADMIN PROFILE
            // ------------------------------------------------------------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administrator',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            const Divider(color: Colors.white12, height: 1),

            const SizedBox(height: 8),

            // ------------------------------------------------------------
            // NAVIGATION
            // ------------------------------------------------------------
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _menuItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    active: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.school_outlined,
                    title: 'Students',
                    onTap: () {
                      _openPage(context, const StudentListScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.badge_outlined,
                    title: 'Teachers',
                    onTap: () {
                      _openPage(context, const TeacherListScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.family_restroom_outlined,
                    title: 'Parents',
                    onTap: () {
                      _openPage(context, const ParentListScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.people_outline,
                    title: 'Users',
                    onTap: () {
                      _openPage(context, const UserListScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.class_outlined,
                    title: 'Classes',
                    onTap: () {
                      _openPage(context, const ClassListScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.menu_book_outlined,
                    title: 'Subjects',
                    onTap: () {
                      _openPage(context, const SubjectListScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.fact_check_outlined,
                    title: 'Attendance',
                    onTap: () {
                      _openPage(context, const AttendanceScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.assignment_outlined,
                    title: 'Exams & Marks',
                    onTap: () {
                      _openPage(context, const ExamScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Finance',
                    onTap: () {
                      _openPage(context, const FinanceScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.auto_stories_outlined,
                    title: 'Diary',
                    onTap: () {
                      _openPage(context, const DiaryScreen());
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    onTap: () {
                      _openPage(
                        context,
                        const notifications.NotificationScreen(),
                      );
                    },
                  ),

                  _menuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      _openPage(context, const SettingsScreen());
                    },
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // LOGOUT
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                children: [
                  const Divider(color: Colors.white12),
                  InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => _logout(context),
                    child: Container(
                      height: 43,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.white.withOpacity(0.72),
                          ),
                          const SizedBox(width: 11),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
    );
  }
}
