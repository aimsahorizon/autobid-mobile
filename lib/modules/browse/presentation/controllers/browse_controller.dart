import 'package:flutter/material.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/repositories/auction_repository.dart';

class BrowseController extends ChangeNotifier {
  final AuctionRepository _repository;

  BrowseController(this._repository);

  List<AuctionEntity> _auctions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AuctionEntity> get auctions => _auctions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadAuctions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auctions = await _repository.getActiveAuctions();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load auctions';
      _auctions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchAuctions(String query) async {
    if (query.isEmpty) {
      await loadAuctions();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auctions = await _repository.searchAuctions(query);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to search auctions';
      _auctions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
