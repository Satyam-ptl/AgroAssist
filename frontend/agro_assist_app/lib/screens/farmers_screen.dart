import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key});

  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _farmers = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmers() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getFarmers(search: _searchController.text.trim(), pageSize: 200);
      final results = List<Map<String, dynamic>>.from(
        ((response['results'] as List<dynamic>?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );

      if (!mounted) return;
      setState(() {
        _farmers = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), overflow: TextOverflow.ellipsis, maxLines: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAdmin) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Farmers screen is available for admin only.')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Expanded(
              child: Text('Farmers', overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            Chip(label: Text('${_farmers.length}', overflow: TextOverflow.ellipsis, maxLines: 1)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadFarmers(),
                decoration: InputDecoration(
                  hintText: 'Search farmers by name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadFarmers,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _farmers.length,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        final farmer = _farmers[index];
                        return _farmerCard(farmer);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmerCard(Map<String, dynamic> farmer) {
    final firstName = (farmer['first_name'] ?? '').toString();
    final lastName = (farmer['last_name'] ?? '').toString();
    final name = '$firstName $lastName'.trim();
    final location = (farmer['city'] ?? '').toString();
    final taskCount = (farmer['task_count'] ?? 0).toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        onTap: () => _openDetail(farmer),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF2E7D32),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(location, overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
              ],
            ),
            Chip(
              label: Text('Tasks: $taskCount', overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(farmer),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> farmer) async {
    final id = (farmer['id'] as num?)?.toInt();
    if (id == null) return;

    final name = '${(farmer['first_name'] ?? '').toString()} ${(farmer['last_name'] ?? '').toString()}'.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Farmer'),
        content: Text(
          'Remove $name? This permanently deletes their account and all data.',
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteFarmer(id);
      await _loadFarmers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Farmer removed', overflow: TextOverflow.ellipsis, maxLines: 1),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), overflow: TextOverflow.ellipsis, maxLines: 2),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _openDetail(Map<String, dynamic> farmer) {
    final name = '${(farmer['first_name'] ?? '').toString()} ${(farmer['last_name'] ?? '').toString()}'.trim();
    final location = (farmer['city'] ?? '').toString();
    final phone = (farmer['phone_number'] ?? '').toString();
    final taskCount = (farmer['task_count'] ?? 0).toString();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(phone, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(location, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text('Assigned tasks: $taskCount', overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(farmer);
                      },
                      child: const Text('Remove Farmer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
