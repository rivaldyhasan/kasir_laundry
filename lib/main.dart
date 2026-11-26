import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/app_store.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await AppStore.instance.load();
  runApp(const SendShoesApp());
}

class SendShoesApp extends StatelessWidget {
  const SendShoesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final desktop =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Send Shoes Care',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: kHitam)
              .copyWith(primary: kHitam, onPrimary: Colors.white),
          scaffoldBackgroundColor: kLatar,
          appBarTheme: const AppBarTheme(
            backgroundColor: kLatar,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: kGaris),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: kHitam,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Di desktop, tampilkan aplikasi dalam bingkai selebar HP.
        builder: (context, child) {
          if (!desktop) return child!;
          return ColoredBox(
            color: const Color(0xFF263238),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 390,
                  height: double.infinity,
                  child: child,
                ),
              ),
            ),
          );
        },
        home: store.user == null ? const LoginScreen() : const HomeScreen(),
      ),
    );
  }
}
