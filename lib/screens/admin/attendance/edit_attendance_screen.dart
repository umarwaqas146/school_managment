import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> attendanceData;
  final String docId;

  const EditAttendanceScreen({
    super.key,
    required this.attendanceData,
    required this.docId,
  });

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  final String adminId = FirebaseAuth.instance.currentUser!.uid;

  late TextEditingController studentNameController;
  late TextEditingController classController;
  late TextEditingController sectionController;
  late TextEditingController dateController;

  String status = "Present";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    studentNameController = TextEditingController(
      text: widget.attendanceData["studentName"] ?? "",
    );

    classController = TextEditingController(
      text: widget.attendanceData["class"] ?? "",
    );

    sectionController = TextEditingController(
      text: widget.attendanceData["section"] ?? "",
    );

    dateController = TextEditingController(
      text: widget.attendanceData["date"] ?? "",
    );

    status = widget.attendanceData["status"] ?? "Present";
  }

  Future<void> updateAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(adminId)
          .collection("attendance")
          .doc(widget.docId)
          .update({
            "studentName": studentNameController.text.trim(),
            "class": classController.text.trim(),
            "section": sectionController.text.trim(),
            "date": dateController.text.trim(),
            "status": status,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Attendance Updated Successfully"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    studentNameController.dispose();
    classController.dispose();
    sectionController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Attendance"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: studentNameController,
              decoration: const InputDecoration(
                labelText: "Student Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: classController,
              decoration: const InputDecoration(
                labelText: "Class",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: sectionController,
              decoration: const InputDecoration(
                labelText: "Section",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: "Date",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: "Attendance Status",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Present", child: Text("Present")),
                DropdownMenuItem(value: "Absent", child: Text("Absent")),
                DropdownMenuItem(value: "Leave", child: Text("Leave")),
              ],
              onChanged: (value) {
                setState(() {
                  status = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: updateAttendance,
                      child: const Text(
                        "Update Attendance",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
