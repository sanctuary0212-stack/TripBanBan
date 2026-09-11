import '../../domain/ledger_models.dart';

class ShareReportMember {
  const ShareReportMember({
    required this.id,
    required this.name,
    required this.balance,
  });

  final String id;
  final String name;
  final MemberBalance balance;
}

class SettlementShareReport {
  const SettlementShareReport({
    required this.tripName,
    required this.currency,
    required this.totalExpenseMinor,
    required this.fundBalanceMinor,
    required this.members,
    required this.transfers,
    required this.generatedAt,
  });

  final String tripName;
  final String currency;
  final int totalExpenseMinor;
  final int fundBalanceMinor;
  final List<ShareReportMember> members;
  final List<SuggestedTransfer> transfers;
  final DateTime generatedAt;

  String memberName(String id) =>
      members.where((member) => member.id == id).map((member) => member.name).firstOrNull ?? id;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
