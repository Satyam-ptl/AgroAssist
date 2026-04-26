import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'crops_screen.dart';
import 'farmers_screen.dart';
import 'login_screen.dart';
import 'reminder_history_screen.dart';
import 'reminders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _myProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (AuthService.isAdmin) return;
    try {
      final profile = await ApiService.getMyProfile();
      if (!mounted) return;
      setState(() => _myProfile = profile);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.session?.username ?? 'User';
    final width = MediaQuery.of(context).size.width;
    final avatarRadius = width * 0.12;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: const Color(0xFF2E7D32),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: (width * 0.08).clamp(20.0, 36.0), color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  username,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  backgroundColor: AuthService.isAdmin ? Colors.red.shade100 : Colors.green.shade100,
                  label: Text(AuthService.isAdmin ? 'Admin' : 'Farmer'),
                ),
              ),
              const SizedBox(height: 16),
              if (!AuthService.isAdmin)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(
                          (_myProfile?['phone_number'] ?? '').toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(
                          (_myProfile?['location'] ?? _myProfile?['city'] ?? '').toString(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _openEditSheet,
                            child: const Text('Edit Phone & Location'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (AuthService.isAdmin) ...[
                const Text('Admin Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ListTile(
                  leading: const Icon(Icons.grass),
                  title: const Text('Manage Crops', overflow: TextOverflow.ellipsis, maxLines: 1),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CropsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Manage Farmers', overflow: TextOverflow.ellipsis, maxLines: 1),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FarmersScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Send Reminders', overflow: TextOverflow.ellipsis, maxLines: 1),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RemindersScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Reminder History', overflow: TextOverflow.ellipsis, maxLines: 1),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ReminderHistoryScreen()));
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About AgroAssist', overflow: TextOverflow.ellipsis, maxLines: 1),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('About AgroAssist'),
                      content: Text('AgroAssist helps farmers and admins manage crops and tasks efficiently.'),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red), overflow: TextOverflow.ellipsis, maxLines: 1),
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditSheet() async {
    final phoneController = TextEditingController(text: (_myProfile?['phone_number'] ?? '').toString());
    final locationController = TextEditingController(text: (_myProfile?['location'] ?? _myProfile?['city'] ?? '').toString());
    final navigator = Navigator.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ApiService.updateMyProfile({
                      'phone': phoneController.text.trim(),
                      'location': locationController.text.trim(),
                    });
                    if (!mounted) return;
                    navigator.pop();
                    await _loadProfile();
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    phoneController.dispose();
    locationController.dispose();
  }

  Future<void> _confirmLogout() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirmed != true) return;
    await AuthService.logout();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
