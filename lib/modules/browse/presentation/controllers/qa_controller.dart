import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/qa_entity.dart';
import '../../data/datasources/qa_supabase_datasource.dart';

class QAController extends ChangeNotifier {
  final QASupabaseDataSource datasource;
  final String auctionId;
  final String? currentUserId;

  QAController({
    required this.datasource,
    required this.auctionId,
    this.currentUserId,
  });

  List<QAEntity> _items = [];
  bool _loading = false;
  StreamSubscription<List<QAEntity>>? _sub;

  List<QAEntity> get items => _items;
  bool get loading => _loading;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await datasource.getQuestions(
        auctionId,
        currentUserId: currentUserId,
      );
      _sub = datasource
          .subscribeToQA(auctionId, currentUserId: currentUserId)
          .listen((data) {
            _items = data;
            notifyListeners();
          });
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> disposeStream() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> postAnswer(
    String questionId,
    String sellerId,
    String answer,
  ) async {
    await datasource.postAnswer(
      questionId: questionId,
      sellerId: sellerId,
      answer: answer,
    );
    // snapshot will update via realtime subscription
  }

  Future<void> postQuestion(
    String category,
    String question,
    String userId,
  ) async {
    await datasource.postQuestion(
      auctionId: auctionId,
      userId: userId,
      category: category,
      question: question,
    );
  }

  Future<void> like(String questionId, String userId) async {
    await datasource.likeQuestion(questionId: questionId, userId: userId);
  }

  Future<void> unlike(String questionId, String userId) async {
    await datasource.unlikeQuestion(questionId: questionId, userId: userId);
  }
}
