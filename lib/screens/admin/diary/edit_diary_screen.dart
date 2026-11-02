import 'package:flutter/material.dart';

class EditDiaryScreen extends StatelessWidget {
  const EditDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Diary")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Update Title",

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              maxLines: 5,

              decoration: InputDecoration(
                labelText: "Update Description",

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
