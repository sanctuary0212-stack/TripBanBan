import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../domain/currency_catalog.dart';
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
        if (!snapshot.hasData) {
          return Scaffold(appBar: AppBar(title: Text(strings.t('settlement'))), body: const Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data!;
        final ledger = data.ledger;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 82,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.t('settlement'), style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: data.trip.id,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    items: [
                      for (final trip in data.trips)
                        DropdownMenuItem<String>(
                          value: trip.id,
                          child: Text(trip.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) async {
                      if (value == null || value == data.trip.id) return;
                      await widget.controller.selectTrip(value);
                      if (mounted) setState(() => refresh++);
                    },
                  ),
                ),
              ],
            ),
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
                      Text(strings.t('totalExpense'), style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        MoneyText.formatMinor(ledger.totalExpenseMinor, ledger.currency),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(_statusLabel(ledger.status, strings))),
                          if (ledger.fundBalanceMinor != 0)
                            Chip(
                              avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                              label: Text('${strings.t('publicFund')} ${MoneyText.formatMinor(ledger.fundBalanceMinor, ledger.currency)}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _memberStatsSection(data, strings),
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
                            label: Text('${strings.t('fundRefund')} · ${MoneyText.formatMinor(ledger.fundBalanceMinor, ledger.currency)}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _transferSuggestions(data, strings),
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

  Widget _memberStatsSection(_SettlementViewData data, AppStrings strings) {
    final ledger = data.ledger;
    final headerStyle = TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    const valueStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w800);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${strings.t('memberStats')} (${ledger.currency})',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 14),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.35),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    const SizedBox(),
                    _tableText(strings.t('paid'), headerStyle),
                    _tableText(strings.t('shouldShare'), headerStyle),
                    _tableText(strings.t('net'), headerStyle),
                  ],
                ),
                for (final balance in ledger.balances)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
                        child: Text(data.memberName(balance.memberId), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      _tableText(_minorValue(balance.paidMinor + balance.fundNetContributionMinor, ledger.currency), valueStyle),
                      _tableText(_minorValue(balance.shareMinor, ledger.currency), valueStyle),
                      _tableText(_minorValue(balance.netMinor, ledger.currency), valueStyle),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableText(String text, TextStyle style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(text, textAlign: TextAlign.right, style: style),
      );

  Widget _transferSuggestions(_SettlementViewData data, AppStrings strings) {
    final ledger = data.ledger;
    final children = <Widget>[];
    if (ledger.suggestedTransfers.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('目前沒有待轉帳款項。'),
      ));
    } else {
      for (final transfer in ledger.suggestedTransfers) {
        final from = data.memberName(transfer.fromMemberId);
        final to = data.memberName(transfer.toMemberId);
        children.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
            title: Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('建議 $from 給 $to ${MoneyText.formatMinor(transfer.amountMinor, ledger.currency)}'),
            trailing: FilledButton.tonal(
              onPressed: () => _markPaid(data, transfer),
              child: Text(strings.t('markPaid')),
            ),
          ),
        );
      }
    }
    return _section(strings.t('whoPaysWhom'), children);
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

  String _statusLabel(TripAccountingStatus status, AppStrings strings) => switch (status) {
        TripAccountingStatus.notStarted => strings.t('notStarted'),
        TripAccountingStatus.pendingSettlement => strings.t('pending'),
        TripAccountingStatus.settled => strings.t('settled'),
      };

  String _minorValue(int minor, String currency) {
    final info = CurrencyCatalog.find(currency);
    final digits = info?.decimalPlaces ?? 2;
    var divisor = 1;
    for (var i = 0; i < digits; i++) {
      divisor *= 10;
    }
    final format = NumberFormat.decimalPattern(_intlLocale())
      ..minimumFractionDigits = digits
      ..maximumFractionDigits = digits;
    return format.format(minor / divisor);
  }

  Future<_SettlementViewData> _load(String tripId) async {
    final trips = await widget.controller.services.repository.watchTrips().first;
    final trip = await widget.controller.services.repository.getTrip(tripId);
    if (trip == null) throw StateError('Trip not found');
    final members = await widget.controller.services.repository.getMembers(tripId);
    final ledger = await widget.controller.services.ledger.calculate(tripId);
    return _SettlementViewData(trip: trip, trips: trips, members: members, ledger: ledger);
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
        'fr' => 'fr_FR',
        'de' => 'de_DE',
        'es' => 'es_ES',
        'it' => 'it_IT',
        'th' => 'th_TH',
        'en' => 'en_US',
        _ => 'zh_TW',
      };
}

class _SettlementViewData {
  const _SettlementViewData({
    required this.trip,
    required this.trips,
    required this.members,
    required this.ledger,
  });

  final TripRow trip;
  final List<TripRow> trips;
  final List<MemberRow> members;
  final LedgerSnapshot ledger;

  String memberName(String id) => members.where((m) => m.id == id).map((m) => m.displayName).firstOrNull ?? id;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
