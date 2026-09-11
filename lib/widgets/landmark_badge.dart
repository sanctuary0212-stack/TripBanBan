import 'package:flutter/material.dart';

String inferCountryCode(String text) {
  final value = text.toLowerCase();
  const groups = <String, List<String>>{
    'JP': ['日本', '東京', '大阪', '京都', '沖繩', '北海道', 'japan', 'tokyo', 'osaka', 'kyoto', 'okinawa', 'sapporo'],
    'KR': ['韓國', '首爾', '釜山', '濟州', 'korea', 'seoul', 'busan', 'jeju'],
    'TW': ['台灣', '臺灣', '台北', '臺北', '高雄', '台中', '臺中', 'taiwan', 'taipei', 'kaohsiung', 'taichung'],
    'FR': ['法國', '巴黎', 'france', 'paris'],
    'IT': ['義大利', '意大利', '羅馬', '佛羅倫斯', '威尼斯', '米蘭', 'italy', 'rome', 'florence', 'venice', 'milan'],
    'US': ['美國', '紐約', '洛杉磯', '舊金山', '夏威夷', 'usa', 'united states', 'new york', 'los angeles', 'san francisco', 'hawaii'],
    'TH': ['泰國', '曼谷', '清邁', '普吉', 'thailand', 'bangkok', 'chiang mai', 'phuket'],
    'DE': ['德國', '柏林', '慕尼黑', 'germany', 'berlin', 'munich'],
    'ES': ['西班牙', '馬德里', '巴塞隆納', 'spain', 'madrid', 'barcelona'],
    'GB': ['英國', '倫敦', 'uk', 'united kingdom', 'london'],
  };
  for (final entry in groups.entries) {
    if (entry.value.any(value.contains)) return entry.key;
  }
  return '';
}

class LandmarkBadge extends StatelessWidget {
  const LandmarkBadge({
    super.key,
    required this.label,
    this.countryCode,
    this.size = 58,
    this.selected = false,
  });

  final String label;
  final String? countryCode;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final code = (countryCode?.trim().isNotEmpty == true ? countryCode! : inferCountryCode(label)).toUpperCase();
    final palette = _palette(code);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        borderRadius: BorderRadius.circular(size * .30),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))]
            : null,
      ),
      child: CustomPaint(
        painter: _LandmarkPainter(code),
      ),
    );
  }

  List<Color> _palette(String code) => switch (code) {
        'JP' => const [Color(0xFFFFE8EC), Color(0xFFFFB9C5)],
        'KR' => const [Color(0xFFE6F0FF), Color(0xFFB9D7FF)],
        'TW' => const [Color(0xFFE3FFF8), Color(0xFF9DEBD7)],
        'FR' => const [Color(0xFFE9EDFF), Color(0xFFBAC7FF)],
        'IT' => const [Color(0xFFE8F8E8), Color(0xFFBEE5C2)],
        'US' => const [Color(0xFFE8F3FF), Color(0xFFB9D8F6)],
        'TH' => const [Color(0xFFFFF2D9), Color(0xFFFFD68A)],
        'DE' => const [Color(0xFFFFF0D9), Color(0xFFFFC77A)],
        'ES' => const [Color(0xFFFFECD5), Color(0xFFFFC68B)],
        'GB' => const [Color(0xFFE8EEFF), Color(0xFFBFCBFF)],
        _ => const [Color(0xFFE2FAF6), Color(0xFF9EE5DA)],
      };
}

class _LandmarkPainter extends CustomPainter {
  _LandmarkPainter(this.code);
  final String code;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF123F3D)
      ..style = PaintingStyle.fill;
    final soft = Paint()
      ..color = const Color(0x44FFFFFF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * .78, size.height * .23), size.width * .13, soft);

    switch (code) {
      case 'JP':
        _mountain(canvas, size, ink);
        break;
      case 'FR':
        _eiffel(canvas, size, ink);
        break;
      case 'IT':
        _dome(canvas, size, ink);
        break;
      case 'TW':
        _taipei(canvas, size, ink);
        break;
      case 'TH':
        _temple(canvas, size, ink);
        break;
      case 'KR':
        _tower(canvas, size, ink);
        break;
      case 'US':
      case 'GB':
      case 'DE':
      case 'ES':
        _skyline(canvas, size, ink);
        break;
      default:
        _globe(canvas, size, ink);
    }

    final plane = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = size.width * .035
      ..strokeCap = StrokeCap.round;
    final p = Path()
      ..moveTo(size.width * .18, size.height * .24)
      ..quadraticBezierTo(size.width * .47, size.height * .10, size.width * .76, size.height * .18);
    canvas.drawPath(p, plane);
  }

  void _mountain(Canvas c, Size s, Paint p) {
    final path = Path()
      ..moveTo(s.width * .10, s.height * .78)
      ..lineTo(s.width * .47, s.height * .34)
      ..lineTo(s.width * .61, s.height * .53)
      ..lineTo(s.width * .72, s.height * .43)
      ..lineTo(s.width * .92, s.height * .78)
      ..close();
    c.drawPath(path, p);
    final snow = Paint()..color = const Color(0xFFEFFDFC);
    final cap = Path()
      ..moveTo(s.width * .36, s.height * .47)
      ..lineTo(s.width * .47, s.height * .34)
      ..lineTo(s.width * .56, s.height * .47)
      ..lineTo(s.width * .50, s.height * .44)
      ..lineTo(s.width * .46, s.height * .49)
      ..lineTo(s.width * .42, s.height * .44)
      ..close();
    c.drawPath(cap, snow);
  }

  void _eiffel(Canvas c, Size s, Paint p) {
    final path = Path()
      ..moveTo(s.width * .48, s.height * .27)
      ..lineTo(s.width * .28, s.height * .82)
      ..lineTo(s.width * .39, s.height * .82)
      ..lineTo(s.width * .46, s.height * .64)
      ..lineTo(s.width * .56, s.height * .64)
      ..lineTo(s.width * .63, s.height * .82)
      ..lineTo(s.width * .74, s.height * .82)
      ..lineTo(s.width * .53, s.height * .27)
      ..close();
    c.drawPath(path, p);
    c.drawRect(Rect.fromLTWH(s.width * .34, s.height * .57, s.width * .33, s.height * .055), p);
    c.drawRect(Rect.fromLTWH(s.width * .39, s.height * .43, s.width * .23, s.height * .045), p);
  }

  void _dome(Canvas c, Size s, Paint p) {
    c.drawRect(Rect.fromLTWH(s.width * .20, s.height * .61, s.width * .62, s.height * .20), p);
    c.drawOval(Rect.fromLTWH(s.width * .31, s.height * .38, s.width * .40, s.height * .34), p);
    c.drawRect(Rect.fromLTWH(s.width * .47, s.height * .31, s.width * .08, s.height * .17), p);
    c.drawRect(Rect.fromLTWH(s.width * .17, s.height * .78, s.width * .68, s.height * .06), p);
  }

  void _taipei(Canvas c, Size s, Paint p) {
    final center = s.width * .5;
    c.drawRect(Rect.fromLTWH(center - s.width * .035, s.height * .22, s.width * .07, s.height * .12), p);
    var y = s.height * .34;
    var w = s.width * .32;
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromCenter(center: Offset(center, y), width: w, height: s.height * .085), p);
      y += s.height * .09;
      w *= .84;
    }
    c.drawRect(Rect.fromLTWH(center - s.width * .15, s.height * .76, s.width * .30, s.height * .08), p);
  }

  void _temple(Canvas c, Size s, Paint p) {
    final roof1 = Path()
      ..moveTo(s.width * .16, s.height * .49)
      ..lineTo(s.width * .50, s.height * .30)
      ..lineTo(s.width * .84, s.height * .49)
      ..lineTo(s.width * .76, s.height * .49)
      ..lineTo(s.width * .50, s.height * .39)
      ..lineTo(s.width * .24, s.height * .49)
      ..close();
    c.drawPath(roof1, p);
    c.drawRect(Rect.fromLTWH(s.width * .28, s.height * .50, s.width * .44, s.height * .27), p);
    c.drawRect(Rect.fromLTWH(s.width * .22, s.height * .76, s.width * .56, s.height * .07), p);
  }

  void _tower(Canvas c, Size s, Paint p) {
    c.drawRect(Rect.fromLTWH(s.width * .46, s.height * .28, s.width * .08, s.height * .40), p);
    c.drawOval(Rect.fromLTWH(s.width * .31, s.height * .42, s.width * .38, s.height * .10), p);
    c.drawRect(Rect.fromLTWH(s.width * .32, s.height * .69, s.width * .36, s.height * .12), p);
  }

  void _skyline(Canvas c, Size s, Paint p) {
    final base = s.height * .82;
    final xs = [.12, .27, .41, .58, .73];
    final hs = [.28, .43, .34, .52, .31];
    final ws = [.13, .12, .15, .11, .14];
    for (var i = 0; i < xs.length; i++) {
      c.drawRect(Rect.fromLTWH(s.width * xs[i], base - s.height * hs[i], s.width * ws[i], s.height * hs[i]), p);
    }
    c.drawRect(Rect.fromLTWH(s.width * .08, base, s.width * .84, s.height * .05), p);
  }

  void _globe(Canvas c, Size s, Paint p) {
    c.drawCircle(Offset(s.width * .50, s.height * .58), s.width * .26, p);
    final cut = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .025;
    c.drawOval(Rect.fromCenter(center: Offset(s.width * .50, s.height * .58), width: s.width * .27, height: s.width * .52), cut);
    c.drawLine(Offset(s.width * .25, s.height * .58), Offset(s.width * .75, s.height * .58), cut);
  }

  @override
  bool shouldRepaint(covariant _LandmarkPainter oldDelegate) => oldDelegate.code != code;
}
