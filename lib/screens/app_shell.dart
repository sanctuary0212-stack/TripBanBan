import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../localization/app_strings.dart';
import 'add_expense_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'settlement_screen.dart';
import 'trip_projects_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.controller.languageCode);
    final pages = [
      TripProjectsScreen(controller: widget.controller),
      RecordsScreen(controller: widget.controller),
      const SizedBox.shrink(),
      SettlementScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: IndexedStack(index: index == 2 ? 0 : index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (next) async {
          if (next == 2) {
            final tripId = widget.controller.selectedTripId;
            if (tripId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.t('noTrips'))),
              );
              return;
            }
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddExpenseScreen(
                  controller: widget.controller,
                  initialTripId: tripId,
                ),
              ),
            );
            if (mounted) setState(() => index = 0);
            return;
          }
          setState(() => index = next);
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.luggage_outlined), selectedIcon: const Icon(Icons.luggage), label: strings.t('trips')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: strings.t('records')),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline, size: 32),
            selectedIcon: const Icon(Icons.add_circle, size: 34),
            label: strings.t('add'),
          ),
          NavigationDestination(icon: const Icon(Icons.sync_alt_outlined), selectedIcon: const Icon(Icons.sync_alt), label: strings.t('settlement')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: strings.t('settings')),
        ],
      ),
    );
  }
}
