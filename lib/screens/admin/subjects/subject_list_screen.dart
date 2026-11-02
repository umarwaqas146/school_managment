import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_subject_screen.dart' as add_subject;
import 'subject_details_screen.dart';

class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  String search = '';

  String get adminId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (adminId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Please login again.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subjects',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Subject',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return add_subject.AddSubjectScreen();
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Subject',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value.trim().toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(adminId)
                  .collection('subjects')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load subjects.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Subjects Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final subjects = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final subjectName = (data['subjectName'] ?? '')
                      .toString()
                      .toLowerCase();

                  final className = (data['className'] ?? '')
                      .toString()
                      .toLowerCase();

                  final teacherName = (data['teacherName'] ?? '')
                      .toString()
                      .toLowerCase();

                  final subjectCode = (data['subjectCode'] ?? '')
                      .toString()
                      .toLowerCase();

                  return subjectName.contains(search) ||
                      className.contains(search) ||
                      teacherName.contains(search) ||
                      subjectCode.contains(search);
                }).toList();

                if (subjects.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching subjects found.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 90,
                  ),
                  itemCount: subjects.length,

                  itemBuilder: (context, index) {
                    final doc = subjects[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),

                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.blue,
                          ),
                        ),

                        title: Text(
                          (data['subjectName'] ?? '').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),

                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Class: ${(data['className'] ?? '').toString()}',
                              ),
                              Text(
                                'Teacher: ${(data['teacherName'] ?? '').toString()}',
                              ),
                              Text(
                                'Code: ${(data['subjectCode'] ?? '').toString()}',
                              ),
                            ],
                          ),
                        ),

                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),

                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) {
                                return SubjectDetailsScreen(
                                  subjectData: data,
                                  docId: doc.id,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
