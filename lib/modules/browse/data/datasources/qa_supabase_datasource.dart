import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/qa_entity.dart';

class QASupabaseDataSource {
  final SupabaseClient client;

  QASupabaseDataSource(this.client);

  Future<List<QAEntity>> getQuestions(
    String auctionId, {
    String? currentUserId,
  }) async {
    final res = await client
        .from('view_auction_qa')
        .select('*')
        .eq('auction_id', auctionId)
        .order('asked_at', ascending: false);

    return (res as List<dynamic>)
        .map((j) => _fromViewRow(j, currentUserId: currentUserId))
        .toList();
  }

  Future<QAEntity> postQuestion({
    required String auctionId,
    required String userId,
    required String category,
    required String question,
  }) async {
    final inserted = await client
        .from('auction_questions')
        .insert({
          'auction_id': auctionId,
          'user_id': userId,
          'category': category,
          'question': question,
        })
        .select('id, auction_id, user_id, category, question, created_at')
        .single();

    return QAEntity(
      id: inserted['id'] as String,
      auctionId: inserted['auction_id'] as String,
      category: inserted['category'] as String,
      question: inserted['question'] as String,
      askedBy: 'You',
      askedAt: DateTime.parse(inserted['created_at'] as String),
      answer: null,
      answeredAt: null,
      likesCount: 0,
      isLikedByUser: false,
    );
  }

  Future<void> postAnswer({
    required String questionId,
    required String sellerId,
    required String answer,
  }) async {
    await client.from('auction_answers').insert({
      'question_id': questionId,
      'seller_id': sellerId,
      'answer': answer,
    });

    // Update answered_at on question for convenience
    await client
        .from('auction_questions')
        .update({'answered_at': DateTime.now().toIso8601String()})
        .eq('id', questionId);
  }

  Future<void> likeQuestion({
    required String questionId,
    required String userId,
  }) async {
    await client.from('auction_question_likes').insert({
      'question_id': questionId,
      'user_id': userId,
    });
  }

  Future<void> unlikeQuestion({
    required String questionId,
    required String userId,
  }) async {
    await client
        .from('auction_question_likes')
        .delete()
        .eq('question_id', questionId)
        .eq('user_id', userId);
  }

  Stream<List<QAEntity>> subscribeToQA(
    String auctionId, {
    String? currentUserId,
  }) {
    final controller = StreamController<List<QAEntity>>();
    final channel = client.channel('qa-auction-$auctionId');

    // Subscribe to Postgres Changes for questions, answers, and likes
    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'auction_questions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'auction_id',
          value: auctionId,
        ),
        callback: (_) => _emitSnapshot(auctionId, currentUserId, controller),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'auction_questions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'auction_id',
          value: auctionId,
        ),
        callback: (_) => _emitSnapshot(auctionId, currentUserId, controller),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'auction_answers',
        callback: (_) => _emitSnapshot(auctionId, currentUserId, controller),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'auction_question_likes',
        callback: (_) => _emitSnapshot(auctionId, currentUserId, controller),
      )
      ..subscribe();

    // Initial load
    _emitSnapshot(auctionId, currentUserId, controller);

    controller.onCancel = () async {
      await client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<void> _emitSnapshot(
    String auctionId,
    String? currentUserId,
    StreamController<List<QAEntity>> controller,
  ) async {
    try {
      final items = await getQuestions(auctionId, currentUserId: currentUserId);
      if (!controller.isClosed) {
        controller.add(items);
      }
    } catch (e) {
      // ignore errors but keep stream alive
    }
  }

  QAEntity _fromViewRow(dynamic j, {String? currentUserId}) {
    final likes = (j['likes_count'] ?? 0) as int;
    final profileData = j['profiles'] as Map<String, dynamic>?;
    final displayName =
        profileData?['display_name'] as String? ??
        profileData?['full_name'] as String? ??
        'User';

    final likesData = j['auction_question_likes'] as List<dynamic>?;
    final likedByUser = likesData != null && currentUserId != null
        ? likesData.any((like) => like['user_id'] == currentUserId)
        : false;

    return QAEntity(
      id: j['id'] as String,
      auctionId: j['auction_id'] as String,
      category: (j['category'] as String?) ?? 'general',
      question: (j['question'] as String?) ?? '',
      askedBy: displayName,
      askedAt: DateTime.parse(j['asked_at'] as String),
      answer: j['answer'] as String?,
      answeredAt: j['answered_at'] != null
          ? DateTime.parse(j['answered_at'] as String)
          : null,
      likesCount: likes,
      isLikedByUser: likedByUser,
    );
  }
}
