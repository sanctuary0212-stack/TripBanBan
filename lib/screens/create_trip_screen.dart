import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../features/premium/premium_service.dart';
import '../widgets/currency_picker.dart';
import '../widgets/landmark_badge.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final nameController = TextEditingController();
  final destinationController = TextEditingController();
  final members = <TextEditingController>[TextEditingController(text: '我')];
  DateTime? startDate;
  DateTime? endDate;
  late String currency;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    currency = widget.controller.defaultCurrency;
  }

  @override
  void dispose() {
    nameController.dispose();
    destinationController.dispose();
    for (final item in members) item.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = widget.controller.services.premium.isPremium;
    return Scaffold(
      appBar: AppBar(title: const Text('建立新旅程')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: '旅程名稱', hintText: '例如：東京 6 日遊')),
          const SizedBox(height: 12),
          TextField(controller: destinationController, decoration: const InputDecoration(labelText: '目的地（選填）', hintText: '東京 / 沖繩 / 首爾…')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateButton('開始日期', startDate, (value) => setState(() => startDate = value))),
              const SizedBox(width: 12),
              Expanded(child: _dateButton('結束日期', endDate, (value) => setState(() => endDate = value))),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('旅程基準幣別'),
            subtitle: Text(currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final next = await showCurrencyPicker(context, selected: currency, title: '旅程基準幣別');
              if (next != null) setState(() => currency = next);
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text('旅伴', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addMemberField(premium),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('新增旅伴'),
              ),
            ],
          ),
          ...List.generate(members.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: members[index],
                      decoration: InputDecoration(labelText: '旅伴 ${index + 1}'),
                    ),
                  ),
                  if (members.length > 1)
                    IconButton(
                      onPressed: () => setState(() => members.removeAt(index).dispose()),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                ],
              ),
            );
          }),
          if (!premium)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '免費版每趟旅程最多 3 位旅伴；${PremiumService.productLabel} ${PremiumService.priceLabel} 可使用更多旅伴。',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('建立旅程')),
          ),
        ],
      ),
    );
  }

  Future<void> _addMemberField(bool premium) async {
    if (!premium && members.length >= 3) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.workspace_premium_rounded, size: 36),
          title: const Text('需要 TripBanBan Plus'),
          content: const Text('免費版每趟旅程最多 3 人。Plus 為 US\$1.99 一次買斷，可使用更多旅伴。'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))],
        ),
      );
      return;
    }
    if (mounted) setState(() => members.add(TextEditingController()));
  }

  Widget _dateButton(String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
          initialDate: value ?? DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value == null ? '選擇' : '${value.year}/${value.month}/${value.day}'),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final memberNames = members.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
    if (name.isEmpty || memberNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入旅程名稱並至少保留一位旅伴。')));
      return;
    }
    if (!widget.controller.services.premium.isPremium && memberNames.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('免費版每趟旅程最多 3 位旅伴。')));
      return;
    }

    setState(() => saving = true);
    try {
      final destination = destinationController.text.trim();
      final inferredCountry = inferCountryCode('$destination $name');
      final id = await widget.controller.services.repository.createTrip(
        name: name,
        destination: destination,
        countryCode: inferredCountry.isEmpty ? null : inferredCountry,
        startDate: startDate,
        endDate: endDate,
        baseCurrency: currency,
        memberNames: memberNames,
      );
      await widget.controller.selectTrip(id);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
