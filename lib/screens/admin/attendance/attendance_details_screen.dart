import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_attendance_screen.dart';

class AttendanceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> attendanceData;
  final String docId;

  AttendanceDetailsScreen({
    super.key,
    required this.attendanceData,
    required this.docId,
  });

  final String adminId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> deleteAttendance(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(adminId)
          .collection("attendance")
          .doc(docId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance Deleted"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Delete Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditAttendanceScreen(
                    attendanceData: attendanceData,
                    docId: docId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              deleteAttendance(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Student Name: ${attendanceData["studentName"] ?? ""}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            Text(
              "Class: ${attendanceData["class"] ?? ""}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            Text(
              "Date: ${attendanceData["date"] ?? ""}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            Text(
              "Status: ${attendanceData["status"] ?? ""}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
