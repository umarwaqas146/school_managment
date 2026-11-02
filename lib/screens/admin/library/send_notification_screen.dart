import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController messageController = TextEditingController();

  String receiver = "All";

  bool isLoading = false;

  Future<void> sendNotification() async {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection("notifications").add({
        "title": titleController.text.trim(),
        "message": messageController.text.trim(),
        "receiver": receiver,
        "date": DateTime.now().toString(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      titleController.clear();
      messageController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notification Sent Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error : $e"), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Notification"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.blue.shade100,

              child: const Icon(
                Icons.notifications_active,
                size: 45,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: titleController,

              decoration: InputDecoration(
                labelText: "Notification Title",
                prefixIcon: const Icon(Icons.title),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: messageController,
              maxLines: 5,

              decoration: InputDecoration(
                labelText: "Notification Message",
                prefixIcon: const Icon(Icons.message),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: receiver,

              decoration: InputDecoration(
                labelText: "Send To",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              items: const [
                DropdownMenuItem(value: "All", child: Text("All Users")),
                DropdownMenuItem(value: "Students", child: Text("Students")),
                DropdownMenuItem(value: "Teachers", child: Text("Teachers")),
                DropdownMenuItem(value: "Parents", child: Text("Parents")),
              ],

              onChanged: (value) {
                setState(() {
                  receiver = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: sendNotification,

                      icon: const Icon(Icons.send),

                      label: const Text(
                        "Send Notification",
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
