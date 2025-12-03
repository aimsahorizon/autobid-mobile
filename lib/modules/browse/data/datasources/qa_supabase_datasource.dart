import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for Q&A operations
/// Handles questions and answers on auction listings
class QASupabaseDataSource {
  final SupabaseClient _supabase;

  QASupabaseDataSource(this._supabase);

  /// Get Q&A for a listing/auction
  /// Fetches public questions without user join to avoid FK issues
  Future<List<Map<String, dynamic>>> getQuestions(String listingId, {String? userId}) async {
    try {
      print('DEBUG [QADataSource]: ========================================');
      print('DEBUG [QADataSource]: Starting Q&A fetch');
      print('DEBUG [QADataSource]: Listing ID: $listingId');
      print('DEBUG [QADataSource]: User ID: $userId');

      final response = await _supabase
          .from('listing_questions')
          .select('id, question, category, answer, answered_at, likes_count, created_at, asker_id')
          .eq('listing_id', listingId)
          .eq('is_public', true)
          .order('created_at', ascending: false);

      print('DEBUG [QADataSource]: Query executed successfully');
      print('DEBUG [QADataSource]: Raw response type: ${response.runtimeType}');
      print('DEBUG [QADataSource]: Response length: ${response.length}');
      print('DEBUG [QADataSource]: Raw response data: $response');

      // If userId provided, check which questions user has liked
      final questions = List<Map<String, dynamic>>.from(response);

      if (userId != null) {
        final likedQuestions = await _getUserLikedQuestions(userId, listingId);
        for (var question in questions) {
          question['user_has_liked'] = likedQuestions.contains(question['id']);
        }
      } else {
        for (var question in questions) {
          question['user_has_liked'] = false;
        }
      }

      return questions;
    } on PostgrestException catch (e) {
      print('ERROR [QADataSource]: Failed to get questions - ${e.message}');
      throw Exception('Failed to get Q&A: ${e.message}');
    } catch (e) {
      print('ERROR [QADataSource]: Exception - $e');
      throw Exception('Failed to get Q&A: $e');
    }
  }

  /// Get list of question IDs that user has liked
  Future<Set<String>> _getUserLikedQuestions(String userId, String listingId) async {
    try {
      final response = await _supabase
          .from('listing_question_likes')
          .select('question_id')
          .eq('user_id', userId);

      return Set<String>.from(response.map((e) => e['question_id'] as String));
    } catch (e) {
      print('WARN [QADataSource]: Failed to get user likes - $e');
      return {};
    }
  }

  /// Ask a question on a listing
  /// Inserts into listing_questions table
  Future<bool> askQuestion({
    required String listingId,
    required String askerId,
    required String category,
    required String question,
  }) async {
    try {
      print('DEBUG [QADataSource]: Asking question on listing $listingId');

      await _supabase.from('listing_questions').insert({
        'listing_id': listingId,
        'asker_id': askerId,
        'question': question,
        'category': category,
        'is_public': true,
      });

      print('DEBUG [QADataSource]: Question posted successfully');
      return true;
    } on PostgrestException catch (e) {
      print('ERROR [QADataSource]: Failed to ask question - ${e.message}');
      throw Exception('Failed to ask question: ${e.message}');
    } catch (e) {
      print('ERROR [QADataSource]: Exception - $e');
      throw Exception('Failed to ask question: $e');
    }
  }

  /// Toggle like on a question
  /// Adds or removes like based on current state
  Future<bool> toggleQuestionLike({
    required String questionId,
    required String userId,
  }) async {
    try {
      print('DEBUG [QADataSource]: Toggling like for question $questionId');

      // Check if already liked
      final existing = await _supabase
          .from('listing_question_likes')
          .select('id')
          .eq('question_id', questionId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike - remove the like
        await _supabase
            .from('listing_question_likes')
            .delete()
            .eq('question_id', questionId)
            .eq('user_id', userId);

        print('DEBUG [QADataSource]: Question unliked');
        return false; // Now unliked
      } else {
        // Like - add the like
        await _supabase.from('listing_question_likes').insert({
          'question_id': questionId,
          'user_id': userId,
        });

        print('DEBUG [QADataSource]: Question liked');
        return true; // Now liked
      }
    } on PostgrestException catch (e) {
      print('ERROR [QADataSource]: Failed to toggle like - ${e.message}');
      throw Exception('Failed to toggle like: ${e.message}');
    } catch (e) {
      print('ERROR [QADataSource]: Exception - $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Answer a question (seller only, enforced by RLS)
  /// Updates listing_questions with answer and timestamp
  Future<void> answerQuestion({
    required String questionId,
    required String answer,
  }) async {
    try {
      await _supabase.from('listing_questions').update({
        'answer': answer,
        'answered_at': DateTime.now().toIso8601String(),
      }).eq('id', questionId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to answer question: ${e.message}');
    } catch (e) {
      throw Exception('Failed to answer question: $e');
    }
  }
}
