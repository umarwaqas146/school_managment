import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController bookNameController = TextEditingController();

  final TextEditingController authorController = TextEditingController();

  final TextEditingController categoryController = TextEditingController();

  final TextEditingController isbnController = TextEditingController();

  final TextEditingController quantityController = TextEditingController();

  bool isLoading = false;

  Future<void> addBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection("books").add({
        "bookName": bookNameController.text.trim(),
        "author": authorController.text.trim(),
        "category": categoryController.text.trim(),
        "isbn": isbnController.text.trim(),
        "quantity": int.parse(quantityController.text.trim()),
        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Book Added Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      bookNameController.clear();
      authorController.clear();
      categoryController.clear();
      isbnController.clear();
      quantityController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error : $e"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,

        validator: (value) {
          if (value == null || value.trim().isEmpty) {
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
      appBar: AppBar(title: const Text("Add Book"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              buildField(bookNameController, "Book Name", Icons.menu_book),

              buildField(authorController, "Author", Icons.person),

              buildField(categoryController, "Category", Icons.category),

              buildField(isbnController, "ISBN", Icons.qr_code),

              buildField(
                quantityController,
                "Quantity",
                Icons.numbers,
                keyboard: TextInputType.number,
              ),

              const SizedBox(height: 25),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: addBook,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "Save Book",
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
