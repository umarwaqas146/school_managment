import 'package:flutter/material.dart';

import 'school_profile_screen.dart';
import 'change_password_screen.dart';
import 'backup_restore_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _background = Color(0xffF5F7FB);
  static const Color _text = Color(0xff172033);
  static const Color _muted = Color(0xff697386);

  @override
  Widget build(BuildContext context) {
    final settings = [
      _SettingItem(
        title: 'School Profile',
        subtitle: 'Manage school information',
        icon: Icons.school_rounded,
        color: const Color(0xff1565C0),
        screen: const SchoolProfileScreen(),
      ),
      _SettingItem(
        title: 'Change Password',
        subtitle: 'Update your account password',
        icon: Icons.lock_rounded,
        color: const Color(0xffEF6C00),
        screen: const ChangePasswordScreen(),
      ),
      _SettingItem(
        title: 'Backup & Restore',
        subtitle: 'Manage system data backup',
        icon: Icons.backup_rounded,
        color: const Color(0xff2E7D32),
        screen: const BackupRestoreScreen(),
      ),
      _SettingItem(
        title: 'About Application',
        subtitle: 'Application information',
        icon: Icons.info_outline_rounded,
        color: const Color(0xff6A1B9A),
        screen: const AboutAppScreen(),
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
          'Settings',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int columns = 1;

          if (constraints.maxWidth >= 1100) {
            columns = 3;
          } else if (constraints.maxWidth >= 650) {
            columns = 2;
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth >= 1100 ? 32 : 20,
              24,
              constraints.maxWidth >= 1100 ? 32 : 20,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xff1565C0).withOpacity(.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Color(0xff1565C0),
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Settings',
                            style: TextStyle(
                              color: _text,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage school and application preferences',
                            style: TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Settings & Administration',
                  style: TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose an option to manage your system',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: settings.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 92,
                  ),
                  itemBuilder: (context, index) {
                    final item = settings[index];

                    return _SettingCard(
                      item: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item.screen),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _SettingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

class _SettingCard extends StatefulWidget {
  final _SettingItem item;
  final VoidCallback onTap;

  const _SettingCard({required this.item, required this.onTap});

  @override
  State<_SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<_SettingCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, isHovered ? -3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isHovered
                  ? item.color.withOpacity(.30)
                  : const Color(0xffE5E9F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? .07 : .035),
                blurRadius: isHovered ? 18 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(isHovered ? .14 : .09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.color, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff172033),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff697386),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isHovered ? item.color : const Color(0xffA0A8B5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
