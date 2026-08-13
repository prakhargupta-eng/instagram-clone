import 'package:flutter/material.dart';
import '../../adaptive_colors.dart';
import '../../constants.dart';
import '../../data/mock_data.dart';
import '../../models/user.dart';
import '../../widgets/avatar.dart';

class TagPeopleSheet extends StatefulWidget {
  const TagPeopleSheet({super.key, required this.initialTagged});

  final List<AppUser> initialTagged;

  @override
  State<TagPeopleSheet> createState() => _TagPeopleSheetState();
}

class _TagPeopleSheetState extends State<TagPeopleSheet> {
  late final List<AppUser> _selectedUsers = List.from(widget.initialTagged);
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsers = MockDatabase.users;
    final filteredUsers = allUsers.where((u) {
      final q = _query.toLowerCase();
      return u.username.toLowerCase().contains(q) ||
          u.fullName.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      'Tag People',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_selectedUsers),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 0.5, thickness: 0.5, color: context.borderColor),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val.trim()),
                  style: TextStyle(color: context.textPrimaryColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search people...',
                    prefixIcon: Icon(Icons.search, color: context.textSecondaryColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: context.borderColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
              if (_selectedUsers.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _selectedUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final user = _selectedUsers[index];
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundImage: NetworkImage(user.avatarUrl),
                        ),
                        label: Text('@${user.username}'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedUsers.removeWhere((u) => u.id == user.id);
                          });
                        },
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 0.5, thickness: 0.5, color: context.borderColor),
              ],
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 0.5, thickness: 0.5, color: context.borderColor),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isSelected = _selectedUsers.any((u) => u.id == user.id);
                    return ListTile(
                      leading: Avatar(url: user.avatarUrl, radius: 20),
                      title: Text(
                        user.username,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        user.fullName,
                        style: TextStyle(color: context.textSecondaryColor),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        shape: const CircleBorder(),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedUsers.add(user);
                            } else {
                              _selectedUsers.removeWhere((u) => u.id == user.id);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUsers.removeWhere((u) => u.id == user.id);
                          } else {
                            _selectedUsers.add(user);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
