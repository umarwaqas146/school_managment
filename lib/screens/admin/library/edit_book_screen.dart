import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBookScreen extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final String docId;

  const EditBookScreen({
    super.key,
    required this.bookData,
    required this.docId,
  });

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  late TextEditingController bookNameController;
  late TextEditingController authorController;
  late TextEditingController categoryController;
  late TextEditingController isbnController;
  late TextEditingController quantityController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    bookNameController = TextEditingController(
      text: widget.bookData["bookName"],
    );

    authorController = TextEditingController(text: widget.bookData["author"]);

    categoryController = TextEditingController(
      text: widget.bookData["category"],
    );

    isbnController = TextEditingController(text: widget.bookData["isbn"]);

    quantityController = TextEditingController(
      text: widget.bookData["quantity"]?.toString(),
    );
  }

  Future<void> updateBook() async {
    if (bookNameController.text.trim().isEmpty ||
        authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Book Name and Author required")),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("books")
          .doc(widget.docId)
          .update({
            "bookName": bookNameController.text.trim(),

            "author": authorController.text.trim(),

            "category": categoryController.text.trim(),

            "isbn": isbnController.text.trim(),

            "quantity": quantityController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Book Updated Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
      padding: const EdgeInsets.only(bottom: 16),

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
    bookNameController.dispose();

    authorController.dispose();

    categoryController.dispose();

    isbnController.dispose();

    quantityController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Book"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            CircleAvatar(
              radius: 45,

              backgroundColor: Colors.blue.shade100,

              child: const Icon(Icons.menu_book, size: 45, color: Colors.blue),
            ),

            const SizedBox(height: 25),

            inputField("Book Name", Icons.book, bookNameController),

            inputField("Author", Icons.person, authorController),

            inputField("Category", Icons.category, categoryController),

            inputField("ISBN", Icons.confirmation_number, isbnController),

            inputField("Quantity", Icons.numbers, quantityController),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              height: 55,

              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: updateBook,

                      icon: const Icon(Icons.save),

                      label: const Text(
                        "Update Book",
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
