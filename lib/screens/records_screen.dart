import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../domain/money_text.dart';
import '../localization/app_strings.dart';
import '../widgets/category_icon.dart';
import 'add_expense_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String? selectedTripId;
  bool showStats = false;

  @override
  void initState() {
    super.initState();
    selectedTripId = widget.controller.selectedTripId;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.controller.languageCode);
    return StreamBuilder<List<TripRow>>(
      stream: widget.controller.services.repository.watchTrips(),
      builder: (context, tripsSnapshot) {
        final trips = tripsSnapshot.data ?? const <TripRow>[];
        if (trips.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(strings.t('expenseRecords'))),
            body: Center(child: Text(strings.t('noTrips'))),
          );
        }

        final effectiveTripId = trips.any((t) => t.id == selectedTripId)
            ? selectedTripId!
            : (trips.any((t) => t.id == widget.controller.selectedTripId)
                ? widget.controller.selectedTripId!
                : trips.first.id);
        final trip = trips.firstWhere((t) => t.id == effectiveTripId);
        if (selectedTripId != effectiveTripId) selectedTripId = effectiveTripId;

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.t('expenseRecords'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: StreamBuilder<List<ExpenseRow>>(
            stream: widget.controller.services.repository.watchExpenses(effectiveTripId),
            builder: (context, expensesSnapshot) {
              final expenses = expensesSnapshot.data ?? const <ExpenseRow>[];
              final total = expenses.fold<int>(0, (sum, e) => sum + e.baseAmountMinor);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  DropdownButtonFormField<String>(
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(child: _summaryMetric('支出筆數', '${expenses.length} 筆')),
                          Expanded(child: _summaryMetric('總支出', MoneyText.formatMinor(total, trip.baseCurrency))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(controller: widget.controller, initialTripId: effectiveTripId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('新增支出'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, icon: Icon(Icons.receipt_long_outlined), label: Text('明細')),
                      ButtonSegment(value: true, icon: Icon(Icons.bar_chart_rounded), label: Text('統計')),
                    ],
                    selected: {showStats},
                    onSelectionChanged: (value) => setState(() => showStats = value.first),
                  ),
                  const SizedBox(height: 14),
                  if (showStats)
                    FutureBuilder<List<MemberRow>>(
                      future: widget.controller.services.repository.getMembers(effectiveTripId),
                      builder: (context, membersSnapshot) => _buildStats(
                        context,
                        trip,
                        expenses,
                        membersSnapshot.data ?? const <MemberRow>[],
                      ),
                    )
                  else if (expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text(strings.t('noExpenses'))),
                    )
                  else
                    ...[
                      for (final expense in expenses) ...[
                        _expenseCard(context, expense),
                        const SizedBox(height: 9),
                      ],
                    ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _expenseCard(BuildContext context, ExpenseRow expense) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                controller: widget.controller,
                initialTripId: expense.tripId,
                expenseId: expense.id,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: const Color(0xFFE8F4F2), borderRadius: BorderRadius.circular(15)),
                  child: Icon(categoryIcon(expense.categoryKey)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title.trim().isEmpty ? categoryLabel(expense.categoryKey) : expense.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${categoryLabel(expense.categoryKey)} · ${expense.occurredAt.year}/${expense.occurredAt.month}/${expense.occurredAt.day}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MoneyText.formatMinor(expense.originalAmountMinor, expense.originalCurrency),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (expense.originalCurrency != expense.baseCurrency)
                      Text(
                        '≈ ${MoneyText.formatMinor(expense.baseAmountMinor, expense.baseCurrency)}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                  ],
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      );

  Widget _buildStats(BuildContext context, TripRow trip, List<ExpenseRow> expenses, List<MemberRow> members) {
    final byMember = <String, int>{for (final m in members) m.id: 0};
    var fundPaid = 0;
    final byCategory = <String, int>{};
    final byDate = <String, int>{};
    for (final e in expenses) {
      if (e.payerType == 'FUND') {
        fundPaid += e.baseAmountMinor;
      } else if (e.payerMemberId != null) {
        byMember[e.payerMemberId!] = (byMember[e.payerMemberId!] ?? 0) + e.baseAmountMinor;
      }
      byCategory[e.categoryKey] = (byCategory[e.categoryKey] ?? 0) + e.baseAmountMinor;
      final key = '${e.occurredAt.year}/${e.occurredAt.month.toString().padLeft(2, '0')}/${e.occurredAt.day.toString().padLeft(2, '0')}';
      byDate[key] = (byDate[key] ?? 0) + e.baseAmountMinor;
    }
    final categoryEntries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final dateEntries = byDate.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: [
        _statCard(
          '依旅伴付款',
          [
            for (final m in members) MapEntry(m.displayName, byMember[m.id] ?? 0),
            MapEntry('公基金', fundPaid),
          ],
          trip.baseCurrency,
        ),
        const SizedBox(height: 10),
        _statCard(
          '依類別',
          [for (final e in categoryEntries) MapEntry(categoryLabel(e.key), e.value)],
          trip.baseCurrency,
        ),
        const SizedBox(height: 10),
        _statCard('依日期', dateEntries, trip.baseCurrency),
        const SizedBox(height: 10),
        _statCard(
          '付款來源',
          [
            MapEntry('個人付款', byMember.values.fold<int>(0, (a, b) => a + b)),
            MapEntry('公基金', fundPaid),
          ],
          trip.baseCurrency,
        ),
      ],
    );
  }

  Widget _statCard(String title, List<MapEntry<String, int>> rows, String currency) {
    final nonZero = rows.where((e) => e.value != 0).toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 12),
            if (nonZero.isEmpty)
              const Text('尚無資料', style: TextStyle(color: Colors.black54))
            else
              for (final row in nonZero)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.key)),
                      Text(MoneyText.formatMinor(row.value, currency), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      );
}
