import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../domain/ledger_models.dart';
import '../domain/money_input.dart';
import '../domain/money_text.dart';
import '../widgets/category_icon.dart';
import 'add_expense_screen.dart';
import 'manage_members_screen.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.controller, required this.tripId});
  final AppController controller;
  final String tripId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int refresh = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TripRow?>(
      future: widget.controller.services.repository.getTrip(widget.tripId),
      builder: (context, tripSnapshot) {
        final trip = tripSnapshot.data;
        if (trip == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return Scaffold(
          appBar: AppBar(title: Text(trip.name)),
          body: FutureBuilder<LedgerSnapshot>(
            key: ValueKey(refresh),
            future: widget.controller.services.ledger.calculate(trip.id),
            builder: (context, ledgerSnapshot) {
              final ledger = ledgerSnapshot.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _TravelHeroCard(trip: trip, ledger: ledger),
                  const SizedBox(height: 12),
                  StreamBuilder<List<MemberRow>>(
                    stream: widget.controller.services.repository.watchMembers(trip.id),
                    builder: (context, membersSnapshot) {
                      final members = membersSnapshot.data ?? const <MemberRow>[];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('旅伴', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ManageMembersScreen(controller: widget.controller, tripId: trip.id),
                                      ),
                                    ),
                                    icon: const Icon(Icons.group_outlined),
                                    label: const Text('管理旅伴'),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [for (final member in members) Chip(label: Text(member.displayName))],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _FundCard(controller: widget.controller, trip: trip, ledger: ledger),
                  const SizedBox(height: 12),
                  _TripExpenseSummary(controller: widget.controller, trip: trip),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(controller: widget.controller, initialTripId: trip.id),
                        ),
                      );
                      if (mounted) setState(() => refresh++);
                    },
                    icon: const Icon(Icons.add),
                    label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('新增支出')),
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('旅程專案管理', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    onPressed: () => _deleteTrip(trip),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('刪除旅程'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _fundAction(TripRow trip, {required bool refund}) async {
    final members = await widget.controller.services.repository.getMembers(trip.id);
    if (!mounted || members.isEmpty) return;

    var memberId = members.first.id;
    var amountText = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(refund ? '公基金退款' : '繳入公基金'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: memberId,
                items: [for (final m in members) DropdownMenuItem(value: m.id, child: Text(m.displayName))],
                onChanged: (value) => setDialogState(() => memberId = value ?? memberId),
                decoration: const InputDecoration(labelText: '旅伴'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '金額 (${trip.baseCurrency})'),
                onChanged: (value) => amountText = value,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('儲存')),
          ],
        ),
      ),
    );
    if (result != true) return;

    final minor = MoneyInput.parseMajorToMinor(amountText, trip.baseCurrency);
    if (minor == null || minor <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入有效金額')));
      return;
    }

    try {
      if (refund) {
        await widget.controller.services.fund.refund(tripId: trip.id, memberId: memberId, amountMinor: minor);
      } else {
        await widget.controller.services.fund.contribute(tripId: trip.id, memberId: memberId, amountMinor: minor);
      }
      if (mounted) setState(() => refresh++);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteTrip(TripRow trip) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久刪除旅程？'),
        content: Text('「${trip.name}」的支出、公基金、照片與結算紀錄都會刪除。建議先匯出備份。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('永久刪除')),
        ],
      ),
    );
    if (yes != true) return;
    await widget.controller.services.trips.deleteTripCompletely(trip.id);
    await widget.controller.onTripDeleted(trip.id);
    if (mounted) Navigator.pop(context);
  }
}

class _FundCard extends StatelessWidget {
  const _FundCard({required this.controller, required this.trip, required this.ledger});
  final AppController controller;
  final TripRow trip;
  final LedgerSnapshot? ledger;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MemberRow>>(
      stream: controller.services.repository.watchMembers(trip.id),
      builder: (context, membersSnapshot) {
        final members = membersSnapshot.data ?? const <MemberRow>[];
        return StreamBuilder<List<FundTransactionRow>>(
          stream: controller.services.repository.watchFundTransactions(trip.id),
          builder: (context, fundSnapshot) {
            final transactions = fundSnapshot.data ?? const <FundTransactionRow>[];
            final netByMember = <String, int>{for (final member in members) member.id: 0};
            for (final tx in transactions) {
              final memberId = tx.memberId;
              if (memberId == null || !netByMember.containsKey(memberId)) continue;
              if (tx.type == 'CONTRIBUTION') {
                netByMember[memberId] = netByMember[memberId]! + tx.amountMinor;
              } else if (tx.type == 'REFUND') {
                netByMember[memberId] = netByMember[memberId]! - tx.amountMinor;
              }
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('公基金', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 12),
                    if (ledger != null)
                      Text(
                        MoneyText.formatMinor(ledger!.fundBalanceMinor, trip.baseCurrency),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    if (members.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('每人匯入（繳入－退款）', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54)),
                      const SizedBox(height: 8),
                      for (final member in members)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(member.displayName)),
                              Text(
                                MoneyText.formatMinor(netByMember[member.id] ?? 0, trip.baseCurrency),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => (context.findAncestorStateOfType<_TripDetailScreenState>())?._fundAction(trip, refund: false),
                            icon: const Icon(Icons.add),
                            label: const Text('繳入 / 補充'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => (context.findAncestorStateOfType<_TripDetailScreenState>())?._fundAction(trip, refund: true),
                            icon: const Icon(Icons.undo),
                            label: const Text('退款'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TripExpenseSummary extends StatelessWidget {
  const _TripExpenseSummary({required this.controller, required this.trip});
  final AppController controller;
  final TripRow trip;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ExpenseRow>>(
      stream: controller.services.repository.watchExpenses(trip.id),
      builder: (context, expensesSnapshot) {
        final expenses = expensesSnapshot.data ?? const <ExpenseRow>[];
        return FutureBuilder<List<MemberRow>>(
          future: controller.services.repository.getMembers(trip.id),
          builder: (context, membersSnapshot) {
            final members = membersSnapshot.data ?? const <MemberRow>[];
            final total = expenses.fold<int>(0, (sum, e) => sum + e.baseAmountMinor);
            final average = members.isEmpty ? 0 : (total / members.length).round();
            final byCategory = <String, int>{};
            for (final e in expenses) {
              byCategory[e.categoryKey] = (byCategory[e.categoryKey] ?? 0) + e.baseAmountMinor;
            }
            String topCategory = '—';
            if (byCategory.isNotEmpty) {
              final top = byCategory.entries.reduce((a, b) => a.value >= b.value ? a : b);
              topCategory = categoryLabel(top.key);
            }
            final latest = expenses.isEmpty ? null : expenses.first;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本專案支出 Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _summaryMetric('總支出', MoneyText.formatMinor(total, trip.baseCurrency))),
                        Expanded(child: _summaryMetric('支出筆數', '${expenses.length} 筆')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _summaryMetric('平均每人', MoneyText.formatMinor(average, trip.baseCurrency))),
                        Expanded(child: _summaryMetric('最高類別', topCategory)),
                      ],
                    ),
                    if (latest != null) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.history, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '最近：${latest.title.trim().isEmpty ? categoryLabel(latest.categoryKey) : latest.title}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(MoneyText.formatMinor(latest.baseAmountMinor, trip.baseCurrency), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _summaryMetric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        ],
      );
}

class _TravelHeroCard extends StatelessWidget {
  const _TravelHeroCard({required this.trip, required this.ledger});
  final TripRow trip;
  final LedgerSnapshot? ledger;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(minHeight: 210),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF087F73), Color(0xFF24B8B1), Color(0xFF78D9CF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -34, top: -42, child: _bubble(150, const Color(0x33FFF3B0))),
            Positioned(left: -44, bottom: -58, child: _bubble(190, const Color(0x22005262))),
            Positioned(right: 18, bottom: 10, child: _bubble(86, const Color(0x22FFFFFF))),
            Positioned(
              right: 30,
              top: 22,
              child: Transform.rotate(
                angle: -math.pi / 9,
                child: const Icon(Icons.flight_rounded, size: 78, color: Color(0x55FFFFFF)),
              ),
            ),
            const Positioned(right: 22, bottom: 24, child: Icon(Icons.location_on_rounded, size: 64, color: Color(0x44FFFFFF))),
            const Positioned(right: 106, bottom: 34, child: Icon(Icons.luggage_rounded, size: 42, color: Color(0x33FFFFFF))),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: Colors.white70, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        '${trip.destination ?? '旅行專案'} · ${trip.baseCurrency}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (ledger != null) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(child: _metric('總支出', MoneyText.formatMinor(ledger!.totalExpenseMinor, trip.baseCurrency))),
                        const SizedBox(width: 12),
                        Expanded(child: _metric('公基金餘額', MoneyText.formatMinor(ledger!.fundBalanceMinor, trip.baseCurrency))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bubble(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  static Widget _metric(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}
