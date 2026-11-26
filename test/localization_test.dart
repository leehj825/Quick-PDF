import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_pdf/l10n.dart';
import 'package:quick_pdf/main.dart';

void main() {
  Future<(String lang, String text)> probe(WidgetTester tester, Locale phoneLocale) async {
    late String lang, text;
    await tester.pumpWidget(QuickPdfApp(
      locale: phoneLocale, // what the OS reports as the system language
      home: Builder(builder: (c) {
        lang = Localizations.localeOf(c).languageCode;
        text = S.of(c)('gallery');
        MaterialLocalizations.of(c).backButtonTooltip; // must exist for every supported language
        return Text(text);
      }),
    ));
    return (lang, text);
  }

  testWidgets('the app follows the phone language (regression: it always showed English)', (tester) async {
    expect((await probe(tester, const Locale('ko', 'KR'))), ('ko', '갤러리에서 선택'));
    expect((await probe(tester, const Locale('ja', 'JP'))).$1, 'ja');
    expect((await probe(tester, const Locale('es', 'ES'))).$1, 'es');
    expect((await probe(tester, const Locale('en', 'US'))), ('en', 'Choose from gallery'));
  });

  testWidgets('unsupported languages fall back to English', (tester) async {
    expect((await probe(tester, const Locale('fr', 'FR'))), ('en', 'Choose from gallery'));
  });
}
