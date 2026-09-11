import 'package:flutter/material.dart';

import '../domain/currency_catalog.dart';

Future<String?> showCurrencyPicker(
  BuildContext context, {
  required String selected,
  String title = 'Currency',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CurrencyPickerSheet(selected: selected, title: title),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.selected, required this.title});
  final String selected;
  final String title;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final currencies = CurrencyCatalog.all.where((item) {
      if (normalized.isEmpty) return true;
      return item.code.toLowerCase().contains(normalized) ||
          item.name.toLowerCase().contains(normalized) ||
          item.symbol.toLowerCase().contains(normalized);
    }).toList(growable: false);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .82,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
            child: Row(
              children: [
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'TWD / JPY / Dollar / Yen…'),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final item = currencies[index];
                final active = item.code == widget.selected;
                return ListTile(
                  leading: CircleAvatar(child: Text(item.symbol.length <= 3 ? item.symbol : item.code.substring(0, 1))),
                  title: Text('${item.code}  ${item.name}'),
                  subtitle: Text(item.symbol),
                  trailing: active ? const Icon(Icons.check_circle) : null,
                  onTap: () => Navigator.pop(context, item.code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
