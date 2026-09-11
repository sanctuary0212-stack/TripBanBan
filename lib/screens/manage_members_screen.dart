import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../features/premium/premium_service.dart';

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
          final premium = widget.controller.services.premium.isPremium;
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
              FilledButton.icon(
                onPressed: () => _add(members),
                icon: const Icon(Icons.person_add),
                label: Text(!premium && members.length >= 3 ? '升級 Plus 以新增更多旅伴' : '新增旅伴'),
              ),
              if (!premium && members.length >= 3) ...[
                const SizedBox(height: 10),
                Text(
                  '免費版最多 3 人；${PremiumService.productLabel} ${PremiumService.priceLabel} 可使用 3 人以上。',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<String?> _askName(String title, {String initial = ''}) async {
    var text = initial;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名稱'),
          onChanged: (value) => text = value,
          onFieldSubmitted: (_) => Navigator.pop(context, text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, text.trim()), child: const Text('儲存')),
        ],
      ),
    );
  }

  Future<void> _add(List<MemberRow> members) async {
    if (members.length >= 3 && !widget.controller.services.premium.isPremium) {
      await _showPremiumRequired();
      return;
    }
    final name = await _askName('新增旅伴');
    if (name == null || name.isEmpty) return;
    await widget.controller.services.repository.addMember(widget.tripId, name);
  }

  Future<void> _showPremiumRequired() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.workspace_premium_rounded, size: 36),
        title: const Text('需要 TripBanBan Plus'),
        content: const Text(
          '免費版最多 3 人。Plus 為 US\$1.99 一次買斷，可使用更多旅伴，並解鎖 Google Drive 備份與還原。',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
        ],
      ),
    );
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
