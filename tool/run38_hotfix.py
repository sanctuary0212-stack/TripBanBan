from pathlib import Path
import re

records = Path('lib/screens/records_screen.dart')
text = records.read_text()
old_appbar = """        return Scaffold(
          appBar: AppBar(
            title: Text(strings.t('expenseRecords'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: StreamBuilder<List<ExpenseRow>>(
"""
new_appbar = """        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 82,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.t('expenseRecords'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: effectiveTripId,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    items: [
                      for (final item in trips)
                        DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) async {
                      if (value == null || value == effectiveTripId) return;
                      await widget.controller.selectTrip(value);
                      if (mounted) setState(() => selectedTripId = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          body: StreamBuilder<List<ExpenseRow>>(
"""
if old_appbar not in text:
    raise SystemExit('records appbar target not found')
text = text.replace(old_appbar, new_appbar, 1)

body_selector = """                  DropdownButtonFormField<String>(
                    value: effectiveTripId,
                    decoration: const InputDecoration(labelText: '旅程專案'),
                    items: [
                      for (final item in trips)
                        DropdownMenuItem(value: item.id, child: Text('${item.name} · ${item.baseCurrency}')),
                    ],
                    onChanged: (value) async {
                      if (value == null || value == effectiveTripId) return;
                      await widget.controller.selectTrip(value);
                      if (mounted) setState(() => selectedTripId = value);
                    },
                  ),
                  const SizedBox(height: 12),
"""
if body_selector not in text:
    raise SystemExit('records body selector target not found')
text = text.replace(body_selector, '', 1)
records.write_text(text)

settlement = Path('lib/screens/settlement_screen.dart')
s = settlement.read_text()
new_refund = r'''  Future<void> _refundFund(_SettlementViewData data) async {
    if (data.members.isEmpty || data.ledger.fundBalanceMinor <= 0) return;

    final mode = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('公基金退款方式', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('目前餘額：${MoneyText.formatMinor(data.ledger.fundBalanceMinor, data.ledger.currency)}'),
              const SizedBox(height: 14),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const CircleAvatar(child: Icon(Icons.balance_rounded)),
                title: const Text('一鍵平均退款', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('將目前公基金餘額平均退給所有旅伴'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheetContext, 'average'),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const CircleAvatar(child: Icon(Icons.edit_outlined)),
                title: const Text('自行輸入退款', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('自行指定每位旅伴的退款金額，可部分退款'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(sheetContext, 'custom'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mode == null) return;

    if (mode == 'average') {
      final total = data.ledger.fundBalanceMinor;
      final count = data.members.length;
      final base = total ~/ count;
      final remainder = total % count;
      final allocations = <int>[
        for (var i = 0; i < count; i++) base + (i < remainder ? 1 : 0),
      ];

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('確認平均退款'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < data.members.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(data.members[i].displayName),
                      trailing: Text(
                        MoneyText.formatMinor(allocations[i], data.ledger.currency),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(child: Text('退款總額', style: TextStyle(fontWeight: FontWeight.w800))),
                      Text(
                        MoneyText.formatMinor(total, data.ledger.currency),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('平均退款')),
          ],
        ),
      );
      if (confirmed != true) return;

      try {
        for (var i = 0; i < data.members.length; i++) {
          final amount = allocations[i];
          if (amount <= 0) continue;
          await widget.controller.services.fund.refund(
            tripId: data.trip.id,
            memberId: data.members[i].id,
            amountMinor: amount,
            note: '結算頁平均退款',
          );
        }
        if (mounted) setState(() => refresh++);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }

    final amountTextByMember = <String, String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('自行輸入退款'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('可退款上限：${MoneyText.formatMinor(data.ledger.fundBalanceMinor, data.ledger.currency)}'),
                  const SizedBox(height: 12),
                  for (final member in data.members) ...[
                    TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: member.displayName, suffixText: data.ledger.currency, hintText: '0'),
                      onChanged: (value) {
                        amountTextByMember[member.id] = value;
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '已輸入：${MoneyText.formatMinor(_customRefundTotal(data, amountTextByMember), data.ledger.currency)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('退款')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final parsed = <String, int>{};
    var total = 0;
    for (final member in data.members) {
      final raw = amountTextByMember[member.id]?.trim() ?? '';
      if (raw.isEmpty) continue;
      final amount = MoneyInput.parseMajorToMinor(raw, data.ledger.currency);
      if (amount == null || amount < 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${member.displayName} 的退款金額無效')));
        return;
      }
      if (amount == 0) continue;
      parsed[member.id] = amount;
      total += amount;
    }
    if (total <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請至少輸入一筆退款金額')));
      return;
    }
    if (total > data.ledger.fundBalanceMinor) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('退款總額不可超過公基金餘額')));
      return;
    }

    try {
      for (final member in data.members) {
        final amount = parsed[member.id] ?? 0;
        if (amount <= 0) continue;
        await widget.controller.services.fund.refund(
          tripId: data.trip.id,
          memberId: member.id,
          amountMinor: amount,
          note: '結算頁自訂退款',
        );
      }
      if (mounted) setState(() => refresh++);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  int _customRefundTotal(_SettlementViewData data, Map<String, String> values) {
    var total = 0;
    for (final raw in values.values) {
      final text = raw.trim();
      if (text.isEmpty) continue;
      final amount = MoneyInput.parseMajorToMinor(text, data.ledger.currency);
      if (amount != null && amount > 0) total += amount;
    }
    return total;
  }

'''
pattern = r"  Future<void> _refundFund\(_SettlementViewData data\) async \{.*?^  Future<void> _shareImage"
match = re.search(pattern, s, flags=re.S | re.M)
if not match:
    raise SystemExit('settlement refund target not found')
s = s[:match.start()] + new_refund + '  Future<void> _shareImage' + s[match.end():]
settlement.write_text(s)
