import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'Notification title is required';
    }

    if (title.length < 3) {
      return 'Title must contain at least 3 characters';
    }

    if (title.length > 100) {
      return 'Title cannot exceed 100 characters';
    }

    if (RegExp(r'\s{2,}').hasMatch(title)) {
      return 'Please remove extra spaces';
    }

    return null;
  }

  String? _validateMessage(String? value) {
    final message = value?.trim() ?? '';

    if (message.isEmpty) {
      return 'Notification message is required';
    }

    if (message.length < 5) {
      return 'Message must contain at least 5 characters';
    }

    if (message.length > 1000) {
      return 'Message cannot exceed 1000 characters';
    }

    return null;
  }

  Future<void> _sendNotification() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final titleLower = title.toLowerCase();
      final messageLower = message.toLowerCase();

      // Prevent accidental duplicate notifications.
      final duplicateQuery = await firestore
          .collection('notifications')
          .where('titleLower', isEqualTo: titleLower)
          .where('messageLower', isEqualTo: messageLower)
          .limit(1)
          .get();

      if (duplicateQuery.docs.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showSnackBar(
          'A notification with the same title and message already exists.',
          Colors.orange,
        );

        return;
      }

      final notificationRef = firestore.collection('notifications').doc();

      await notificationRef.set({
        'notificationId': notificationRef.id,
        'title': title,
        'titleLower': titleLower,
        'message': message,
        'messageLower': messageLower,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      _titleController.clear();
      _messageController.clear();

      _showSnackBar('Notification sent successfully.', Colors.green);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Failed to send notification.';

      switch (e.code) {
        case 'permission-denied':
          errorMessage =
              'Permission denied. Please check your account permissions.';
          break;

        case 'unavailable':
          errorMessage = 'Server is temporarily unavailable. Please try again.';
          break;

        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;

        case 'failed-precondition':
          errorMessage =
              'Database configuration is incomplete. Please check Firestore.';
          break;

        default:
          if (e.message != null && e.message!.trim().isNotEmpty) {
            errorMessage = e.message!;
          }
      }

      _showSnackBar(errorMessage, Colors.red);
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Something went wrong. Please try again.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 21, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
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
          'Send Notification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool desktop = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.all(desktop ? 28 : 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Notification',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Send an announcement or important alert.',
                style: TextStyle(color: Color(0xFF697386), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Details',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Enter clear and concise information for recipients.',
            style: TextStyle(color: Color(0xFF7A8494), fontSize: 11.5),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            validator: _validateTitle,
            decoration: _inputDecoration(
              label: 'Notification Title',
              icon: Icons.title_rounded,
              hint: 'e.g. Parent Teacher Meeting',
            ),
          ),

          const SizedBox(height: 14),

          TextFormField(
            controller: _messageController,
            maxLength: 1000,
            minLines: 6,
            maxLines: 10,
            textInputAction: TextInputAction.newline,
            validator: _validateMessage,
            decoration: _inputDecoration(
              label: 'Notification Message',
              icon: Icons.message_outlined,
              hint: 'Write the notification message here...',
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFE8EDF3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use a short title and provide all important details '
                    'in the message. Duplicate notifications are blocked '
                    'automatically.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isLoading ? 'Sending...' : 'Send Notification',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
