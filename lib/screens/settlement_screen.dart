import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../domain/ledger_models.dart';
import '../domain/money_input.dart';
import '../domain/money_text.dart';
import '../localization/app_strings.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  int refresh = 0;
  bool sharing = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.controller.languageCode);
    final tripId = widget.controller.selectedTripId;
    if (tripId == null) {
      return Scaffold(appBar: AppBar(title: Text(strings.t('settlement'))), body: Center(child: Text(strings.t('noTrips'))));
    }
    return FutureBuilder<_SettlementViewData>(
      key: ValueKey('$tripId-$refresh'),
      future: _load(tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Scaffold(appBar: AppBar(title: Text(strings.t('settlement'))), body: const Center(child: CircularProgressIndicator()));
        final data = snapshot.data!;
        final ledger = data.ledger;
        return Scaffold(
          appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(strings.t('settlement'), style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(data.trip.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            ]),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('旅行總花費', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(MoneyText.formatMinor(ledger.totalExpenseMinor, ledger.currency), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(_statusLabel(ledger.status))),
                          if (ledger.fundBalanceMinor != 0)
                            Chip(avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18), label: Text('公基金 ${MoneyText.formatMinor(ledger.fundBalanceMinor, ledger.currency)}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _section(
                strings.t('whoPaysWhom'),
                ledger.suggestedTransfers.isEmpty
                    ? [const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('目前沒有待轉帳款項。'))]
                    : [
                        for (final transfer in ledger.suggestedTransfers)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(child: Icon(Icons.arrow_forward)),
                            title: Text('${data.memberName(transfer.fromMemberId)} → ${data.memberName(transfer.toMemberId)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(MoneyText.formatMinor(transfer.amountMinor, ledger.currency)),
                            trailing: FilledButton.tonal(
                              onPressed: () => _markPaid(data, transfer),
                              child: Text(strings.t('markPaid')),
                            ),
                          ),
                      ],
              ),
              const SizedBox(height: 12),
              _section(
                strings.t('memberStats'),
                [
                  for (final balance in ledger.balances)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(data.memberName(balance.memberId), style: const TextStyle(fontWeight: FontWeight.w700))),
                          Expanded(child: _miniStat(strings.t('paid'), MoneyText.formatMinor(balance.paidMinor + balance.fundNetContributionMinor, ledger.currency))),
                          Expanded(child: _miniStat(strings.t('shouldShare'), MoneyText.formatMinor(balance.shareMinor, ledger.currency))),
                          Expanded(child: _miniStat(strings.t('net'), MoneyText.formatMinor(balance.netMinor, ledger.currency))),
                        ],
                      ),
                    ),
                ],
              ),
              if (ledger.fundBalanceMinor > 0) ...[
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFFFFF5E6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 10),
                            Expanded(child: Text(strings.t('fundNeedsRefund'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _refundFund(data),
                            icon: const Icon(Icons.undo_rounded),
                            label: Text('公基金退款 · ${MoneyText.formatMinor(ledger.fundBalanceMinor, ledger.currency)}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: sharing ? null : () => _shareImage(data),
                icon: const Icon(Icons.image_outlined),
                label: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Text(strings.t('shareSettlement'))),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: sharing ? null : () => _shareCsv(data.trip.id, data.trip.name),
                icon: const Icon(Icons.table_view_outlined),
                label: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Text(strings.t('shareCsv'))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 10),
            ...children,
          ]),
        ),
      );

  Widget _miniStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)), Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.end)],
      );

  String _statusLabel(TripAccountingStatus status) => switch (status) {
        TripAccountingStatus.notStarted => '未開始',
        TripAccountingStatus.pendingSettlement => '待結算',
        TripAccountingStatus.settled => '已結清',
      };

  Future<_SettlementViewData> _load(String tripId) async {
    final trip = await widget.controller.services.repository.getTrip(tripId);
    if (trip == null) throw StateError('Trip not found');
    final members = await widget.controller.services.repository.getMembers(tripId);
    final ledger = await widget.controller.services.ledger.calculate(tripId);
    return _SettlementViewData(trip: trip, members: members, ledger: ledger);
  }

  Future<void> _markPaid(_SettlementViewData data, SuggestedTransfer transfer) async {
    await widget.controller.services.repository.addSettlementPayment(
      tripId: data.trip.id,
      fromMemberId: transfer.fromMemberId,
      toMemberId: transfer.toMemberId,
      amountMinor: transfer.amountMinor,
      currency: data.trip.baseCurrency,
    );
    if (mounted) setState(() => refresh++);
  }

  Future<void> _refundFund(_SettlementViewData data) async {
    if (data.members.isEmpty || data.ledger.fundBalanceMinor <= 0) return;
    var memberId = data.members.first.id;
    var amountText = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('公基金退款'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('目前餘額：${MoneyText.formatMinor(data.ledger.fundBalanceMinor, data.ledger.currency)}'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: memberId,
                items: [for (final member in data.members) DropdownMenuItem(value: member.id, child: Text(member.displayName))],
                onChanged: (value) => setDialogState(() => memberId = value ?? memberId),
                decoration: const InputDecoration(labelText: '退款給'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '退款金額 (${data.ledger.currency})'),
                onChanged: (value) => amountText = value,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('退款')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final amountMinor = MoneyInput.parseMajorToMinor(amountText, data.ledger.currency);
    if (amountMinor == null || amountMinor <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入有效退款金額')));
      return;
    }
    try {
      await widget.controller.services.fund.refund(
        tripId: data.trip.id,
        memberId: memberId,
        amountMinor: amountMinor,
        note: '結算頁公基金退款',
      );
      if (mounted) setState(() => refresh++);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _shareImage(_SettlementViewData data) async {
    setState(() => sharing = true);
    try {
      final report = await widget.controller.services.reportFactory.settlementReport(data.trip.id);
      final image = await widget.controller.services.settlementImage.render(report, locale: _intlLocale());
      await widget.controller.services.share.shareFiles(
        [image],
        title: '${data.trip.name} 結算',
        text: '旅行伴伴 TripBanBan · ${data.trip.name} 結算清單',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  Future<void> _shareCsv(String tripId, String name) async {
    setState(() => sharing = true);
    try {
      final files = await widget.controller.services.csv.exportTrip(tripId);
      await widget.controller.services.share.shareFiles(files, title: '$name CSV', text: 'TripBanBan 支出明細');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  String _intlLocale() => switch (widget.controller.languageCode) {
        'zh_Hans' => 'zh_CN',
        'ja' => 'ja_JP',
        'ko' => 'ko_KR',
        'en' => 'en_US',
        _ => 'zh_TW',
      };
}

class _SettlementViewData {
  const _SettlementViewData({required this.trip, required this.members, required this.ledger});
  final TripRow trip;
  final List<MemberRow> members;
  final LedgerSnapshot ledger;

  String memberName(String id) => members.where((m) => m.id == id).map((m) => m.displayName).firstOrNull ?? id;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
