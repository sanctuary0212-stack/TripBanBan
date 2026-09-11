import 'dart:async';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../domain/money_input.dart';
import '../domain/money_text.dart';
import '../features/expenses/expense_application_service.dart';
import '../platform/attachment_storage_service.dart';
import '../widgets/category_icon.dart';
import '../widgets/currency_picker.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.controller,
    required this.initialTripId,
    this.expenseId,
  });

  final AppController controller;
  final String initialTripId;
  final String? expenseId;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountController = TextEditingController();
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final manualRateController = TextEditingController();
  final customControllers = <String, TextEditingController>{};
  final percentageControllers = <String, TextEditingController>{};

  late String tripId;
  String currency = 'TWD';
  String payerType = 'MEMBER';
  String? payerMemberId;
  String categoryKey = 'FOOD';
  String? customCategoryId;
  DateTime occurredAt = DateTime.now();
  ExpenseSplitMode splitMode = ExpenseSplitMode.equal;
  final selectedMemberIds = <String>{};
  final stagedAttachments = <StagedAttachment>[];
  List<AttachmentRow> existingAttachments = const [];

  TripRow? trip;
  List<TripRow> trips = const [];
  List<MemberRow> members = const [];
  List<CustomCategoryRow> customCategories = const [];
  int? previewBaseMinor;
  String? previewRate;
  String? previewRateSource;
  bool manualRate = false;
  bool loading = true;
  bool saving = false;
  bool dirty = false;
  int previewGeneration = 0;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    tripId = widget.initialTripId;
    amountController.addListener(_amountChanged);
    manualRateController.addListener(_amountChanged);
    titleController.addListener(_markDirty);
    noteController.addListener(_markDirty);
    _load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    amountController.dispose();
    titleController.dispose();
    noteController.dispose();
    manualRateController.dispose();
    for (final c in customControllers.values) c.dispose();
    for (final c in percentageControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    trips = await widget.controller.services.repository.watchTrips().first;
    await _loadTrip(tripId, resetSelections: true);
    if (widget.expenseId != null) await _loadExisting(widget.expenseId!);
    if (mounted) setState(() { loading = false; dirty = false; });
    await _refreshPreview();
  }

  Future<void> _loadTrip(String nextTripId, {required bool resetSelections}) async {
    final nextTrip = await widget.controller.services.repository.getTrip(nextTripId);
    if (nextTrip == null) return;
    final nextMembers = await widget.controller.services.repository.getMembers(nextTripId);
    final categories = await widget.controller.services.repository.getCustomCategories(nextTripId);
    tripId = nextTripId;
    trip = nextTrip;
    members = nextMembers;
    customCategories = categories;
    if (resetSelections) {
      currency = nextTrip.baseCurrency;
      selectedMemberIds
        ..clear()
        ..addAll(nextMembers.map((e) => e.id));
      payerMemberId = nextMembers.isEmpty ? null : nextMembers.first.id;
      payerType = 'MEMBER';
      _resetSplitControllers();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadExisting(String expenseId) async {
    final expense = await widget.controller.services.repository.getExpense(expenseId);
    if (expense == null) return;
    if (expense.tripId != tripId) await _loadTrip(expense.tripId, resetSelections: false);
    final shares = await widget.controller.services.repository.getExpenseShares(expense.id);
    titleController.text = expense.title;
    noteController.text = expense.note ?? '';
    amountController.text = MoneyInput.minorToMajorText(expense.originalAmountMinor, expense.originalCurrency);
    currency = expense.originalCurrency;
    payerType = expense.payerType;
    payerMemberId = expense.payerMemberId;
    categoryKey = expense.categoryKey;
    customCategoryId = expense.customCategoryId;
    occurredAt = expense.occurredAt;
    previewBaseMinor = expense.baseAmountMinor;
    previewRate = expense.exchangeRateText;
    previewRateSource = expense.exchangeRateSource;
    if (expense.originalCurrency != expense.baseCurrency) {
      manualRate = true;
      manualRateController.text = expense.exchangeRateText;
    }
    selectedMemberIds
      ..clear()
      ..addAll(shares.map((e) => e.memberId));
    final mode = shares.isEmpty ? 'EQUAL' : shares.first.mode;
    splitMode = switch (mode) {
      'CUSTOM' => ExpenseSplitMode.customAmount,
      'PERCENTAGE' => ExpenseSplitMode.percentage,
      _ => ExpenseSplitMode.equal,
    };
    _resetSplitControllers();
    for (final share in shares) {
      if (splitMode == ExpenseSplitMode.customAmount) {
        customControllers[share.memberId]?.text = MoneyInput.minorToMajorText(share.amountMinor, trip!.baseCurrency);
      } else if (splitMode == ExpenseSplitMode.percentage) {
        percentageControllers[share.memberId]?.text = share.ratioText ?? '';
      }
    }
    existingAttachments = await widget.controller.services.attachments.attachmentsForExpense(expense.id);
  }

  void _resetSplitControllers() {
    for (final c in customControllers.values) c.dispose();
    for (final c in percentageControllers.values) c.dispose();
    customControllers.clear();
    percentageControllers.clear();
    for (final member in members) {
      customControllers[member.id] = TextEditingController()..addListener(_splitInputChanged);
      percentageControllers[member.id] = TextEditingController()..addListener(_splitInputChanged);
    }
  }

  void _amountChanged() {
    _markDirty();
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 220), _refreshPreview);
  }

  void _splitInputChanged() {
    _markDirty();
    if (mounted) setState(() {});
  }

  void _markDirty() {
    if (!loading && !saving && !dirty && mounted) {
      setState(() => dirty = true);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!dirty) return true;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放棄未儲存的變更？'),
        content: const Text('目前輸入的支出內容尚未儲存。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('繼續編輯')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('放棄變更')),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _requestClose() async {
    if (saving) return;
    if (!await _confirmDiscard() || !mounted) return;
    setState(() => dirty = false);
    Navigator.pop(context);
  }

  int? get originalMinor => MoneyInput.parseMajorToMinor(amountController.text, currency);

  Map<String, int> get customMinorByMember {
    final base = trip?.baseCurrency ?? 'TWD';
    return {
      for (final id in selectedMemberIds)
        if (MoneyInput.parseMajorToMinor(customControllers[id]?.text ?? '', base) case final int value) id: value,
    };
  }

  Map<String, String> get percentageByMember => {
        for (final id in selectedMemberIds) id: percentageControllers[id]?.text.trim() ?? '',
      };

  Future<void> _refreshPreview() async {
    final currentTrip = trip;
    final minor = originalMinor;
    if (currentTrip == null || minor == null || minor <= 0 || selectedMemberIds.isEmpty) {
      if (mounted) setState(() => previewBaseMinor = null);
      return;
    }
    final generation = ++previewGeneration;
    try {
      final prepared = await widget.controller.services.expenses.prepare(
        ExpenseSaveRequest(
          expenseId: widget.expenseId,
          tripId: tripId,
          title: titleController.text,
          note: noteController.text,
          originalAmountMinor: minor,
          originalCurrency: currency,
          payerType: payerType,
          payerMemberId: payerMemberId,
          categoryKey: categoryKey,
          customCategoryId: customCategoryId,
          occurredAt: occurredAt,
          selectedMemberIds: selectedMemberIds.toList(),
          splitMode: ExpenseSplitMode.equal,
          manualRateText: manualRate ? manualRateController.text : null,
        ),
      );
      if (!mounted || generation != previewGeneration) return;
      setState(() {
        previewBaseMinor = prepared.baseAmountMinor;
        previewRate = prepared.exchangeRateText;
        previewRateSource = prepared.exchangeRateSource;
      });
    } catch (_) {
      if (mounted && generation == previewGeneration) setState(() => previewBaseMinor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final currentTrip = trip;
    if (currentTrip == null) return const Scaffold(body: Center(child: Text('找不到旅程')));
    final selectedMembers = members.where((m) => selectedMemberIds.contains(m.id)).toList(growable: false);

    return PopScope(
      canPop: !saving && !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && dirty) await _requestClose();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: saving ? null : _requestClose),
          title: Text(widget.expenseId == null ? '新增支出' : '編輯支出'),
          actions: [
            if (widget.expenseId != null)
              IconButton(onPressed: _deleteExpense, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
          children: [
            _section('旅程專案', [
              DropdownButtonFormField<String>(
                value: tripId,
                items: [for (final item in trips) DropdownMenuItem(value: item.id, child: Text('${item.name} · ${item.baseCurrency}'))],
                onChanged: widget.expenseId != null
                    ? null
                    : (value) async {
                        if (value == null || value == tripId) return;
                        if (!await _confirmDiscard() || !mounted) return;
                        setState(() => dirty = false);
                        await widget.controller.selectTrip(value);
                        await _loadTrip(value, resetSelections: true);
                        if (mounted) setState(() => dirty = false);
                        await _refreshPreview();
                      },
              ),
            ]),
            _section('金額', [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(hintText: '0'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final next = await showCurrencyPicker(context, selected: currency, title: '支出幣別');
                      if (next != null) {
                        setState(() { currency = next; dirty = true; });
                        await _refreshPreview();
                      }
                    },
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(currency)),
                  ),
                ],
              ),
              if (currency != currentTrip.baseCurrency) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        previewBaseMinor == null
                            ? '等待匯率或請手動輸入'
                            : '≈ ${MoneyText.formatMinor(previewBaseMinor!, currentTrip.baseCurrency)} · 匯率 ${previewRate ?? '-'}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    Switch(value: manualRate, onChanged: (value) => setState(() { manualRate = value; dirty = true; _refreshPreview(); })),
                    const Text('手動'),
                  ],
                ),
                if (manualRate)
                  TextField(
                    controller: manualRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: '1 $currency = ? ${currentTrip.baseCurrency}'),
                  )
                else if (previewRateSource != null)
                  Text('來源：$previewRateSource', style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ]),
            _section('誰付款？', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('公基金'),
                    selected: payerType == 'FUND',
                    onSelected: (_) => setState(() { payerType = 'FUND'; dirty = true; }),
                  ),
                  for (final member in members)
                    ChoiceChip(
                      label: Text(member.displayName),
                      selected: payerType == 'MEMBER' && payerMemberId == member.id,
                      onSelected: (_) => setState(() { payerType = 'MEMBER'; payerMemberId = member.id; dirty = true; }),
                    ),
                ],
              ),
            ]),
            _section('誰需要分攤？', [
              Row(
                children: [
                  Text('已選 ${selectedMemberIds.length} 人'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      if (selectedMemberIds.length == members.length) {
                        selectedMemberIds.clear();
                      } else {
                        selectedMemberIds..clear()..addAll(members.map((e) => e.id));
                      }
                      dirty = true;
                      _refreshPreview();
                    }),
                    child: Text(selectedMemberIds.length == members.length ? '取消全選' : '全選'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final member in members)
                    FilterChip(
                      label: Text(member.displayName),
                      selected: selectedMemberIds.contains(member.id),
                      onSelected: (yes) => setState(() {
                        yes ? selectedMemberIds.add(member.id) : selectedMemberIds.remove(member.id);
                        dirty = true;
                        _refreshPreview();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<ExpenseSplitMode>(
                segments: const [
                  ButtonSegment(value: ExpenseSplitMode.equal, label: Text('平均')),
                  ButtonSegment(value: ExpenseSplitMode.customAmount, label: Text('自訂金額')),
                  ButtonSegment(value: ExpenseSplitMode.percentage, label: Text('比例')),
                ],
                selected: {splitMode},
                onSelectionChanged: (value) => setState(() { splitMode = value.first; dirty = true; }),
              ),
              const SizedBox(height: 12),
              ..._splitRows(selectedMembers, currentTrip.baseCurrency),
              const SizedBox(height: 8),
              _allocationStatus(currentTrip.baseCurrency),
            ]),
            _section('分類', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in systemCategories)
                    ChoiceChip(
                      avatar: Icon(categoryIcon(key), size: 18),
                      label: Text(categoryLabel(key)),
                      selected: categoryKey == key && customCategoryId == null,
                      onSelected: (_) => setState(() { categoryKey = key; customCategoryId = null; dirty = true; }),
                    ),
                  for (final item in customCategories)
                    ChoiceChip(
                      avatar: const Icon(Icons.label_rounded, size: 18),
                      label: Text(item.name),
                      selected: customCategoryId == item.id,
                      onSelected: (_) => setState(() { categoryKey = 'CUSTOM'; customCategoryId = item.id; dirty = true; }),
                    ),
                  ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('新增類別'), onPressed: _addCustomCategory),
                ],
              ),
            ]),
            _section('支出明細', [
              TextField(controller: titleController, decoration: const InputDecoration(hintText: '選填，例如：和牛燒肉')),
              const SizedBox(height: 10),
              TextField(controller: noteController, maxLines: 3, decoration: const InputDecoration(hintText: '備註（選填）')),
              const SizedBox(height: 10),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.schedule),
                title: const Text('日期時間'),
                subtitle: Text('${occurredAt.year}/${occurredAt.month}/${occurredAt.day} ${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}'),
                onTap: _pickDateTime,
              ),
            ]),
            _section('照片與收據', [
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _stageReceipt, icon: const Icon(Icons.camera_alt_outlined), label: const Text('拍攝收據'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: _stagePhotos, icon: const Icon(Icons.photo_library_outlined), label: const Text('加入照片'))),
                ],
              ),
              if (existingAttachments.isNotEmpty || stagedAttachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final row in existingAttachments) _existingAttachmentChip(row),
                    for (var i = 0; i < stagedAttachments.length; i++) _stagedAttachmentChip(i),
                  ],
                ),
              ],
            ]),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
            label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('儲存支出')),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              ...children,
            ]),
          ),
        ),
      );

  List<Widget> _splitRows(List<MemberRow> selectedMembers, String baseCurrency) {
    final total = previewBaseMinor;
    final equal = total == null || selectedMembers.isEmpty
        ? const <int>[]
        : widget.controller.services.split.equalSplit(total, selectedMembers.length);
    return [
      for (var i = 0; i < selectedMembers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(selectedMembers[i].displayName, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (splitMode == ExpenseSplitMode.equal)
                Text(equal.isEmpty ? '-' : MoneyText.formatMinor(equal[i], baseCurrency))
              else if (splitMode == ExpenseSplitMode.customAmount)
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: customControllers[selectedMembers[i].id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(suffixText: baseCurrency, hintText: '0'),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: percentageControllers[selectedMembers[i].id],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(suffixText: '%', hintText: '0'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(width: 115, child: Text(_percentDerived(selectedMembers[i].id, baseCurrency), textAlign: TextAlign.end)),
                  ],
                ),
            ],
          ),
        ),
    ];
  }

  String _percentDerived(String memberId, String baseCurrency) {
    final total = previewBaseMinor;
    final raw = percentageControllers[memberId]?.text.trim() ?? '';
    final percent = Decimal.tryParse(raw);
    if (total == null || percent == null || percent < Decimal.zero) return '-';
    final value = (Decimal.fromInt(total) * percent / Decimal.fromInt(100)).toDecimal(scaleOnInfinitePrecision: 6).round().toBigInt().toInt();
    return MoneyText.formatMinor(value, baseCurrency);
  }

  Widget _allocationStatus(String baseCurrency) {
    final total = previewBaseMinor;
    if (total == null) return const Text('輸入金額後顯示分攤結果', style: TextStyle(color: Colors.black54));
    if (splitMode == ExpenseSplitMode.equal) {
      return Text('合計 ${MoneyText.formatMinor(total, baseCurrency)}', style: const TextStyle(fontWeight: FontWeight.w700));
    }
    if (splitMode == ExpenseSplitMode.customAmount) {
      final allocated = customMinorByMember.values.fold<int>(0, (a, b) => a + b);
      final delta = total - allocated;
      final label = delta == 0
          ? '已完整分配'
          : delta > 0
              ? '尚未分配 ${MoneyText.formatMinor(delta, baseCurrency)}'
              : '超出 ${MoneyText.formatMinor(-delta, baseCurrency)}';
      return Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: delta == 0 ? Colors.green.shade700 : Theme.of(context).colorScheme.error));
    }
    var sum = Decimal.zero;
    for (final id in selectedMemberIds) {
      final value = Decimal.tryParse(percentageControllers[id]?.text.trim() ?? '');
      if (value != null) sum += value;
    }
    final delta = Decimal.fromInt(100) - sum;
    final label = delta == Decimal.zero ? '已完整分配 100%' : delta > Decimal.zero ? '尚未分配 $delta%' : '超出 ${-delta}%';
    return Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: delta == Decimal.zero ? Colors.green.shade700 : Theme.of(context).colorScheme.error));
  }

  Future<void> _save() async {
    final minor = originalMinor;
    if (minor == null || minor <= 0) return _warning('請輸入有效金額。');
    if (selectedMemberIds.isEmpty) return _warning('至少選擇一位分攤旅伴。');
    if (payerType == 'MEMBER' && payerMemberId == null) return _warning('請選擇付款人。');

    setState(() => saving = true);
    try {
      final id = await widget.controller.services.expenses.save(
        ExpenseSaveRequest(
          expenseId: widget.expenseId,
          tripId: tripId,
          title: titleController.text,
          note: noteController.text,
          originalAmountMinor: minor,
          originalCurrency: currency,
          payerType: payerType,
          payerMemberId: payerMemberId,
          categoryKey: categoryKey,
          customCategoryId: customCategoryId,
          occurredAt: occurredAt,
          selectedMemberIds: selectedMemberIds.toList(),
          splitMode: splitMode,
          customAmountMinorByMember: customMinorByMember,
          percentageByMember: percentageByMember,
          manualRateText: manualRate ? manualRateController.text : null,
        ),
      );
      if (stagedAttachments.isNotEmpty) {
        await widget.controller.services.attachments.persistStaged(id, stagedAttachments);
      }
      await widget.controller.selectTrip(tripId);
      if (mounted) {
        setState(() => dirty = false);
        Navigator.pop(context, id);
      }
    } catch (e) {
      await _warning('$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deleteExpense() async {
    final id = widget.expenseId;
    if (id == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除此筆支出？'),
        content: const Text('刪除後會重新計算公基金、每人統計與建議轉帳。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
    if (yes != true) return;
    await widget.controller.services.expenses.delete(id);
    if (mounted) {
      setState(() => dirty = false);
      Navigator.pop(context);
    }
  }

  Future<void> _warning(String message) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('無法儲存'),
          content: Text(message),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('知道了'))],
        ),
      );

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2040), initialDate: occurredAt);
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(occurredAt));
    if (time == null) return;
    setState(() { occurredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute); dirty = true; });
  }

  Future<void> _addCustomCategory() async {
    final text = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增自訂類別'),
        content: TextField(controller: text, autofocus: true, decoration: const InputDecoration(labelText: '類別名稱')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, text.text.trim()), child: const Text('新增')),
        ],
      ),
    );
    text.dispose();
    if (name == null || name.isEmpty) return;
    final id = await widget.controller.services.repository.addCustomCategory(tripId: tripId, name: name, iconKey: 'tag');
    customCategories = await widget.controller.services.repository.getCustomCategories(tripId);
    setState(() { categoryKey = 'CUSTOM'; customCategoryId = id; dirty = true; });
  }

  Future<void> _stageReceipt() async {
    try {
      final staged = await widget.controller.services.attachments.stageReceipt();
      if (staged != null) setState(() { stagedAttachments.add(staged); dirty = true; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('相機無法使用：$e')));
    }
  }

  Future<void> _stagePhotos() async {
    try {
      final remaining = 5 - stagedAttachments.length;
      if (remaining <= 0) return;
      final staged = await widget.controller.services.attachments.stagePhotos(limit: remaining);
      if (staged.isNotEmpty) setState(() { stagedAttachments.addAll(staged); dirty = true; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('相簿無法使用：$e')));
    }
  }

  Widget _stagedAttachmentChip(int index) {
    final item = stagedAttachments[index];
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(item.file.path), width: 74, height: 74, fit: BoxFit.cover)),
        Positioned(right: 0, top: 0, child: InkWell(onTap: () => setState(() { stagedAttachments.removeAt(index); dirty = true; }), child: const CircleAvatar(radius: 11, child: Icon(Icons.close, size: 14)))),
      ],
    );
  }

  Widget _existingAttachmentChip(AttachmentRow row) {
    return FutureBuilder<File>(
      future: widget.controller.services.attachments.fileFor(row),
      builder: (context, snapshot) {
        final file = snapshot.data;
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: file != null && file.existsSync()
                  ? Image.file(file, width: 74, height: 74, fit: BoxFit.cover)
                  : Container(width: 74, height: 74, color: Colors.black12, child: const Icon(Icons.image_not_supported)),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: InkWell(
                onTap: () async {
                  await widget.controller.services.attachments.deleteAttachment(row.id);
                  existingAttachments = await widget.controller.services.attachments.attachmentsForExpense(row.expenseId);
                  if (mounted) setState(() => dirty = true);
                },
                child: const CircleAvatar(radius: 11, child: Icon(Icons.close, size: 14)),
              ),
            ),
          ],
        );
      },
    );
  }
}
