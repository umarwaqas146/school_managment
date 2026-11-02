import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification History"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
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
                "No Notifications Found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: notifications.length,

            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;

              final String title = data["title"]?.toString() ?? "No Title";

              final String message =
                  data["message"]?.toString() ?? "No Message";

              final String receiver =
                  data["receiver"]?.toString() ?? "All Users";

              final String date = data["date"]?.toString() ?? "N/A";

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
                    backgroundColor: Colors.blue.shade100,

                    child: const Icon(Icons.notifications, color: Colors.blue),
                  ),

                  title: Text(
                    title,
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
                        Text(message),

                        const SizedBox(height: 5),

                        Text("Receiver : $receiver"),

                        const SizedBox(height: 3),

                        Text("Date : $date"),
                      ],
                    ),
                  ),

                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
