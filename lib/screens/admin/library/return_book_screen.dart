import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnBookScreen extends StatefulWidget {
  const ReturnBookScreen({super.key});

  @override
  State<ReturnBookScreen> createState() => _ReturnBookScreenState();
}

class _ReturnBookScreenState extends State<ReturnBookScreen> {
  Future<void> returnBook(String docId) async {
    await FirebaseFirestore.instance
        .collection("issued_books")
        .doc(docId)
        .update({"status": "Returned", "returnedAt": Timestamp.now()});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Book Returned Successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Return Book"), centerTitle: true),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("issued_books")
            .where("status", isEqualTo: "Issued")
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
                "No Issued Books",
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
                  leading: const CircleAvatar(child: Icon(Icons.menu_book)),

                  title: Text(
                    data["bookName"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Student : ${data["studentName"]}"),
                      Text("Issue Date : ${data["issueDate"]}"),
                      Text("Return Date : ${data["returnDate"]}"),
                    ],
                  ),

                  trailing: ElevatedButton(
                    onPressed: () {
                      returnBook(books[index].id);
                    },
                    child: const Text("Return"),
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
