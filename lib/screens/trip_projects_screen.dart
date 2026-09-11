import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../data/local/app_database.dart';
import '../domain/ledger_models.dart';
import '../domain/money_text.dart';
import '../localization/app_strings.dart';
import '../widgets/landmark_badge.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripProjectsScreen extends StatelessWidget {
  const TripProjectsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(controller.languageCode);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('appName'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<List<TripRow>>(
        stream: controller.services.repository.watchTrips(),
        builder: (context, snapshot) {
          final trips = snapshot.data ?? const <TripRow>[];
          if (trips.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flight_takeoff_rounded, size: 68),
                    const SizedBox(height: 18),
                    Text(strings.t('noTrips'), textAlign: TextAlign.center),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _openCreateTrip(context),
                      icon: const Icon(Icons.add, size: 25),
                      label: Text(strings.t('newTrip')),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: trips.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == trips.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: () => _openCreateTrip(context),
                      icon: const Icon(Icons.add_circle_outline, size: 25),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Text(strings.t('newTrip')),
                      ),
                    ),
                  ),
                );
              }
              return _TripCard(controller: controller, trip: trips[index]);
            },
          );
        },
      ),
    );
  }

  Future<void> _openCreateTrip(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTripScreen(controller: controller)),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.controller, required this.trip});
  final AppController controller;
  final TripRow trip;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LedgerSnapshot>(
      future: controller.services.ledger.calculate(trip.id),
      builder: (context, snapshot) {
        final ledger = snapshot.data;
        final status = ledger?.status ?? TripAccountingStatus.notStarted;
        final strings = AppStrings(controller.languageCode);
        final statusLabel = switch (status) {
          TripAccountingStatus.notStarted => strings.t('notStarted'),
          TripAccountingStatus.pendingSettlement => strings.t('pending'),
          TripAccountingStatus.settled => strings.t('settled'),
        };
        final selected = controller.selectedTripId == trip.id;
        final destinationLabel = [
          if (trip.destination?.trim().isNotEmpty == true) trip.destination!.trim(),
          trip.name,
        ].join(' ');
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              await controller.selectTrip(trip.id);
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TripDetailScreen(controller: controller, tripId: trip.id)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  LandmarkBadge(
                    label: destinationLabel,
                    countryCode: trip.countryCode,
                    selected: selected,
                    size: 58,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(trip.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                            if (selected) const Icon(Icons.check_circle, size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${trip.destination?.isNotEmpty == true ? '${trip.destination} · ' : ''}${trip.baseCurrency}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _pill(statusLabel),
                            if (ledger != null) _pill('${strings.t('totalExpense')} ${MoneyText.formatMinor(ledger.totalExpenseMinor, trip.baseCurrency)}'),
                            if (ledger != null && ledger.fundBalanceMinor != 0)
                              _pill('${strings.t('publicFund')} ${MoneyText.formatMinor(ledger.fundBalanceMinor, trip.baseCurrency)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF0F5F4), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );
}
