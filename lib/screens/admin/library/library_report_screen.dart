import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryReportScreen extends StatelessWidget {
  const LibraryReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Library Reports"), centerTitle: true),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("issued_books")
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
                "No Library Reports Found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: reports.length,

            itemBuilder: (context, index) {
              final data = reports[index].data() as Map<String, dynamic>;

              final String bookName = data["bookName"]?.toString() ?? "N/A";

              final String studentName =
                  data["studentName"]?.toString() ?? "N/A";

              final String issueDate = data["issueDate"]?.toString() ?? "N/A";

              final String returnDate = data["returnDate"]?.toString() ?? "N/A";

              final String status = data["status"]?.toString() ?? "Pending";

              final bool returned = status == "Returned";

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),

                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: returned
                        ? Colors.green.shade100
                        : Colors.orange.shade100,

                    child: Icon(
                      returned ? Icons.check_circle : Icons.menu_book,
                      color: returned ? Colors.green : Colors.orange,
                    ),
                  ),

                  title: Text(
                    bookName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Student : $studentName"),
                        const SizedBox(height: 3),
                        Text("Issue Date : $issueDate"),
                        const SizedBox(height: 3),
                        Text("Return Date : $returnDate"),
                        const SizedBox(height: 3),
                        Text("Status : $status"),
                      ],
                    ),
                  ),

                  trailing: Chip(
                    backgroundColor: returned ? Colors.green : Colors.orange,

                    label: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
