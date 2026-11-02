import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
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

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');

      final period = hour >= 12 ? 'PM' : 'AM';

      hour = hour % 12;

      if (hour == 0) {
        hour = 12;
      }

      return '$day-$month-$year • $hour:$minute $period';
    }

    return 'Date unavailable';
  }

  Future<void> _deleteNotification(
    BuildContext context,
    DocumentSnapshot notification,
  ) async {
    final data = notification.data() as Map<String, dynamic>? ?? {};

    final title = (data['title'] ?? 'this notification').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Notification',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete "$title"?\n\n'
            'This action cannot be undone.',
          ),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .delete();

      if (!mounted) return;

      _showSnackBar('Notification deleted successfully.', Colors.green);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'Failed to delete notification.';

      switch (e.code) {
        case 'permission-denied':
          message =
              'Permission denied. You do not have access to delete this notification.';
          break;

        case 'unavailable':
          message = 'Server is temporarily unavailable. Please try again.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        default:
          if (e.message != null && e.message!.trim().isNotEmpty) {
            message = e.message!;
          }
      }

      _showSnackBar(message, Colors.red);
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Something went wrong. Please try again.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  InputDecoration _searchDecoration() {
    return InputDecoration(
      hintText: 'Search notifications...',
      prefixIcon: const Icon(
        Icons.search_rounded,
        size: 21,
        color: Color(0xFF64748B),
      ),
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(
              onPressed: () {
                _searchController.clear();
              },
              icon: const Icon(
                Icons.clear_rounded,
                size: 19,
                color: Color(0xFF64748B),
              ),
            )
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  List<DocumentSnapshot> _filterNotifications(
    List<DocumentSnapshot> notifications,
  ) {
    if (_searchQuery.isEmpty) {
      return notifications;
    }

    return notifications.where((notification) {
      final data = notification.data() as Map<String, dynamic>? ?? {};

      final title = (data['title'] ?? '').toString().toLowerCase();

      final message = (data['message'] ?? '').toString().toLowerCase();

      return title.contains(_searchQuery) || message.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        title: const Text(
          'Notification History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }

          final allNotifications = snapshot.data?.docs ?? [];

          final notifications = _filterNotifications(allNotifications);

          return LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;

              return SingleChildScrollView(
                padding: EdgeInsets.all(desktop ? 28 : 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(allNotifications.length),
                        const SizedBox(height: 18),
                        _buildSearch(),
                        const SizedBox(height: 18),
                        _buildContent(
                          notifications,
                          allNotifications.isNotEmpty,
                        ),
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

  Widget _buildHeader(int totalNotifications) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xFF1565C0),
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification History',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$totalNotifications notification'
                '${totalNotifications == 1 ? '' : 's'} found',
                style: const TextStyle(color: Color(0xFF697386), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: _searchDecoration(),
    );
  }

  Widget _buildContent(
    List<DocumentSnapshot> notifications,
    bool hasAnyNotifications,
  ) {
    if (!hasAnyNotifications) {
      return _buildEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No Notifications Found',
        message: 'There are no notifications in the system yet.',
      );
    }

    if (notifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Matching Notifications',
        message: 'Try searching with a different title or message.',
      );
    }

    return Column(
      children: notifications.map((notification) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNotificationCard(notification),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationCard(DocumentSnapshot notification) {
    final data = notification.data() as Map<String, dynamic>? ?? {};

    final title = (data['title'] ?? 'Untitled Notification').toString();

    final message = (data['message'] ?? '').toString();

    final createdAt = data['createdAt'];

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF1565C0),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'More options',
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteNotification(context, notification);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 19,
                                color: Colors.red,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF5F6B7A),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 29, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF172033),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7A8494), fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to Load Notifications',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please check your internet connection or '
                'Firestore permissions and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF7A8494),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 17),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
