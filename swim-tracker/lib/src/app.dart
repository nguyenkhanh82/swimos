import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routing/app_router.dart';

class SwimTrackApp extends ConsumerStatefulWidget {
  const SwimTrackApp({super.key});

  @override
  ConsumerState<SwimTrackApp> createState() => _SwimTrackAppState();
}

class _SwimTrackAppState extends ConsumerState<SwimTrackApp> {
  @override
  Widget build(BuildContext context) {
    try {
      final goRouter = ref.watch(goRouterProvider);

      return MaterialApp.router(
        title: 'SwimTrack Pro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0891b2), // Cyan/Blue Primary
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.outfitTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF0F9FF), // Light Blue tint
        ),
        themeMode: ThemeMode.dark, // Force dark theme globally
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00E5FF), // Neon Cyan
            brightness: Brightness.dark,
            surface: const Color(0xFF021B33), // Deep Ocean Blue
            primary: const Color(0xFF00E5FF),
            secondary: const Color(0xFF7000FF), // Deep Purple
            tertiary: const Color(0xFF0055FF), // True Blue
          ),
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          scaffoldBackgroundColor: const Color(0xFF010E1A), // Darkest Deep Blue
          cardTheme: const CardThemeData(
            color: Color(0x0DFFFFFF), // Colors.white.withValues(alpha: 0.05)
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              side: BorderSide(color: Color(0x26FFFFFF)), // alpha: 0.15
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF), // Neon Cyan
              foregroundColor: const Color(0xFF010E1A), // Dark Text
              elevation: 10,
              shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF00E5FF)),
            ),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
        ),
        routerConfig: goRouter,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error building SwimTrackApp: $e');
      debugPrint('Stack trace: $stackTrace');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      );
    }
  }
}
