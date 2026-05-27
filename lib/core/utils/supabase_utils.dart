import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper to wrap a Supabase stream.
/// If the stream encounters an expired JWT error (InvalidJWTToken),
/// it automatically attempts to refresh the session and retries the subscription.
Stream<T> retryStreamWithAuth<T>(
  Stream<T> Function() streamFactory, {
  int maxRetries = 3,
}) async* {
  int retryCount = 0;
  while (true) {
    try {
      await for (final value in streamFactory()) {
        retryCount = 0; // Reset retry count on successful emission
        yield value;
      }
      break; // Normal stream completion
    } catch (e) {
      final errorStr = e.toString();
      final isExpiredToken = errorStr.contains("InvalidJWTToken") ||
          errorStr.contains("expired") ||
          errorStr.contains("JWT");

      if (isExpiredToken) {
        try {
          // Attempt to refresh the session to get a new valid token
          final response = await Supabase.instance.client.auth.refreshSession();
          if (response.session != null) {
            // Give a tiny moment for auth state to propagate to realtime client
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (authErr) {
          // If refresh fails, we will still back off and retry
        }
      }

      retryCount++;
      if (retryCount > maxRetries) {
        rethrow; // Propagate the error if we exceeded max retries
      }

      // Backoff delay before reconnecting (2s, 4s, 6s)
      await Future.delayed(Duration(seconds: retryCount * 2));
    }
  }
}
