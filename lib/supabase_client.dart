import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static final client = Supabase.initialize(
    url: 'https://fohrxkshppelbzhxnbat.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvaHJ4a3NocHBlbGJ6aHhuYmF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg0NDE1MTcsImV4cCI6MjA1NDAxNzUxN30.4aCiPbdMrQE6rmBbAw5PvEHLSL88jVe9lUYshcnGW-E',
  );
}
