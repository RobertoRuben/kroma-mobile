import 'package:flutter/material.dart';
import 'core/core.dart';
import 'features/home/presentation/screens/main_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ModelPreloader.instance.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KromaDev',
      debugShowCheckedModeBanner: false,
      // Smoother page transitions
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling from causing layout jumps
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
      // Light theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: AppColors.lightColorScheme,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.card,
        dividerColor: AppColors.divider,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.primary,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // Dark theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: AppColors.darkColorScheme,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.cardDark,
        dividerColor: AppColors.dividerDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primaryHover,
          unselectedItemColor: AppColors.textSecondaryDark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryHover,
            foregroundColor: Colors.white,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // Follow system theme
      themeMode: ThemeMode.system,
      home: _isInitialized ? const MainScreen() : const _LoadingScreen(),
    );
  }
}

/// Loading screen shown while models are being loaded
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with gradient background
            // App Logo with spherical/modern shape
            // App Logo with spherical/modern shape
            ClipOval(
              child: Image.asset(
                isDark
                    ? 'lib/assets/app-logo-dark.png'
                    : 'lib/assets/app-logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'KromaDev',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inteligencia Agrícola',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: ModelPreloader.instance,
              builder: (context, _) {
                return Text(
                  ModelPreloader.instance.loadingMessage ?? 'Iniciando...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
