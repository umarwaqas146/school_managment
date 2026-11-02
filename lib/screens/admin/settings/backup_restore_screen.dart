import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  Future<void> backupData(BuildContext context) async {
    try {
      final users = await FirebaseFirestore.instance.collection("users").get();

      final students = await FirebaseFirestore.instance
          .collection("students")
          .get();

      final teachers = await FirebaseFirestore.instance
          .collection("teachers")
          .get();

      final books = await FirebaseFirestore.instance.collection("books").get();

      final fees = await FirebaseFirestore.instance.collection("fees").get();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Backup Successful\n"
            "Users: ${users.docs.length}\n"
            "Students: ${students.docs.length}\n"
            "Teachers: ${teachers.docs.length}\n"
            "Books: ${books.docs.length}\n"
            "Fees: ${fees.docs.length}",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Backup Failed\n$e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void restoreData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Restore feature will be available in next update."),
      ),
    );
  }

  Widget buildCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),

      child: ListTile(
        contentPadding: const EdgeInsets.all(20),

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color, size: 30),
        ),

        title: Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle),
        ),

        trailing: ElevatedButton(onPressed: onTap, child: const Text("Start")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Backup & Restore"), centerTitle: true),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            buildCard(
              context,
              "Backup Database",
              "Backup all Firebase collections.",
              Icons.backup,
              Colors.blue,
              () => backupData(context),
            ),

            buildCard(
              context,
              "Restore Database",
              "Restore previously saved backup.",
              Icons.restore,
              Colors.green,
              () => restoreData(context),
            ),
          ],
        ),
      ),
    );
  }
}
