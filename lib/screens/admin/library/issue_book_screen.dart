import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueBookScreen extends StatefulWidget {
  const IssueBookScreen({super.key});

  @override
  State<IssueBookScreen> createState() => _IssueBookScreenState();
}

class _IssueBookScreenState extends State<IssueBookScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController studentController = TextEditingController();
  final TextEditingController bookController = TextEditingController();
  final TextEditingController issueDateController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();

  bool isLoading = false;

  Future<void> issueBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("issued_books").add({
        "studentName": studentController.text.trim(),
        "bookName": bookController.text.trim(),
        "issueDate": issueDateController.text.trim(),
        "returnDate": returnDateController.text.trim(),
        "status": "Issued",
        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Book Issued Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      studentController.clear();
      bookController.clear();
      issueDateController.clear();
      returnDateController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  Widget field(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: (value) => value!.isEmpty ? "Required Field" : null,
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
    studentController.dispose();
    bookController.dispose();
    issueDateController.dispose();
    returnDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issue Book"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              field(studentController, "Student Name", Icons.person),

              field(bookController, "Book Name", Icons.menu_book),

              field(issueDateController, "Issue Date", Icons.date_range),

              field(returnDateController, "Return Date", Icons.event),

              const SizedBox(height: 25),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: issueBook,
                        icon: const Icon(Icons.assignment),
                        label: const Text(
                          "Issue Book",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
