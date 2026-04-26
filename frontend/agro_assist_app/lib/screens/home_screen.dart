import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/auth_ui_service.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = <String, dynamic>{};
  List<dynamic> _recentTasks = <dynamic>[];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
    });

    try {
      final stats = await ApiService.getDashboardStats();
      final tasksMap = await ApiService.getTasks(pageSize: 3);
      final tasks = List<dynamic>.from((tasksMap['results'] as List<dynamic>?) ?? const []);

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = stats;
        _recentTasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      setState(() {
        _loading = false;
      });
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService.session?.username ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Good morning, $username',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          IconButton(
            onPressed: () => AuthUiService.confirmAndLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: _buildStatCards(),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Recent Tasks',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const TasksScreen()),
                              );
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ListView.builder(
                        itemCount: _recentTasks.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = Map<String, dynamic>.from(_recentTasks[index] as Map);
                          final title = (item['task_name'] ?? '').toString();
                          final dueDate = (item['due_date'] ?? '').toString();
                          final priority = (item['importance'] ?? 'Medium').toString();
                          return Card(
                            child: ListTile(
                              title: Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Text(
                                dueDate,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              trailing: Chip(
                                label: Text(
                                  priority,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _buildStatCards() {
    final isAdmin = AuthService.isAdmin;

    if (isAdmin) {
      return [
        _statCard('Total Crops', _stats['total_crops'], Icons.grass, const [Color(0xFF388E3C), Color(0xFF66BB6A)]),
        _statCard('Total Farmers', _stats['total_farmers'], Icons.people, const [Color(0xFF1565C0), Color(0xFF42A5F5)]),
        _statCard('Pending Tasks', _stats['pending_tasks'], Icons.assignment, const [Color(0xFFF57C00), Color(0xFFFFB74D)]),
        _statCard('Overdue Tasks', _stats['overdue_tasks'], Icons.warning, const [Color(0xFFD32F2F), Color(0xFFEF5350)]),
      ];
    }

    return [
      _statCard('My Pending Tasks', _stats['my_pending_tasks'], Icons.assignment, const [Color(0xFFF57C00), Color(0xFFFFB74D)]),
      _statCard('My Overdue Tasks', _stats['my_overdue_tasks'], Icons.warning, const [Color(0xFFD32F2F), Color(0xFFEF5350)]),
      _statCard('My Completed Tasks', _stats['my_completed_tasks'], Icons.check_circle, const [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
      _statCard('Total Crops', _stats['total_crops'], Icons.grass, const [Color(0xFF1565C0), Color(0xFF42A5F5)]),
    ];
  }

  Widget _statCard(String label, dynamic value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${value ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
