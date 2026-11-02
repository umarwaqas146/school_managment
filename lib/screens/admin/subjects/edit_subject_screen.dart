import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditSubjectScreen extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final String docId;

  const EditSubjectScreen({
    super.key,

    required this.subjectData,

    required this.docId,
  });

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  late TextEditingController subjectController;

  late TextEditingController classController;

  late TextEditingController teacherController;

  late TextEditingController codeController;

  late TextEditingController descriptionController;

  final String adminId = FirebaseAuth.instance.currentUser!.uid;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    subjectController = TextEditingController(
      text: widget.subjectData["subjectName"],
    );

    classController = TextEditingController(
      text: widget.subjectData["className"],
    );

    teacherController = TextEditingController(
      text: widget.subjectData["teacherName"],
    );

    codeController = TextEditingController(
      text: widget.subjectData["subjectCode"],
    );

    descriptionController = TextEditingController(
      text: widget.subjectData["description"],
    );
  }

  Future<void> updateSubject() async {
    if (subjectController.text.trim().isEmpty ||
        classController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject Name and Class required")),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(adminId)
          .collection("subjects")
          .doc(widget.docId)
          .update({
            "subjectName": subjectController.text.trim(),

            "className": classController.text.trim(),

            "teacherName": teacherController.text.trim(),

            "subjectCode": codeController.text.trim(),

            "description": descriptionController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subject Updated Successfully"),

          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget inputField(
    String label,

    IconData icon,

    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: TextField(
        controller: controller,

        decoration: InputDecoration(
          labelText: label,

          prefixIcon: Icon(icon),

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    subjectController.dispose();

    classController.dispose();

    teacherController.dispose();

    codeController.dispose();

    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Subject"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            CircleAvatar(
              radius: 45,

              backgroundColor: Colors.blue.shade100,

              child: const Icon(Icons.book, size: 45, color: Colors.blue),
            ),

            const SizedBox(height: 25),

            inputField("Subject Name", Icons.book, subjectController),

            inputField("Class Name", Icons.class_, classController),

            inputField("Teacher Name", Icons.person, teacherController),

            inputField("Subject Code", Icons.code, codeController),

            inputField("Description", Icons.description, descriptionController),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              height: 55,

              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: updateSubject,

                      icon: const Icon(Icons.save),

                      label: const Text(
                        "Update Subject",

                        style: TextStyle(fontSize: 18),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,

                        foregroundColor: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
