import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/localization_service.dart';
import 'services/auth_service.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';

/// Main entry point of the Flutter application
/// This function is called when the app starts
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService.init();
  await AuthService.init();
  runApp(const AgroAssistApp());  // Run the app
}

/// Root widget of the application
/// This is a StatelessWidget because it doesn't change
class AgroAssistApp extends StatelessWidget {
  const AgroAssistApp({super.key});

  ThemeData _buildTheme() {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGreen = Color(0xFF66BB6A);
    const backgroundGreen = Color(0xFFF1F8E9);
    const textPrimary = Color(0xFF1B2631);
    const textSecondary = Color(0xFF666666);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: lightGreen,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundGreen,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primaryGreen,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB8D8B8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB8D8B8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: const Color(0xFFDCEDC8),
        backgroundColor: Colors.white,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen);
          }
          return const IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            );
          }
          return GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return MaterialApp(
          title: LocalizationService.tr('AgroAssist'),
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          themeAnimationDuration: const Duration(milliseconds: 300),
          home: AuthService.session == null ? const LoginScreen() : const AppShell(),
        );
      },
    );
  }
}

