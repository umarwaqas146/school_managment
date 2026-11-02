import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'edit_user_screen.dart';
import 'add_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedRole = 'All';

  final List<String> _roles = const [
    'All',
    'admin',
    'teacher',
    'student',
    'parent',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getValue(Map<String, dynamic> data, String key) {
    return (data[key] ?? '').toString().trim();
  }

  bool _matchesSearch(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    final searchableText = [
      _getValue(data, 'name'),
      _getValue(data, 'email'),
      _getValue(data, 'phone'),
      _getValue(data, 'role'),
    ].join(' ').toLowerCase();

    return searchableText.contains(query);
  }

  bool _matchesRole(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    if (_selectedRole == 'All') {
      return true;
    }

    final role = _getValue(doc.data(), 'role').toLowerCase();

    return role == _selectedRole.toLowerCase();
  }

  Future<void> _deleteUser(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final role = _getValue(data, 'role').toLowerCase();

    final name = _getValue(data, 'name');

    if (role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin users cannot be deleted from this screen.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete User?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete "$name"?\n\n'
            'This will remove the user profile from Firestore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(doc.id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Unable to delete user.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openAddUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddUserScreen()),
    );
  }

  Future<void> _openEditUser(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditUserScreen(userId: doc.id, userData: doc.data()),
      ),
    );
  }

  String _formatRole(String role) {
    if (role.isEmpty) {
      return 'Unknown';
    }

    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF7C3AED);
      case 'teacher':
        return const Color(0xFF1769E0);
      case 'student':
        return const Color(0xFF059669);
      case 'parent':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'teacher':
        return Icons.school_outlined;
      case 'student':
        return Icons.person_outline;
      case 'parent':
        return Icons.family_restroom_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Widget _buildRoleChip(String role) {
    final color = _roleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(role), size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            _formatRole(role),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(int totalUsers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people_alt_outlined,
                        color: Color(0xFF1769E0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System Users',
                            style: TextStyle(
                              color: Color(0xFF0B1F3A),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$totalUsers registered users',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openAddUser,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add User'),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: Color(0xFF1769E0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Users',
                      style: TextStyle(
                        color: Color(0xFF0B1F3A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$totalUsers registered users',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openAddUser,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add User'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          if (isMobile) {
            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search name, email, phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Role',
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role == 'All' ? 'All Roles' : _formatRole(role),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search name, email, phone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.filter_alt_outlined),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role == 'All' ? 'All Roles' : _formatRole(role),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final name = _getValue(data, 'name');
    final email = _getValue(data, 'email');
    final phone = _getValue(data, 'phone');
    final role = _getValue(data, 'role');

    final displayName = name.isEmpty ? 'Unnamed User' : name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF2FF),
                child: Text(
                  displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1769E0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0B1F3A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildRoleChip(role),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  phone.isEmpty ? 'No phone' : phone,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditUser(doc),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  onPressed: role.toLowerCase() == 'admin'
                      ? null
                      : () => _deleteUser(doc),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFD)),
            columnSpacing: 28,
            columns: const [
              DataColumn(
                label: Text(
                  'User',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              DataColumn(
                label: Text(
                  'Email',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              DataColumn(
                label: Text(
                  'Phone',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              DataColumn(
                label: Text(
                  'Role',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
            rows: docs.map((doc) {
              final data = doc.data();

              final name = _getValue(data, 'name');
              final email = _getValue(data, 'email');
              final phone = _getValue(data, 'phone');
              final role = _getValue(data, 'role');

              final displayName = name.isEmpty ? 'Unnamed User' : name;

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFEAF2FF),
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF1769E0),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 140,
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 190,
                      child: Text(
                        email.isEmpty ? '-' : email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(phone.isEmpty ? '-' : phone)),
                  DataCell(_buildRoleChip(role)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openEditUser(doc),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: role.toLowerCase() == 'admin'
                              ? null
                              : () => _deleteUser(doc),
                          color: Colors.red,
                          icon: const Icon(Icons.delete_outline, size: 19),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter =
        _searchController.text.trim().isNotEmpty || _selectedRole != 'All';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilter ? Icons.search_off_outlined : Icons.people_outline,
              size: 36,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No users found' : 'No users available',
            style: const TextStyle(
              color: Color(0xFF0B1F3A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try changing your search or role filter.'
                : 'Add your first system user to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _openAddUser,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add User'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 45,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data?.docs ?? [];

            final filteredDocs = allDocs
                .where(_matchesSearch)
                .where(_matchesRole)
                .toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 800;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(allDocs.length),
                          const SizedBox(height: 16),
                          _buildFilters(),
                          const SizedBox(height: 16),
                          if (filteredDocs.isEmpty)
                            _buildEmptyState()
                          else if (isMobile)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 500,
                                    mainAxisExtent: 225,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(filteredDocs[index]);
                              },
                            )
                          else
                            _buildDesktopTable(filteredDocs),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
