import 'package:flutter/material.dart';
import 'screens/home_screen.dart';  // Import home screen
import 'services/localization_service.dart';

/// Main entry point of the Flutter application
/// This function is called when the app starts
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService.init();
  runApp(const FarmBuddyApp());  // Run the app
}

/// Root widget of the application
/// This is a StatelessWidget because it doesn't change
class FarmBuddyApp extends StatelessWidget {
  const FarmBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return MaterialApp(
          title: LocalizationService.tr('Farm Buddy'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            primaryColor: const Color(0xFF2ECC71),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
