import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  bool darkMode = false;

  Widget settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color color = Colors.blue,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blue.shade100,

                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blue.shade700,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Administrator",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      user?.email ?? "No Email",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            settingTile(
              icon: Icons.notifications,
              title: "Notifications",
              subtitle: "Enable or Disable Notifications",
              trailing: Switch(
                value: notifications,
                onChanged: (value) {
                  setState(() {
                    notifications = value;
                  });
                },
              ),
            ),

            settingTile(
              icon: Icons.dark_mode,
              title: "Dark Mode",
              subtitle: "Coming Soon",
              trailing: Switch(
                value: darkMode,
                onChanged: (value) {
                  setState(() {
                    darkMode = value;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Dark Mode will be available soon."),
                    ),
                  );
                },
              ),
            ),

            settingTile(
              icon: Icons.security,
              title: "Privacy Policy",
              subtitle: "View privacy policy",
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Privacy Policy Coming Soon")),
                );
              },
            ),

            settingTile(
              icon: Icons.info,
              title: "About App",
              subtitle: "Version 1.0.0",
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "The Sapient School",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "© 2026 The Sapient School",
                );
              },
            ),

            settingTile(
              icon: Icons.feedback,
              title: "Feedback",
              subtitle: "Send us your feedback",
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Feedback Feature Coming Soon")),
                );
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await FirebaseAuth.instance.signOut();

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
