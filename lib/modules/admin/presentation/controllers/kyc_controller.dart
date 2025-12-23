import 'package:flutter/foundation.dart';
import '../../domain/entities/kyc_document_entity.dart';
import '../../domain/entities/kyc_stats_entity.dart';
import '../../domain/usecases/get_kyc_stats_usecase.dart';
import '../../domain/usecases/get_kyc_submissions_usecase.dart';
import '../../domain/usecases/get_kyc_document_usecase.dart';
import '../../domain/usecases/approve_kyc_usecase.dart';
import '../../domain/usecases/reject_kyc_usecase.dart';
import '../../domain/usecases/get_document_url_usecase.dart';

class KycController extends ChangeNotifier {
  final GetKycStatsUseCase _getKycStatsUseCase;
  final GetKycSubmissionsUseCase _getKycSubmissionsUseCase;
  final GetKycDocumentUseCase _getKycDocumentUseCase;
  final ApproveKycUseCase _approveKycUseCase;
  final RejectKycUseCase _rejectKycUseCase;
  final GetDocumentUrlUseCase _getDocumentUrlUseCase;

  KycStatsEntity? _stats;
  List<KycDocumentEntity> _submissions = [];
  KycDocumentEntity? _selectedDocument;
  bool _isLoading = false;
  bool _isLoadingDocument = false;
  String? _error;
  String _selectedStatus = 'pending';
  final Map<String, String> _documentUrlCache = {};

  KycController(
    this._getKycStatsUseCase,
    this._getKycSubmissionsUseCase,
    this._getKycDocumentUseCase,
    this._approveKycUseCase,
    this._rejectKycUseCase,
    this._getDocumentUrlUseCase,
  );

  // Getters
  KycStatsEntity? get stats => _stats;
  List<KycDocumentEntity> get submissions => _submissions;
  KycDocumentEntity? get selectedDocument => _selectedDocument;
  bool get isLoading => _isLoading;
  bool get isLoadingDocument => _isLoadingDocument;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;

  /// Load KYC statistics
  Future<void> loadStats() async {
    try {
      _stats = await _getKycStatsUseCase();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load KYC submissions by status
  Future<void> loadSubmissions({String? status}) async {
    _selectedStatus = status ?? 'pending';
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _submissions = await _getKycSubmissionsUseCase(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load a specific KYC document
  Future<void> loadDocument(String kycDocumentId) async {
    _isLoadingDocument = true;
    _error = null;
    notifyListeners();

    try {
      _selectedDocument = await _getKycDocumentUseCase(kycDocumentId);
      _isLoadingDocument = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingDocument = false;
      notifyListeners();
    }
  }

  /// Approve KYC document
  Future<bool> approveKyc(String kycDocumentId, {String? notes}) async {
    try {
      await _approveKycUseCase(kycDocumentId, notes: notes);

      // Reload data
      await Future.wait([
        loadStats(),
        loadSubmissions(status: _selectedStatus),
      ]);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject KYC document
  Future<bool> rejectKyc(
    String kycDocumentId,
    String reason, {
    String? notes,
  }) async {
    try {
      await _rejectKycUseCase(kycDocumentId, reason, notes: notes);

      // Reload data
      await Future.wait([
        loadStats(),
        loadSubmissions(status: _selectedStatus),
      ]);

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get signed URL for document file
  Future<String?> getDocumentUrl(String filePath) async {
    // Check cache first
    if (_documentUrlCache.containsKey(filePath)) {
      return _documentUrlCache[filePath];
    }

    try {
      final url = await _getDocumentUrlUseCase(filePath);
      _documentUrlCache[filePath] = url;
      return url;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear selected document
  void clearSelectedDocument() {
    _selectedDocument = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadStats(),
      loadSubmissions(status: _selectedStatus),
    ]);
  }
}
