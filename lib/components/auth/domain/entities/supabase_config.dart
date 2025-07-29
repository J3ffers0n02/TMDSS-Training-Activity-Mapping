import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseConfig {
  static const String supabaseUrl = 'https://iihasbuewkxjoyfxpxwo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpaGFzYnVld2t4am95ZnhweHdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzNzU1MTksImV4cCI6MjA2MDk1MTUxOX0.7CIWvdbYGn90bVFFRkDLE47VIkdNQFH855Kfn8tFDS4';

  static Future<void> initialize() async {
    try
    {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
     print('Supabase initialized successfully');
    } catch (e) {
      print('Supabase initialization failed: $e');
    }
  }
}
  
