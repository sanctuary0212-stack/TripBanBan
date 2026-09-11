import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripbanban_app/data/local/app_database.dart';
import 'package:tripbanban_app/data/repositories/ledger_repository.dart';
import 'package:tripbanban_app/features/backup/snapshot_service.dart';

void main() {
  test('portable JSON snapshot restores trips and members', () async {
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final sourceRepo = LedgerRepository(source);
    await sourceRepo.createTrip(name: 'Okinawa', baseCurrency: 'JPY', memberNames: ['Amy', 'Jack']);
    final snapshot = await SnapshotService(source).exportJson();

    final target = AppDatabase.forTesting(NativeDatabase.memory());
    await SnapshotService(target).restoreJson(snapshot);
    final trips = await target.select(target.trips).get();
    final members = await target.select(target.members).get();
    expect(trips.single.name, 'Okinawa');
    expect(members.map((e) => e.displayName), containsAll(['Amy', 'Jack']));

    await source.close();
    await target.close();
  });
}
