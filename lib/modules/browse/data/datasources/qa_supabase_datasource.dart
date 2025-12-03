import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for Q&A operations
/// Handles questions and answers on auction listings
class QASupabaseDataSource {
  final SupabaseClient _supabase;

  QASupabaseDataSource(this._supabase);

  /// Get Q&A for an auction
  /// Fetches public questions with asker info from user_profiles
  Future<List<Map<String, dynamic>>> getQA(String vehicleId) async {
    try {
      final response = await _supabase
          .from('qa_entries')
          .select('id, question, answer, created_at, answered_at, user_profiles!asker_id(username, profile_photo_url)')
          .eq('vehicle_id', vehicleId)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get Q&A: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get Q&A: $e');
    }
  }

  /// Ask a question on an auction
  /// Inserts into qa_entries table
  Future<void> askQuestion({
    required String vehicleId,
    required String askerId,
    required String question,
    bool isPublic = true,
  }) async {
    try {
      await _supabase.from('qa_entries').insert({
        'vehicle_id': vehicleId,
        'asker_id': askerId,
        'question': question,
        'is_public': isPublic,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to ask question: ${e.message}');
    } catch (e) {
      throw Exception('Failed to ask question: $e');
    }
  }

  /// Answer a question (seller only, enforced by RLS)
  /// Updates qa_entries with answer and timestamp
  Future<void> answerQuestion({
    required String qaId,
    required String answer,
  }) async {
    try {
      await _supabase.from('qa_entries').update({
        'answer': answer,
        'answered_at': DateTime.now().toIso8601String(),
      }).eq('id', qaId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to answer question: ${e.message}');
    } catch (e) {
      throw Exception('Failed to answer question: $e');
    }
  }

  /// Get questions asked by user
  /// Useful for user's Q&A history
  Future<List<Map<String, dynamic>>> getUserQuestions(String userId) async {
    try {
      final response = await _supabase
          .from('qa_entries')
          .select('id, question, answer, created_at, answered_at, vehicles!vehicle_id(id, brand, model, year)')
          .eq('asker_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user questions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user questions: $e');
    }
  }
}
