import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_subject_screen.dart';

class SubjectDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> subjectData;
  final String docId;

  const SubjectDetailsScreen({
    super.key,
    required this.subjectData,
    required this.docId,
  });

  String? get adminId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid.isEmpty) {
      return null;
    }

    return user.uid;
  }

  Future<void> deleteSubject(BuildContext context) async {
    final uid = adminId;

    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login again.")));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Subject"),
          content: const Text("Are you sure you want to delete this subject?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("subjects")
          .doc(docId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subject Deleted Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Firebase error: ${e.message ?? "Unable to delete subject."}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subject Details"),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return EditSubjectScreen(
                      subjectData: subjectData,
                      docId: docId,
                    );
                  },
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              deleteSubject(context);
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.book, size: 55, color: Colors.blue),
            ),

            const SizedBox(height: 25),

            _infoCard(
              Icons.book,
              "Subject Name",
              (subjectData["subjectName"] ?? "").toString(),
            ),

            _infoCard(
              Icons.class_,
              "Class Name",
              (subjectData["className"] ?? "").toString(),
            ),

            _infoCard(
              Icons.person,
              "Teacher Name",
              (subjectData["teacherName"] ?? "").toString(),
            ),

            _infoCard(
              Icons.code,
              "Subject Code",
              (subjectData["subjectCode"] ?? "").toString(),
            ),

            _infoCard(
              Icons.description,
              "Description",
              (subjectData["description"] ?? "").toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: ListTile(
        leading: Icon(icon, color: Colors.blue),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text(value.isEmpty ? "N/A" : value),
      ),
    );
  }
}
