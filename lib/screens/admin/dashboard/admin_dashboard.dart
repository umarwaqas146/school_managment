import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/login_screen.dart';

import '../users/user_list_screen.dart';
import '../users/add_user_screen.dart';

import '../students/student_list_screen.dart';
import '../students/add_student_screen.dart';

import '../teachers/teacher_list_screen.dart';
import '../teachers/add_teacher_screen.dart';

import '../parents/parent_list_screen.dart';
import '../parents/add_parent_screen.dart';

import '../classes/class_list_screen.dart';
import '../subjects/subject_list_screen.dart';

import '../attendance/attendance_screen.dart';
import '../exams/exam_screen.dart';
import '../finance/finance_screen.dart';

import '../settings/settings_screen.dart';
import '../diary/diary_screen.dart';
import '../notifications/notification_screen.dart' as notifications;

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const Color primary = Color(0xff1565C0);
  static const Color primaryDark = Color(0xff0D47A1);
  static const Color background = Color(0xffF5F7FB);
  static const Color textDark = Color(0xff172033);
  static const Color textGrey = Color(0xff697386);
  static const Color borderColor = Color(0xffE5E9F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool desktop = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              desktop ? 30 : 16,
              desktop ? 24 : 16,
              desktop ? 30 : 16,
              30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(desktop),
                    const SizedBox(height: 18),

                    _buildStatistics(),
                    const SizedBox(height: 18),

                    _buildQuickActions(context),
                    const SizedBox(height: 26),

                    _buildSectionHeader(
                      title: 'Management',
                      subtitle: 'Manage students, staff and school operations',
                    ),
                    const SizedBox(height: 13),

                    _buildManagementGrid(context),

                    const SizedBox(height: 28),

                    _buildFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: textDark),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.school_rounded, color: primary, size: 22),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The Sapient School',
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => notifications.NotificationScreen(),
              ),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 25),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 3),
        _buildProfileButton(context),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) async {
        if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        }

        if (value == 'logout') {
          await _logout(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 10),
              Text('Settings'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Colors.red),
              SizedBox(width: 10),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: primary.withOpacity(.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_rounded, color: primary, size: 21),
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 285,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryDark, primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(.20)),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The Sapient School',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'School Management System',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _drawerItem(
                    context,
                    'Dashboard',
                    Icons.dashboard_rounded,
                    const AdminDashboard(),
                    selected: true,
                  ),
                  _drawerItem(
                    context,
                    'Students',
                    Icons.school_rounded,
                    const StudentListScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Teachers',
                    Icons.person_rounded,
                    const TeacherListScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Parents',
                    Icons.family_restroom_rounded,
                    const ParentListScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Users',
                    Icons.people_alt_rounded,
                    const UserListScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Classes',
                    Icons.class_rounded,
                    const ClassListScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Subjects',
                    Icons.menu_book_rounded,
                    const SubjectListScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Attendance',
                    Icons.fact_check_rounded,
                    const AttendanceScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Exams',
                    Icons.assignment_rounded,
                    const ExamScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Finance',
                    Icons.account_balance_wallet_rounded,
                    const FinanceScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Diary',
                    Icons.menu_book_rounded,
                    const DiaryScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Notifications',
                    Icons.notifications_rounded,
                    notifications.NotificationScreen(),
                  ),
                  _drawerItem(
                    context,
                    'Settings',
                    Icons.settings_rounded,
                    const SettingsScreen(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen, {
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: primary.withOpacity(.09),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        leading: Icon(icon, size: 21, color: selected ? primary : textGrey),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? primary : textDark,
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context);

          if (screen is AdminDashboard) {
            return;
          }

          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcomeSection(bool desktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 25 : 19,
        vertical: desktop ? 22 : 19,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: desktop ? 23 : 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Monitor and manage your school from one place.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.82),
                    fontSize: desktop ? 13.5 : 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (desktop)
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.13),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _statisticsError('Admin session not found.');
    }

    final studentsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .snapshots();

    final teachersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('teachers')
        .snapshots();

    final parentsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('parents')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: studentsStream,
      builder: (context, studentSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: teachersStream,
          builder: (context, teacherSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: parentsStream,
              builder: (context, parentSnapshot) {
                final int students = studentSnapshot.data?.docs.length ?? 0;

                final int teachers = teacherSnapshot.data?.docs.length ?? 0;

                final int parents = parentSnapshot.data?.docs.length ?? 0;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    final int users = usersSnapshot.data?.docs.length ?? 0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;

                        int columns;

                        if (width >= 1100) {
                          columns = 4;
                        } else if (width >= 700) {
                          columns = 2;
                        } else {
                          columns = 1;
                        }

                        final cards = [
                          _DashboardStatData(
                            title: 'Students',
                            value: students,
                            subtitle: 'Registered students',
                            icon: Icons.school_rounded,
                            color: const Color(0xff1565C0),
                          ),
                          _DashboardStatData(
                            title: 'Teachers',
                            value: teachers,
                            subtitle: 'Teaching staff',
                            icon: Icons.person_rounded,
                            color: const Color(0xff2E7D32),
                          ),
                          _DashboardStatData(
                            title: 'Parents',
                            value: parents,
                            subtitle: 'Parent accounts',
                            icon: Icons.family_restroom_rounded,
                            color: const Color(0xff7B1FA2),
                          ),
                          _DashboardStatData(
                            title: 'Users',
                            value: users,
                            subtitle: 'System users',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xffEF6C00),
                          ),
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cards.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 13,
                                mainAxisSpacing: 13,
                                mainAxisExtent: 112,
                              ),
                          itemBuilder: (context, index) {
                            return _DashboardStatCard(data: cards[index]);
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statisticsError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: textGrey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionData(
        title: 'Add Student',
        icon: Icons.person_add_alt_1_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );
        },
      ),
      _QuickActionData(
        title: 'Add Teacher',
        icon: Icons.person_add_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTeacherScreen()),
          );
        },
      ),
      _QuickActionData(
        title: 'Add Parent',
        icon: Icons.group_add_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddParentScreen()),
          );
        },
      ),
      _QuickActionData(
        title: 'Attendance',
        icon: Icons.fact_check_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceScreen()),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                _quickAction(actions[i]),
                if (i != actions.length - 1) const SizedBox(height: 9),
              ],
            ],
          );
        }

        int columns = constraints.maxWidth >= 1100 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 66,
          ),
          itemBuilder: (context, index) {
            return _quickAction(actions[index]);
          },
        );
      },
    );
  }

  Widget _quickAction(_QuickActionData action) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: action.onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: primary, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: textGrey, fontSize: 12)),
      ],
    );
  }

  // ============================================================
  // MANAGEMENT GRID
  // ============================================================

  Widget _buildManagementGrid(BuildContext context) {
    final modules = [
      _ModuleData(
        title: 'Students',
        subtitle: 'Manage student records',
        icon: Icons.school_rounded,
        color: const Color(0xff1565C0),
        screen: const StudentListScreen(),
      ),
      _ModuleData(
        title: 'Teachers',
        subtitle: 'Manage teaching staff',
        icon: Icons.person_rounded,
        color: const Color(0xff2E7D32),
        screen: const TeacherListScreen(),
      ),
      _ModuleData(
        title: 'Parents',
        subtitle: 'Manage parent records',
        icon: Icons.family_restroom_rounded,
        color: const Color(0xff7B1FA2),
        screen: const ParentListScreen(),
      ),
      _ModuleData(
        title: 'Users',
        subtitle: 'Manage system users',
        icon: Icons.people_alt_rounded,
        color: const Color(0xffEF6C00),
        screen: const UserListScreen(),
      ),
      _ModuleData(
        title: 'Classes',
        subtitle: 'Manage school classes',
        icon: Icons.class_rounded,
        color: const Color(0xff00838F),
        screen: const ClassListScreen(),
      ),
      _ModuleData(
        title: 'Subjects',
        subtitle: 'Manage subjects',
        icon: Icons.menu_book_rounded,
        color: const Color(0xff5E35B1),
        screen: const SubjectListScreen(),
      ),
      _ModuleData(
        title: 'Attendance',
        subtitle: 'Biometric attendance',
        icon: Icons.fingerprint_rounded,
        color: const Color(0xff00897B),
        screen: const AttendanceScreen(),
      ),
      _ModuleData(
        title: 'Exams',
        subtitle: 'Manage examinations',
        icon: Icons.assignment_rounded,
        color: const Color(0xffC62828),
        screen: const ExamScreen(),
      ),
      _ModuleData(
        title: 'Finance',
        subtitle: 'Manage school finance',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xff6D4C41),
        screen: const FinanceScreen(),
      ),
      _ModuleData(
        title: 'Diary',
        subtitle: 'Manage school diary',
        icon: Icons.menu_book_rounded,
        color: const Color(0xff3949AB),
        screen: const DiaryScreen(),
      ),
      _ModuleData(
        title: 'Notifications',
        subtitle: 'Send school updates',
        icon: Icons.notifications_rounded,
        color: const Color(0xffD84315),
        screen: notifications.NotificationScreen(),
      ),
      _ModuleData(
        title: 'Settings',
        subtitle: 'System settings',
        icon: Icons.settings_rounded,
        color: const Color(0xff455A64),
        screen: const SettingsScreen(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1200) {
          columns = 4;
        } else if (constraints.maxWidth >= 800) {
          columns = 3;
        } else if (constraints.maxWidth >= 520) {
          columns = 2;
        } else {
          columns = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 13,
            mainAxisSpacing: 13,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) {
            return _ModuleCard(
              module: modules[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => modules[index].screen),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Center(
      child: Text(
        'The Sapient School Management System',
        style: TextStyle(
          color: textGrey.withOpacity(.75),
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
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
}

// ============================================================
// DASHBOARD STAT MODEL
// ============================================================

class _DashboardStatData {
  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DashboardStatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ============================================================
// DASHBOARD STAT CARD
// ============================================================

class _DashboardStatCard extends StatelessWidget {
  final _DashboardStatData data;

  const _DashboardStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminDashboard.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withOpacity(.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminDashboard.textGrey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value.toString(),
                  style: const TextStyle(
                    color: AdminDashboard.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTION MODEL
// ============================================================

class _QuickActionData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

// ============================================================
// MODULE MODEL
// ============================================================

class _ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

// ============================================================
// MODULE CARD
// ============================================================

class _ModuleCard extends StatefulWidget {
  final _ModuleData module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, isHovered ? -3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isHovered
                  ? module.color.withOpacity(.28)
                  : AdminDashboard.borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? .065 : .03),
                blurRadius: isHovered ? 17 : 9,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: module.color.withOpacity(isHovered ? .14 : .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: module.color, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminDashboard.textDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminDashboard.textGrey,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isHovered ? module.color : const Color(0xffA0A8B5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
