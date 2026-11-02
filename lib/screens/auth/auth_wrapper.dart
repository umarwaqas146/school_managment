import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/dashboard/admin_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import '../student/student_dashboard.dart';
import '../parent/parent_dashboard.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final User user = snapshot.data!;

        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserProfile(firestore, user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return _AccountProblemScreen(
                message:
                    'Unable to load your account information.\n\n'
                    'Please check your internet connection and try again.',
                onRetry: () {
                  auth.signOut();
                },
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return _AccountProblemScreen(
                message:
                    'Your Firebase account exists, but no user profile '
                    'was found in the school system.',
                onRetry: () {
                  auth.signOut();
                },
              );
            }

            final String role = _normalizeRole(profile['role']);

            switch (role) {
              case 'admin':
                return const AdminDashboard();

              case 'teacher':
                return const TeacherDashboard();

              case 'student':
                return const StudentDashboard();

              case 'parent':
                return const ParentDashboard();

              default:
                return _AccountProblemScreen(
                  message:
                      'Your account has an invalid or missing user role.\n\n'
                      'Please contact the school administrator.',
                  onRetry: () {
                    auth.signOut();
                  },
                );
            }
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile(
    FirebaseFirestore firestore,
    User user,
  ) async {
    // ============================================================
    // 1. FAST UID LOOKUP
    // ============================================================

    final DocumentSnapshot<Map<String, dynamic>> uidDoc = await firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (uidDoc.exists) {
      final data = uidDoc.data();

      if (data != null) {
        return {...data, '_documentId': uidDoc.id};
      }
    }

    // ============================================================
    // 2. EXACT EMAIL LOOKUP
    // ============================================================

    final String? email = user.email?.trim();

    if (email == null || email.isEmpty) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>> emailSnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (emailSnapshot.docs.isNotEmpty) {
      final doc = emailSnapshot.docs.first;

      return {...doc.data(), '_documentId': doc.id};
    }

    // ============================================================
    // 3. LOWERCASE EMAIL LOOKUP
    // ============================================================

    final String lowercaseEmail = email.toLowerCase();

    final QuerySnapshot<Map<String, dynamic>> lowercaseSnapshot =
        await firestore
            .collection('users')
            .where('emailLower', isEqualTo: lowercaseEmail)
            .limit(1)
            .get();

    if (lowercaseSnapshot.docs.isNotEmpty) {
      final doc = lowercaseSnapshot.docs.first;

      return {...doc.data(), '_documentId': doc.id};
    }

    return null;
  }

  static String _normalizeRole(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim().toLowerCase();
  }
}

// ================================================================
// AUTH LOADING SCREEN
// ================================================================

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06264F),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Sapient School',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF06264F),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Loading your account...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1769E0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ACCOUNT PROBLEM SCREEN
// ================================================================

class _AccountProblemScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AccountProblemScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person_off_rounded,
                        color: Color(0xFFD97706),
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Account Problem',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.logout_rounded, size: 19),
                        label: const Text(
                          'Return to Login',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1769E0),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
