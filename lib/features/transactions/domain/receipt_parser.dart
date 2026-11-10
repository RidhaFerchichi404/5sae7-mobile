/// What a scanned receipt suggests for a new expense. Every field may be
/// missing; the user always checks the form before saving.
class ReceiptDraft {
  const ReceiptDraft({this.total, this.date, this.merchant});

  final double? total;
  final DateTime? date;
  final String? merchant;

  bool get isEmpty => total == null && date == null && merchant == null;
}

// Most specific first: "NET A PAYER" beats a bare "TOTAL".
const _totalWords = [
  'NET A PAYER',
  'A PAYER',
  'TOTAL TTC',
  'TOTAL',
  'MONTANT',
  'AMOUNT',
];
// Lines that look like a total but are not the amount spent.
const _notTotal = ['SOUS', 'SUBTOTAL', 'HT', 'TVA', 'REMISE', 'POINTS'];
// Cash handed over and change are often larger than the total.
const _payment = ['ESPECE', 'CASH', 'RENDU', 'MONNAIE', 'CHANGE', 'RECU'];
const _notMerchant = [
  'TICKET',
  'BIENVENUE',
  'WELCOME',
  'FACTURE',
  'CAISSE',
  'DATE',
  'TEL',
  'FAX',
  'MF',
  'MATRICULE',
];

// 12,500 · 12.500 · 1 250,000 · 45.50 (2 or 3 decimals, as in TND/EUR),
// plus "12, 500", a space OCR often adds after the separator.
final _amount = RegExp(
  r'(?<![\d.,])(\d{1,3}(?:[  ]\d{3})+|\d+)[.,] ?(\d{2,3})(?!\d)',
);
final _dayFirst = RegExp(
  r'(?<!\d)(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4}|\d{2})(?!\d)',
);
final _isoDate = RegExp(r'(?<!\d)(\d{4})-(\d{2})-(\d{2})(?!\d)');

/// One line of OCR text and where it sits on the photo.
typedef OcrLine = ({String text, double left, double top, double height});

/// OCR returns a receipt column by column, so a label and its amount come
/// out far apart. Lines whose vertical centres are close form one printed
/// row, read left to right.
String joinRows(List<OcrLine> lines) {
  double centre(OcrLine line) => line.top + line.height / 2;
  final sorted = [...lines]..sort((a, b) => centre(a).compareTo(centre(b)));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    if (row != null &&
        (centre(line) - centre(row.first)).abs() < row.first.height / 2) {
      row.add(line);
    } else {
      rows.add([line]);
    }
  }
  return [
    for (final row in rows)
      (row..sort((a, b) => a.left.compareTo(b.left)))
          .map((line) => line.text)
          .join('  '),
  ].join('\n');
}

/// Reads OCR text from a Tunisian or French style receipt.
ReceiptDraft parseReceipt(String text, {required DateTime today}) {
  final lines = [
    for (final line in text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  return ReceiptDraft(
    total: _total(lines),
    date: _date(lines, today),
    merchant: _merchant(lines),
  );
}

double? _total(List<String> lines) {
  final keys = [for (final line in lines) _key(line)];
  for (final word in _totalWords) {
    for (var i = lines.length - 1; i >= 0; i--) {
      final key = keys[i];
      if (!key.contains(word) || _hasAny(key, _notTotal)) {
        continue;
      }
      final here = _amounts(lines[i]);
      if (here.isNotEmpty) {
        return here.last;
      }
      // The amount is often printed on the line below its label.
      if (i + 1 < lines.length && !_hasAny(keys[i + 1], _payment)) {
        final below = _amounts(lines[i + 1]);
        if (below.isNotEmpty) {
          return below.first;
        }
      }
    }
  }
  // No label found: the largest amount that is not cash or change.
  final all = [
    for (var i = 0; i < lines.length; i++)
      if (!_hasAny(keys[i], _payment)) ..._amounts(lines[i]),
  ];
  return all.isEmpty ? null : all.reduce((a, b) => a > b ? a : b);
}

List<double> _amounts(String line) {
  return [
    for (final match in _amount.allMatches(line))
      if (double.tryParse(
            '${match[1]!.replaceAll(RegExp(r'[  ]'), '')}.${match[2]}',
          )
          case final value? when value > 0)
        value,
  ];
}

DateTime? _date(List<String> lines, DateTime today) {
  final latest = DateTime(today.year, today.month, today.day);
  final earliest = DateTime(today.year - 2, today.month, today.day);
  for (final line in lines) {
    final candidates = [
      for (final m in _isoDate.allMatches(line))
        _valid(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)),
      for (final m in _dayFirst.allMatches(line))
        _valid(
          m[3]!.length == 2 ? 2000 + int.parse(m[3]!) : int.parse(m[3]!),
          int.parse(m[2]!),
          int.parse(m[1]!),
        ),
    ];
    for (final date in candidates) {
      if (date != null && !date.isAfter(latest) && !date.isBefore(earliest)) {
        return date;
      }
    }
  }
  return null;
}

/// Null when the parts overflow, e.g. 31/02.
DateTime? _valid(int year, int month, int day) {
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

String? _merchant(List<String> lines) {
  for (final line in lines.take(5)) {
    final letters = line.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '').length;
    final key = _key(line);
    if (letters < 3 ||
        letters < line.replaceAll(' ', '').length / 2 ||
        _notMerchant.any((word) => RegExp('\\b$word\\b').hasMatch(key))) {
      continue;
    }
    final name = line.length > 40 ? line.substring(0, 40).trim() : line;
    return name == name.toUpperCase() ? _titleCase(name) : name;
  }
  return null;
}

String _titleCase(String text) => text
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Upper case without accents, so "Net à payer" matches "NET A PAYER".
String _key(String line) {
  const accents = {'À': 'A', 'Â': 'A', 'É': 'E', 'È': 'E', 'Ê': 'E', 'Ç': 'C'};
  var key = line.toUpperCase();
  accents.forEach((from, to) => key = key.replaceAll(from, to));
  return key;
}

bool _hasAny(String key, List<String> words) =>
    words.any((word) => RegExp('\\b$word').hasMatch(key));
