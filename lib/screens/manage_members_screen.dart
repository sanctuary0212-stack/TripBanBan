import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';

class ManageMembersScreen extends StatefulWidget {
  const ManageMembersScreen({super.key, required this.controller, required this.tripId});
  final AppController controller;
  final String tripId;

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理旅伴')),
      body: StreamBuilder<List<MemberRow>>(
        stream: widget.controller.services.repository.watchMembers(widget.tripId),
        builder: (context, snapshot) {
          final members = snapshot.data ?? const <MemberRow>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final member in members)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(member.displayName),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => value == 'rename' ? _rename(member) : _delete(member),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('重新命名')),
                        PopupMenuItem(value: 'delete', child: Text('刪除旅伴')),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(onPressed: _add, icon: const Icon(Icons.person_add), label: const Text('新增旅伴')),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _askName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: '名稱')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('儲存')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _add() async {
    final name = await _askName('新增旅伴');
    if (name == null || name.isEmpty) return;
    await widget.controller.services.repository.addMember(widget.tripId, name);
  }

  Future<void> _rename(MemberRow member) async {
    final name = await _askName('重新命名', initial: member.displayName);
    if (name == null || name.isEmpty || name == member.displayName) return;
    await widget.controller.services.repository.renameMember(member.id, name);
  }

  Future<void> _delete(MemberRow member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除旅伴？'),
        content: Text('若 ${member.displayName} 已經出現在支出、公基金或結算紀錄中，系統會阻止刪除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.controller.services.repository.deleteMember(member.id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
