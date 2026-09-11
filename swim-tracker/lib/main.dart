import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  // Replace these placeholders with your actual Supabase configuration keys
  await Supabase.initialize(
    url: 'https://haljddborueaplgigsia.supabase.co',
    anonKey: 'sb_publishable_bk_IWh1vezTJqe3j9xGcvg_-vvmvzaL',
  );

  runApp(const ProviderScope(child: SwimTrackApp()));
}

