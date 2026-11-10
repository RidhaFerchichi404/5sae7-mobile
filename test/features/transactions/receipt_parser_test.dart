import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/domain/receipt_parser.dart';

final _today = DateTime(2026, 11, 10);

void main() {
  test('reads a Tunisian supermarket ticket', () {
    const text = '''
MAGASIN GENERAL
Av. Habib Bourguiba Tunis
Tel 71 000 000
Date: 08/11/2026 18:42
LAIT DELICE 1L      1,350
PAIN                0,200
FROMAGE           12,500
SOUS-TOTAL        14,050
TOTAL TTC         14,050
ESPECES           20,000
RENDU              5,950
''';
    final draft = parseReceipt(text, today: _today);
    expect(draft.total, 14.05);
    expect(draft.date, DateTime(2026, 11, 8));
    expect(draft.merchant, 'Magasin General');
  });

  test('takes the amount printed under the label', () {
    const text = 'Café de Paris\nNet à payer\n7.500 DT\nMerci';
    final draft = parseReceipt(text, today: _today);
    expect(draft.total, 7.5);
    expect(draft.merchant, 'Café de Paris');
  });

  test('without a label, the largest amount that is not cash', () {
    const text = 'Boutique\n2,000\n35,900\nCASH 50,000';
    expect(parseReceipt(text, today: _today).total, 35.9);
  });

  test('handles thousands, ISO dates and ignores future or bad dates', () {
    final draft = parseReceipt(
      'TOTAL 1 250,000\n31/02/2026\n2027-01-01\n2026-10-30',
      today: _today,
    );
    expect(draft.total, 1250);
    expect(draft.date, DateTime(2026, 10, 30));
  });

  test('rebuilds rows when OCR returns labels and amounts as columns', () {
    // Left column first, then the right column, as ML Kit does.
    final text = joinRows([
      (text: 'MONOPRIX', left: 150, top: 10, height: 20),
      (text: 'TOTAL TTC', left: 10, top: 100, height: 20),
      (text: 'ESPECES', left: 10, top: 130, height: 20),
      (text: '22,950', left: 300, top: 102, height: 20),
      (text: '30,000', left: 300, top: 131, height: 20),
    ]);
    expect(text, 'MONOPRIX\nTOTAL TTC  22,950\nESPECES  30,000');
    final draft = parseReceipt(text, today: _today);
    expect(draft.total, 22.95);
    expect(draft.merchant, 'Monoprix');
  });

  test('reads OCR quirks seen on a real scan', () {
    // ML Kit read "TOTAL TTC" as "TOTAL TIC" and "12,500" as "12, 500".
    const text = 'FROMAGE  12, 500\nTOTAL TIC  22,950\nESPECES  30,000';
    expect(parseReceipt(text, today: _today).total, 22.95);
    expect(parseReceipt('Boutique\n12, 500', today: _today).total, 12.5);
  });

  test('nothing readable gives an empty draft', () {
    expect(parseReceipt('', today: _today).isEmpty, isTrue);
    expect(parseReceipt('12 34\n---', today: _today).isEmpty, isTrue);
  });
}
