import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardStatistics extends StatelessWidget {
  const DashboardStatistics({super.key});

  static const Color primary = Color(0xff1769E0);
  static const Color navy = Color(0xff06264F);
  static const Color background = Color(0xffF5F8FC);
  static const Color textDark = Color(0xff172033);
  static const Color textGrey = Color(0xff697386);

  String get adminId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _collectionStream(
    String collection,
  ) {
    if (adminId.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(adminId)
        .collection(collection)
        .snapshots();
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        final bool loading =
            snapshot.connectionState == ConnectionState.waiting;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE5EAF1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    loading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            count.toString(),
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style: const TextStyle(color: textGrey, fontSize: 10.5),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xffEAF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, color: primary, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (adminId.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1200) {
          columns = 3;
        } else if (constraints.maxWidth >= 700) {
          columns = 3;
        } else {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: columns == 1 ? 3.0 : 1.9,
          children: [
            _buildStatCard(
              context: context,
              title: 'Students',
              subtitle: 'Total registered students',
              icon: Icons.school_rounded,
              iconColor: primary,
              stream: _collectionStream('students'),
            ),

            _buildStatCard(
              context: context,
              title: 'Teachers',
              subtitle: 'Total registered teachers',
              icon: Icons.person_rounded,
              iconColor: const Color(0xff159570),
              stream: _collectionStream('teachers'),
            ),

            _buildStatCard(
              context: context,
              title: 'Parents',
              subtitle: 'Total registered parents',
              icon: Icons.family_restroom_rounded,
              iconColor: const Color(0xffE58A00),
              stream: _collectionStream('parents'),
            ),
          ],
        );
      },
    );
  }
}
