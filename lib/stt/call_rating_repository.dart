import 'package:eloquent/eloquent.dart';

import 'call_rater.dart';

/// Persists [CallRating] rows into the `ai_call_ratings` table, keyed by the
/// recording's `file_name` (e.g. `20260825-...​.wav`).
class CallRatingRepository {
  static const String table = 'ai_call_ratings';

  final Connection db;

  CallRatingRepository(this.db);

  /// Inserts or updates the rating for [fileName].
  Future<void> save(String fileName, CallRating rating) async {
    final now = _mysqlNow();
    final values = {
      'introduction': rating.introduction,
      'call_handling': rating.callHandling,
      'closing': rating.closing,
      'overall': rating.overall,
      'feedback': rating.feedback,
      'model': rating.model,
      'updated_at': now,
    };

    final existing = await db
        .table(table)
        .where('file_name', '=', fileName)
        .select(['id'])
        .limit(1)
        .get();

    if (existing.isNotEmpty) {
      await db.table(table).where('file_name', '=', fileName).update(values);
    } else {
      await db.table(table).insert({
        'file_name': fileName,
        ...values,
        'created_at': now,
      });
    }
  }

  static String _mysqlNow() =>
      DateTime.now().toIso8601String().split('.').first.replaceFirst('T', ' ');
}
