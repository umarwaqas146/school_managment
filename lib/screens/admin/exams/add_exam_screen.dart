import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();

  final examNameController = TextEditingController();
  final classController = TextEditingController();
  final subjectController = TextEditingController();
  final totalMarksController = TextEditingController();

  DateTime? selectedDate;

  bool isLoading = false;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveExam() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please Select Exam Date")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String examId = FirebaseFirestore.instance.collection("exams").doc().id;

      await FirebaseFirestore.instance.collection("exams").doc(examId).set({
        "examId": examId,
        "examName": examNameController.text.trim(),
        "class": classController.text.trim(),
        "subject": subjectController.text.trim(),
        "totalMarks": int.parse(totalMarksController.text),
        "date": Timestamp.fromDate(selectedDate!),
        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Exam Added Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      examNameController.clear();
      classController.clear();
      subjectController.clear();
      totalMarksController.clear();

      setState(() {
        selectedDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,

        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Required";
          }
          return null;
        },

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
    examNameController.dispose();
    classController.dispose();
    subjectController.dispose();
    totalMarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Exam"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              buildField(examNameController, "Exam Name", Icons.assignment),

              buildField(classController, "Class", Icons.class_),

              buildField(subjectController, "Subject", Icons.book),

              buildField(totalMarksController, "Total Marks", Icons.score),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.calendar_today),

                title: Text(
                  selectedDate == null
                      ? "Select Exam Date"
                      : DateFormat('dd MMM yyyy').format(selectedDate!),
                ),

                trailing: ElevatedButton(
                  onPressed: pickDate,
                  child: const Text("Pick"),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: isLoading ? null : saveExam,

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Exam", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
