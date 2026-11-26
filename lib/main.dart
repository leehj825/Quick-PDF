import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pdfrx/pdfrx.dart';

import 'screens/home_screen.dart';
import 'l10n.dart';
import 'services/reward_service.dart';

const kPrimary = Color(0xFF2563EB);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  await RewardService.instance.init();
  try {
    await MobileAds.instance.initialize();
    RewardService.instance.preload();
  } catch (_) {}
  runApp(const QuickPdfApp());
}

class QuickPdfApp extends StatelessWidget {
  /// [locale] / [home] are only overridden by tests and the store-screenshot renderer.
  const QuickPdfApp({super.key, this.locale, this.home, this.fontFamily, this.fontFamilyFallback});
  final Locale? locale;
  final Widget? home;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: kPrimary, brightness: b).copyWith(
      primary: kPrimary,
      surface: dark ? const Color(0xFF1E293B) : Colors.white,
      outline: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickPDF',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: locale,
      // Without these the app only "knows" en-US, so a Korean/Japanese/Spanish phone
      // would resolve to English and never show the translated strings.
      // English is first so unsupported languages (e.g. French) fall back to English.
      supportedLocales: [for (final l in ['en', ...supportedLangs.where((l) => l != 'en')]) Locale(l)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home ?? const HomeScreen(),
    );
  }
}
