import 'package:flutter/material.dart';

import 'send_notification_screen.dart';
import 'notification_history_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NotificationItem(
        title: 'Send Notification',
        subtitle: 'Send messages and alerts',
        icon: Icons.send_outlined,
        screen: const SendNotificationScreen(),
      ),
      _NotificationItem(
        title: 'Notification History',
        subtitle: 'View previously sent notifications',
        icon: Icons.history_rounded,
        screen: const NotificationHistoryScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff172033),
        title: const Text(
          'Notification Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool desktop = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: EdgeInsets.all(desktop ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xffEAF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
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
                            'Notifications',
                            style: TextStyle(
                              color: Color(0xff172033),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Send and manage school notifications.',
                            style: TextStyle(
                              color: Color(0xff697386),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: desktop ? 2 : 1,
                    mainAxisExtent: 92,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    return _NotificationCard(item: items[index]);
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

class _NotificationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
  });
}

class _NotificationCard extends StatefulWidget {
  final _NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        transform: Matrix4.translationValues(0, hovering ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: hovering ? const Color(0xffBBD4F6) : const Color(0xffE4E9F0),
          ),
          boxShadow: [
            BoxShadow(
              color: hovering
                  ? const Color(0xff1565C0).withOpacity(.10)
                  : Colors.black.withOpacity(.025),
              blurRadius: hovering ? 18 : 8,
              offset: Offset(0, hovering ? 7 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => widget.item.screen),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: hovering
                          ? const Color(0xff1565C0)
                          : const Color(0xffEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: hovering ? Colors.white : const Color(0xff1565C0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            color: Color(0xff172033),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff7A8494),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: hovering
                        ? const Color(0xff1565C0)
                        : const Color(0xffA9B1BD),
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
