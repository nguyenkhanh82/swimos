import 'dart:io';

void main() {
  final files = [
    'lib/src/features/profile/presentation/profile_screen.dart',
    'lib/src/features/records/presentation/records_screen.dart',
    'lib/src/features/training/presentation/training_screen.dart',
    'lib/src/features/meets/presentation/meets_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('Skipping $path');
      continue;
    }
    String content = file.readAsStringSync();

    // Fix scaffold backgrounds
    content = content.replaceAll(
      'backgroundColor: const Color(0xFFF8FAFC),',
      'backgroundColor: Colors.transparent,',
    );
    // Add transparent background to Scaffolds that don't have one
    content = content.replaceAll(
      'return Scaffold(\n      appBar: AppBar(',
      'return Scaffold(\n      backgroundColor: Colors.transparent,\n      appBar: AppBar(',
    );

    // Fix AppBars
    content = content.replaceAll(
      "backgroundColor: Colors.white,\n        elevation: 0,",
      "backgroundColor: Colors.transparent,\n        elevation: 0,",
    );

    // Dark text colors to white
    content = content.replaceAll(
      'color: const Color(0xFF0F172A)',
      'color: Colors.white',
    );
    content = content.replaceAll(
      'color: const Color(0xFF64748B)',
      'color: Colors.white70',
    );
    content = content.replaceAll(
      'color: const Color(0xFF94A3B8)',
      'color: Colors.white54',
    );

    // Grey text colors to white
    content = content.replaceAll(
      'color: Colors.grey[700]',
      'color: Colors.white',
    );
    content = content.replaceAll(
      'color: Colors.grey[600]',
      'color: Colors.white70',
    );
    content = content.replaceAll(
      'color: Colors.grey[400]',
      'color: Colors.white54',
    );

    // Fix Cards/Containers
    content = content.replaceAll(
      'color: Colors.white,\n                borderRadius: BorderRadius.circular(24),',
      'color: Colors.white.withValues(alpha: 0.05),\n                borderRadius: BorderRadius.circular(24),\n                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),',
    );
    content = content.replaceAll(
      'color: Colors.white,\n            borderRadius: BorderRadius.circular(16),',
      'color: Colors.white.withValues(alpha: 0.05),\n            borderRadius: BorderRadius.circular(16),\n            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),',
    );

    // Box shadows
    content = content.replaceAll(
      'color: Colors.black.withValues(alpha: 0.05),',
      'color: Colors.black.withValues(alpha: 0.2),',
    );
    content = content.replaceAll(
      'color: Colors.black.withValues(alpha: 0.02),',
      'color: Colors.black.withValues(alpha: 0.2),',
    );

    file.writeAsStringSync(content);
    print('Processed $path');
  }
}
