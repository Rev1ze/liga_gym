import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrapResult {
  const SupabaseBootstrapResult({
    required this.isConfigured,
    required this.coachMediaBucket,
    this.error,
  });

  static const defaultCoachMediaBucket = 'coach-media';
  static const defaultSupabaseUrl = 'https://miqshsftnwzjpujqzmkh.supabase.co';
  static const defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pcXNoc2Z0bnd6anB1anF6bWtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5Nzc2NjgsImV4cCI6MjA5NTU1MzY2OH0.t_dmV1BeUnhcfdMy4CVdmAi5Nu1NsWbkN6a0hvrOvQU';

  final bool isConfigured;
  final String coachMediaBucket;
  final Object? error;

  static Future<SupabaseBootstrapResult> initialize() async {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: defaultSupabaseUrl,
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: defaultSupabaseAnonKey,
    );
    const coachMediaBucket = String.fromEnvironment(
      'SUPABASE_COACH_MEDIA_BUCKET',
      defaultValue: defaultCoachMediaBucket,
    );

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      return const SupabaseBootstrapResult(
        isConfigured: false,
        coachMediaBucket: coachMediaBucket,
      );
    }

    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      return const SupabaseBootstrapResult(
        isConfigured: true,
        coachMediaBucket: coachMediaBucket,
      );
    } catch (error) {
      debugPrint('Supabase initialization skipped: $error');

      return SupabaseBootstrapResult(
        isConfigured: false,
        coachMediaBucket: coachMediaBucket,
        error: error,
      );
    }
  }
}

final supabaseBootstrapProvider = Provider<SupabaseBootstrapResult>(
  (ref) =>
      throw UnimplementedError('supabaseBootstrapProvider is not overridden'),
);
