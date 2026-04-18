import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/mystery_tiebreaker_session_entity.dart';
import 'package:autobid_mobile/modules/bids/data/datasources/mystery_tiebreaker_datasource.dart';

class MysteryTiebreakerController extends ChangeNotifier {
  final String auctionId;
  final String? currentUserId;

  MysteryTiebreakerController({required this.auctionId, this.currentUserId});

  TiebreakerSessionEntity? _session;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  // RPS reveal state (transient animation data)
  String? _lastRevealedP1Choice;
  String? _lastRevealedP2Choice;
  bool _showReveal = false;

  TiebreakerSessionEntity? get session => _session;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get lastRevealedP1Choice => _lastRevealedP1Choice;
  String? get lastRevealedP2Choice => _lastRevealedP2Choice;
  bool get showReveal => _showReveal;

  RealtimeChannel? _channel;

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> init() async {
    await load();
    _channel = MysteryTiebreakerDatasource.instance.subscribeToSession(
      auctionId: auctionId,
      onUpdate: _onRealtimeUpdate,
    );
  }

  void _onRealtimeUpdate() {
    load(silent: true);
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;
    final session = await MysteryTiebreakerDatasource.instance.getSession(
      auctionId,
    );

    // Detect round reveal transition
    if (session != null && _session != null) {
      final prev = _session!;
      if (session.rpsRounds.length > prev.rpsRounds.length) {
        final latest = session.rpsRounds.last;
        _lastRevealedP1Choice = latest.p1Choice;
        _lastRevealedP2Choice = latest.p2Choice;
        _showReveal = true;
      }
    }

    _session = session;
    _isLoading = false;
    notifyListeners();
  }

  void clearReveal() {
    _showReveal = false;
    notifyListeners();
  }

  Future<bool> setReady() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    final result = await MysteryTiebreakerDatasource.instance.setReady(
      auctionId,
    );
    _isProcessing = false;
    if (!result.success) {
      _errorMessage = result.error;
    }
    await load(silent: true);
    return result.success;
  }

  Future<bool> submitChoice(String choice) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    final result = await MysteryTiebreakerDatasource.instance.submitRpsChoice(
      auctionId,
      choice,
    );
    _isProcessing = false;
    if (!result.success) {
      _errorMessage = result.error;
    }
    await load(silent: true);
    return result.success;
  }

  Future<void> checkTimeout() async {
    if (_session == null) return;
    if (!_session!.isDeadlinePassed) return;
    if (_session!.status != TiebreakerStatus.waitingReady) return;
    await MysteryTiebreakerDatasource.instance.processTimeout(auctionId);
    await load(silent: true);
  }
}
