import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book List"), centerTitle: true),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("books")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Books Found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final books = snapshot.data!.docs;

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                elevation: 4,

                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.menu_book, color: Colors.blue),
                  ),

                  title: Text(
                    data["bookName"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Author : ${data["author"]}"),

                      Text("Category : ${data["category"]}"),

                      Text("ISBN : ${data["isbn"]}"),

                      Text("Quantity : ${data["quantity"]}"),
                    ],
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "delete") {
                        await FirebaseFirestore.instance
                            .collection("books")
                            .doc(books[index].id)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Book Deleted")),
                        );
                      }
                    },

                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
