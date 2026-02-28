import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/invites_supabase_datasource.dart';
import '../../domain/usecases/buyer_invite_usecases.dart';

/// Controller for managing buyer's received auction invites
/// Handles loading, streaming, accepting, and rejecting invites
class BuyerInvitesController extends ChangeNotifier {
  final ListMyInvitesUseCase _listMyInvitesUseCase;
  final RespondToInviteUseCase _respondToInviteUseCase;
  final InvitesSupabaseDatasource _datasource;
  final String _userId;

  BuyerInvitesController({
    required ListMyInvitesUseCase listMyInvitesUseCase,
    required RespondToInviteUseCase respondToInviteUseCase,
    required InvitesSupabaseDatasource datasource,
    required String userId,
  }) : _listMyInvitesUseCase = listMyInvitesUseCase,
       _respondToInviteUseCase = respondToInviteUseCase,
       _datasource = datasource,
       _userId = userId;

  List<Map<String, dynamic>> _invites = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  List<Map<String, dynamic>> get invites => _invites;
  List<Map<String, dynamic>> get pendingInvites =>
      _invites.where((i) => i['status'] == 'pending').toList();
  int get pendingCount => pendingInvites.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load invites via RPC (initial load)
  Future<void> loadInvites() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _listMyInvitesUseCase();
    result.fold(
      (failure) => _errorMessage = failure.message,
      (data) => _invites = data,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Subscribe to realtime invite updates
  void subscribeToInvites() {
    _subscription?.cancel();
    _subscription = _datasource
        .streamMyInvites(_userId)
        .listen(
          (data) {
            _invites = data;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[BuyerInvitesController] Stream error: $e');
          },
        );
  }

  /// Accept an invite
  Future<bool> acceptInvite(String inviteId) async {
    final result = await _respondToInviteUseCase(
      inviteId: inviteId,
      decision: 'accepted',
    );
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        // Reload to refresh list
        loadInvites();
        return true;
      },
    );
  }

  /// Reject an invite
  Future<bool> rejectInvite(String inviteId) async {
    final result = await _respondToInviteUseCase(
      inviteId: inviteId,
      decision: 'rejected',
    );
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        loadInvites();
        return true;
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
