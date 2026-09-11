import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/money_text.dart';
import '../../platform/local_paths.dart';
import 'report_models.dart';

class SettlementImageService {
  SettlementImageService({LocalPaths? paths}) : _paths = paths ?? const LocalPaths();

  final LocalPaths _paths;

  static const double width = 1080;
  static const double side = 72;

  Future<File> render(SettlementShareReport report, {String locale = 'zh_TW'}) async {
    final labels = _Labels.forLocale(locale);
    final transferRows = report.transfers.isEmpty ? 1 : report.transfers.length;
    final memberRows = report.members.length;
    // Keep the share image bounded for messaging apps and lower-memory Android devices.
    final height = (900 + transferRows * 92 + memberRows * 118).clamp(1200, 7800).toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFFF4FAF9));

    final cardPaint = Paint()..color = Colors.white;
    final accentPaint = Paint()..color = const Color(0xFF119C91);
    final linePaint = Paint()
      ..color = const Color(0xFFE3ECEA)
      ..strokeWidth = 2;

    var y = 70.0;
    _text(canvas, '旅行伴伴  TripBanBan', Offset(side, y), 27, const Color(0xFF57706D), FontWeight.w600);
    y += 58;
    _text(canvas, report.tripName, Offset(side, y), 53, const Color(0xFF173D39), FontWeight.w800);
    y += 88;

    final summaryRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(side, y, width - side * 2, 190),
      const Radius.circular(32),
    );
    canvas.drawRRect(summaryRect, accentPaint);
    _text(canvas, labels.total, Offset(side + 42, y + 34), 27, Colors.white.withAlpha(220), FontWeight.w600);
    _text(
      canvas,
      MoneyText.formatMinor(report.totalExpenseMinor, report.currency, locale: locale),
      Offset(side + 42, y + 82),
      50,
      Colors.white,
      FontWeight.w800,
    );
    y += 238;

    _sectionTitle(canvas, labels.transfers, y);
    y += 62;
    final transferCardHeight = 38 + transferRows * 92.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(side, y, width - side * 2, transferCardHeight), const Radius.circular(28)),
      cardPaint,
    );
    var rowY = y + 24;
    if (report.transfers.isEmpty) {
      _text(canvas, labels.noTransfer, Offset(side + 36, rowY + 14), 29, const Color(0xFF4B6662), FontWeight.w600);
    } else {
      for (var i = 0; i < report.transfers.length; i++) {
        final transfer = report.transfers[i];
        _text(
          canvas,
          '${report.memberName(transfer.fromMemberId)}  →  ${report.memberName(transfer.toMemberId)}',
          Offset(side + 36, rowY),
          30,
          const Color(0xFF213F3C),
          FontWeight.w700,
        );
        _textRight(
          canvas,
          MoneyText.formatMinor(transfer.amountMinor, report.currency, locale: locale),
          Offset(width - side - 36, rowY),
          30,
          const Color(0xFF0B877F),
          FontWeight.w800,
        );
        rowY += 92;
        if (i != report.transfers.length - 1) {
          canvas.drawLine(Offset(side + 36, rowY - 22), Offset(width - side - 36, rowY - 22), linePaint);
        }
      }
    }
    y += transferCardHeight + 48;

    _sectionTitle(canvas, labels.members, y);
    y += 62;
    final memberCardHeight = 34 + memberRows * 118.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(side, y, width - side * 2, memberCardHeight), const Radius.circular(28)),
      cardPaint,
    );
    rowY = y + 22;
    for (var i = 0; i < report.members.length; i++) {
      final member = report.members[i];
      final balance = member.balance;
      final paid = balance.paidMinor + balance.fundNetContributionMinor;
      _text(canvas, member.name, Offset(side + 36, rowY), 29, const Color(0xFF213F3C), FontWeight.w800);
      rowY += 38;
      final columns = [
        '${labels.paid} ${MoneyText.formatMinor(paid, report.currency, locale: locale)}',
        '${labels.share} ${MoneyText.formatMinor(balance.shareMinor, report.currency, locale: locale)}',
        '${labels.net} ${MoneyText.formatMinor(balance.netMinor, report.currency, locale: locale)}',
      ];
      _text(canvas, columns.join('   ·   '), Offset(side + 36, rowY), 21, const Color(0xFF647B78), FontWeight.w600, maxWidth: width - side * 2 - 72);
      rowY += 80;
      if (i != report.members.length - 1) {
        canvas.drawLine(Offset(side + 36, rowY - 20), Offset(width - side - 36, rowY - 20), linePaint);
      }
    }
    y += memberCardHeight + 40;

    if (report.fundBalanceMinor != 0) {
      _text(
        canvas,
        '${labels.fund} ${MoneyText.formatMinor(report.fundBalanceMinor, report.currency, locale: locale)} · ${labels.fundHint}',
        Offset(side, y),
        24,
        const Color(0xFFA76513),
        FontWeight.w600,
        maxWidth: width - side * 2,
      );
    }

    _text(canvas, 'Generated by 旅行伴伴 TripBanBan', Offset(side, height - 86), 24, const Color(0xFF78908D), FontWeight.w500);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Unable to encode settlement image.');

    final dir = await _paths.tempExports();
    final file = File('${dir.path}/TripBanBan_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file;
  }

  void _sectionTitle(Canvas canvas, String value, double y) =>
      _text(canvas, value, Offset(side, y), 34, const Color(0xFF173D39), FontWeight.w800);

  void _text(
    Canvas canvas,
    String text,
    Offset offset,
    double size,
    Color color,
    FontWeight weight, {
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color, fontWeight: weight, height: 1.25)),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: maxWidth ?? width - offset.dx - side);
    painter.paint(canvas, offset);
  }

  void _textRight(Canvas canvas, String text, Offset rightTop, double size, Color color, FontWeight weight) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(rightTop.dx - painter.width, rightTop.dy));
  }
}

class _Labels {
  const _Labels({required this.total, required this.transfers, required this.noTransfer, required this.members, required this.paid, required this.share, required this.net, required this.fund, required this.fundHint});

  final String total;
  final String transfers;
  final String noTransfer;
  final String members;
  final String paid;
  final String share;
  final String net;
  final String fund;
  final String fundHint;

  static _Labels forLocale(String locale) {
    if (locale.startsWith('en')) return const _Labels(total: 'Trip total', transfers: 'Who pays whom', noTransfer: 'No pending transfers', members: 'Member statistics', paid: 'Paid', share: 'Share', net: 'Net', fund: 'Fund balance', fundHint: 'Refund the remaining fund before final settlement.');
    if (locale.startsWith('ja')) return const _Labels(total: '旅行総額', transfers: '誰が誰に支払うか', noTransfer: '未払いの送金はありません', members: 'メンバー別統計', paid: '支払', share: '負担', net: '差額', fund: '共同資金残高', fundHint: '最終精算前に残額を返金してください。');
    if (locale.startsWith('ko')) return const _Labels(total: '여행 총지출', transfers: '누가 누구에게 얼마를', noTransfer: '대기 중인 이체가 없습니다', members: '멤버별 통계', paid: '결제', share: '분담', net: '순액', fund: '공동 경비 잔액', fundHint: '최종 정산 전에 남은 금액을 환불하세요.');
    if (locale.startsWith('zh_CN')) return const _Labels(total: '旅行总支出', transfers: '谁该给谁', noTransfer: '目前没有待转账款项', members: '每人支出统计', paid: '已支付', share: '应分摊', net: '净额', fund: '公基金余额', fundHint: '退款后才能完全结清。');
    return const _Labels(total: '旅行總支出', transfers: '誰該給誰', noTransfer: '目前沒有待轉帳款項', members: '每人支出統計', paid: '已支付', share: '應分攤', net: '淨額', fund: '公基金餘額', fundHint: '退款後才能完全結清。');
  }
}
