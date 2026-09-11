import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../domain/money_text.dart';
import '../localization/app_strings.dart';
import '../widgets/category_icon.dart';
import 'add_expense_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(controller.languageCode);
    final tripId = controller.selectedTripId;
    if (tripId == null) {
      return Scaffold(appBar: AppBar(title: Text(strings.t('expenseRecords'))), body: Center(child: Text(strings.t('noTrips'))));
    }
    return FutureBuilder<TripRow?>(
      future: controller.services.repository.getTrip(tripId),
      builder: (context, tripSnapshot) {
        final trip = tripSnapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(strings.t('expenseRecords'), style: const TextStyle(fontWeight: FontWeight.w800)),
              if (trip != null) Text(trip.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
            ]),
          ),
          body: StreamBuilder<List<ExpenseRow>>(
            stream: controller.services.repository.watchExpenses(tripId),
            builder: (context, snapshot) {
              final expenses = snapshot.data ?? const <ExpenseRow>[];
              if (expenses.isEmpty) return Center(child: Text(strings.t('noExpenses')));
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(
                            controller: controller,
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
                                  Text(expense.title.trim().isEmpty ? categoryLabel(expense.categoryKey) : expense.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text('${categoryLabel(expense.categoryKey)} · ${expense.occurredAt.year}/${expense.occurredAt.month}/${expense.occurredAt.day}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(MoneyText.formatMinor(expense.originalAmountMinor, expense.originalCurrency), style: const TextStyle(fontWeight: FontWeight.w800)),
                                if (expense.originalCurrency != expense.baseCurrency)
                                  Text('≈ ${MoneyText.formatMinor(expense.baseAmountMinor, expense.baseCurrency)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
