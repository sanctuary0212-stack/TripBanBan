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
      final region = _regionFor(item.code);
      if (normalized.isEmpty) return true;
      return item.code.toLowerCase().contains(normalized) ||
          item.name.toLowerCase().contains(normalized) ||
          item.symbol.toLowerCase().contains(normalized) ||
          region.country.toLowerCase().contains(normalized);
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
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'TWD / JPY / 國家 / Dollar / Yen…'),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final item = currencies[index];
                final region = _regionFor(item.code);
                final active = item.code == widget.selected;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFB9F2EA),
                    child: Text(region.flag, style: const TextStyle(fontSize: 22)),
                  ),
                  title: Text('${item.code}  ${item.name}'),
                  subtitle: Text('${region.country} · ${item.symbol}'),
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

class _CurrencyRegion {
  const _CurrencyRegion(this.country, this.iso2);
  final String country;
  final String? iso2;

  String get flag {
    final code = iso2;
    if (code == null || code.length != 2) return '🌐';
    final upper = code.toUpperCase().codeUnits;
    return String.fromCharCodes(upper.map((c) => 0x1F1E6 + c - 65));
  }
}

_CurrencyRegion _regionFor(String code) => _regions[code] ?? const _CurrencyRegion('國際 / 多國', null);

const Map<String, _CurrencyRegion> _regions = {
  'AED': _CurrencyRegion('阿拉伯聯合大公國', 'AE'),
  'AFN': _CurrencyRegion('阿富汗', 'AF'),
  'ALL': _CurrencyRegion('阿爾巴尼亞', 'AL'),
  'AMD': _CurrencyRegion('亞美尼亞', 'AM'),
  'ANG': _CurrencyRegion('荷屬加勒比地區', 'CW'),
  'AOA': _CurrencyRegion('安哥拉', 'AO'),
  'ARS': _CurrencyRegion('阿根廷', 'AR'),
  'AUD': _CurrencyRegion('澳洲', 'AU'),
  'AWG': _CurrencyRegion('阿魯巴', 'AW'),
  'AZN': _CurrencyRegion('亞塞拜然', 'AZ'),
  'BAM': _CurrencyRegion('波士尼亞與赫塞哥維納', 'BA'),
  'BBD': _CurrencyRegion('巴貝多', 'BB'),
  'BDT': _CurrencyRegion('孟加拉', 'BD'),
  'BGN': _CurrencyRegion('保加利亞', 'BG'),
  'BHD': _CurrencyRegion('巴林', 'BH'),
  'BIF': _CurrencyRegion('蒲隆地', 'BI'),
  'BMD': _CurrencyRegion('百慕達', 'BM'),
  'BND': _CurrencyRegion('汶萊', 'BN'),
  'BOB': _CurrencyRegion('玻利維亞', 'BO'),
  'BRL': _CurrencyRegion('巴西', 'BR'),
  'BSD': _CurrencyRegion('巴哈馬', 'BS'),
  'BTN': _CurrencyRegion('不丹', 'BT'),
  'BWP': _CurrencyRegion('波札那', 'BW'),
  'BYN': _CurrencyRegion('白俄羅斯', 'BY'),
  'BZD': _CurrencyRegion('貝里斯', 'BZ'),
  'CAD': _CurrencyRegion('加拿大', 'CA'),
  'CDF': _CurrencyRegion('剛果民主共和國', 'CD'),
  'CHF': _CurrencyRegion('瑞士', 'CH'),
  'CLP': _CurrencyRegion('智利', 'CL'),
  'CNY': _CurrencyRegion('中國', 'CN'),
  'COP': _CurrencyRegion('哥倫比亞', 'CO'),
  'CRC': _CurrencyRegion('哥斯大黎加', 'CR'),
  'CUP': _CurrencyRegion('古巴', 'CU'),
  'CVE': _CurrencyRegion('維德角', 'CV'),
  'CZK': _CurrencyRegion('捷克', 'CZ'),
  'DJF': _CurrencyRegion('吉布地', 'DJ'),
  'DKK': _CurrencyRegion('丹麥', 'DK'),
  'DOP': _CurrencyRegion('多明尼加', 'DO'),
  'DZD': _CurrencyRegion('阿爾及利亞', 'DZ'),
  'EGP': _CurrencyRegion('埃及', 'EG'),
  'ERN': _CurrencyRegion('厄利垂亞', 'ER'),
  'ETB': _CurrencyRegion('衣索比亞', 'ET'),
  'EUR': _CurrencyRegion('歐元區', 'EU'),
  'FJD': _CurrencyRegion('斐濟', 'FJ'),
  'GBP': _CurrencyRegion('英國', 'GB'),
  'GEL': _CurrencyRegion('喬治亞', 'GE'),
  'GHS': _CurrencyRegion('迦納', 'GH'),
  'GIP': _CurrencyRegion('直布羅陀', 'GI'),
  'GMD': _CurrencyRegion('甘比亞', 'GM'),
  'GNF': _CurrencyRegion('幾內亞', 'GN'),
  'GTQ': _CurrencyRegion('瓜地馬拉', 'GT'),
  'GYD': _CurrencyRegion('蓋亞那', 'GY'),
  'HKD': _CurrencyRegion('香港', 'HK'),
  'HNL': _CurrencyRegion('宏都拉斯', 'HN'),
  'HUF': _CurrencyRegion('匈牙利', 'HU'),
  'IDR': _CurrencyRegion('印尼', 'ID'),
  'ILS': _CurrencyRegion('以色列', 'IL'),
  'INR': _CurrencyRegion('印度', 'IN'),
  'IQD': _CurrencyRegion('伊拉克', 'IQ'),
  'IRR': _CurrencyRegion('伊朗', 'IR'),
  'ISK': _CurrencyRegion('冰島', 'IS'),
  'JMD': _CurrencyRegion('牙買加', 'JM'),
  'JOD': _CurrencyRegion('約旦', 'JO'),
  'JPY': _CurrencyRegion('日本', 'JP'),
  'KES': _CurrencyRegion('肯亞', 'KE'),
  'KGS': _CurrencyRegion('吉爾吉斯', 'KG'),
  'KHR': _CurrencyRegion('柬埔寨', 'KH'),
  'KMF': _CurrencyRegion('葛摩', 'KM'),
  'KRW': _CurrencyRegion('韓國', 'KR'),
  'KWD': _CurrencyRegion('科威特', 'KW'),
  'KYD': _CurrencyRegion('開曼群島', 'KY'),
  'KZT': _CurrencyRegion('哈薩克', 'KZ'),
  'LAK': _CurrencyRegion('寮國', 'LA'),
  'LBP': _CurrencyRegion('黎巴嫩', 'LB'),
  'LKR': _CurrencyRegion('斯里蘭卡', 'LK'),
  'LRD': _CurrencyRegion('賴比瑞亞', 'LR'),
  'LYD': _CurrencyRegion('利比亞', 'LY'),
  'MAD': _CurrencyRegion('摩洛哥', 'MA'),
  'MDL': _CurrencyRegion('摩爾多瓦', 'MD'),
  'MGA': _CurrencyRegion('馬達加斯加', 'MG'),
  'MKD': _CurrencyRegion('北馬其頓', 'MK'),
  'MMK': _CurrencyRegion('緬甸', 'MM'),
  'MNT': _CurrencyRegion('蒙古', 'MN'),
  'MOP': _CurrencyRegion('澳門', 'MO'),
  'MRU': _CurrencyRegion('茅利塔尼亞', 'MR'),
  'MUR': _CurrencyRegion('模里西斯', 'MU'),
  'MVR': _CurrencyRegion('馬爾地夫', 'MV'),
  'MWK': _CurrencyRegion('馬拉威', 'MW'),
  'MXN': _CurrencyRegion('墨西哥', 'MX'),
  'MYR': _CurrencyRegion('馬來西亞', 'MY'),
  'MZN': _CurrencyRegion('莫三比克', 'MZ'),
  'NAD': _CurrencyRegion('納米比亞', 'NA'),
  'NGN': _CurrencyRegion('奈及利亞', 'NG'),
  'NIO': _CurrencyRegion('尼加拉瓜', 'NI'),
  'NOK': _CurrencyRegion('挪威', 'NO'),
  'NPR': _CurrencyRegion('尼泊爾', 'NP'),
  'NZD': _CurrencyRegion('紐西蘭', 'NZ'),
  'OMR': _CurrencyRegion('阿曼', 'OM'),
  'PAB': _CurrencyRegion('巴拿馬', 'PA'),
  'PEN': _CurrencyRegion('秘魯', 'PE'),
  'PGK': _CurrencyRegion('巴布亞紐幾內亞', 'PG'),
  'PHP': _CurrencyRegion('菲律賓', 'PH'),
  'PKR': _CurrencyRegion('巴基斯坦', 'PK'),
  'PLN': _CurrencyRegion('波蘭', 'PL'),
  'PYG': _CurrencyRegion('巴拉圭', 'PY'),
  'QAR': _CurrencyRegion('卡達', 'QA'),
  'RON': _CurrencyRegion('羅馬尼亞', 'RO'),
  'RSD': _CurrencyRegion('塞爾維亞', 'RS'),
  'RUB': _CurrencyRegion('俄羅斯', 'RU'),
  'RWF': _CurrencyRegion('盧安達', 'RW'),
  'SAR': _CurrencyRegion('沙烏地阿拉伯', 'SA'),
  'SBD': _CurrencyRegion('索羅門群島', 'SB'),
  'SCR': _CurrencyRegion('塞席爾', 'SC'),
  'SDG': _CurrencyRegion('蘇丹', 'SD'),
  'SEK': _CurrencyRegion('瑞典', 'SE'),
  'SGD': _CurrencyRegion('新加坡', 'SG'),
  'SHP': _CurrencyRegion('聖赫勒拿', 'SH'),
  'SLE': _CurrencyRegion('獅子山', 'SL'),
  'SOS': _CurrencyRegion('索馬利亞', 'SO'),
  'SRD': _CurrencyRegion('蘇利南', 'SR'),
  'SSP': _CurrencyRegion('南蘇丹', 'SS'),
  'STN': _CurrencyRegion('聖多美普林西比', 'ST'),
  'SYP': _CurrencyRegion('敘利亞', 'SY'),
  'SZL': _CurrencyRegion('史瓦帝尼', 'SZ'),
  'THB': _CurrencyRegion('泰國', 'TH'),
  'TJS': _CurrencyRegion('塔吉克', 'TJ'),
  'TMT': _CurrencyRegion('土庫曼', 'TM'),
  'TND': _CurrencyRegion('突尼西亞', 'TN'),
  'TOP': _CurrencyRegion('東加', 'TO'),
  'TRY': _CurrencyRegion('土耳其', 'TR'),
  'TTD': _CurrencyRegion('千里達及托巴哥', 'TT'),
  'TWD': _CurrencyRegion('台灣', 'TW'),
  'TZS': _CurrencyRegion('坦尚尼亞', 'TZ'),
  'UAH': _CurrencyRegion('烏克蘭', 'UA'),
  'UGX': _CurrencyRegion('烏干達', 'UG'),
  'USD': _CurrencyRegion('美國', 'US'),
  'UYU': _CurrencyRegion('烏拉圭', 'UY'),
  'UZS': _CurrencyRegion('烏茲別克', 'UZ'),
  'VES': _CurrencyRegion('委內瑞拉', 'VE'),
  'VND': _CurrencyRegion('越南', 'VN'),
  'VUV': _CurrencyRegion('萬那杜', 'VU'),
  'WST': _CurrencyRegion('薩摩亞', 'WS'),
  'YER': _CurrencyRegion('葉門', 'YE'),
  'ZAR': _CurrencyRegion('南非', 'ZA'),
  'ZMW': _CurrencyRegion('尚比亞', 'ZM'),
  'ZWL': _CurrencyRegion('辛巴威', 'ZW'),
};
