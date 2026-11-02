import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.red.shade50,

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.error_outline,

                size: 70,

                color: Colors.red.shade400,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Oops!",

              style: TextStyle(
                fontSize: 24,

                fontWeight: FontWeight.bold,

                color: Colors.red.shade700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              message,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: onRetry,

                icon: const Icon(Icons.refresh),

                label: const Text("Try Again"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
