import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = "Loading..."});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const SizedBox(
            width: 50,

            height: 50,

            child: CircularProgressIndicator(
              strokeWidth: 4,

              color: Colors.blue,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            message,

            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
