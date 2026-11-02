import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_book_screen.dart';

class BookDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> bookData;
  final String docId;

  const BookDetailsScreen({
    super.key,
    required this.bookData,
    required this.docId,
  });

  Future<void> deleteBook(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text("Delete Book"),

        content: const Text("Are you sure you want to delete this book?"),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },

            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },

            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection("books").doc(docId).delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Book Deleted Successfully"),
        backgroundColor: Colors.red,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Details"),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.edit),

            onPressed: () {
              Navigator.push(
                context,

                MaterialPageRoute(
                  builder: (_) =>
                      EditBookScreen(bookData: bookData, docId: docId),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),

            onPressed: () {
              deleteBook(context);
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

              child: const Icon(Icons.menu_book, size: 55, color: Colors.blue),
            ),

            const SizedBox(height: 25),
            _infoCard(Icons.book, "Book Name", bookData["bookName"] ?? ""),

            _infoCard(Icons.person, "Author", bookData["author"] ?? ""),

            _infoCard(Icons.category, "Category", bookData["category"] ?? ""),

            _infoCard(
              Icons.confirmation_number,
              "ISBN",
              bookData["isbn"] ?? "",
            ),

            _infoCard(
              Icons.library_books,
              "Quantity",
              bookData["quantity"]?.toString() ?? "0",
            ),

            _infoCard(
              Icons.check_circle,
              "Available",
              bookData["available"]?.toString() ?? "0",
            ),

            _infoCard(
              Icons.assignment,
              "Status",
              bookData["status"] ?? "Available",
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 4,

      margin: const EdgeInsets.only(bottom: 15),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: ListTile(
        leading: Icon(icon, color: Colors.blue),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Text(value.isEmpty ? "N/A" : value),
      ),
    );
  }
}
