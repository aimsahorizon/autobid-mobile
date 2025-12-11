import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/admin_supabase_datasource.dart';
import 'data/datasources/kyc_supabase_datasource.dart';
import 'data/repositories/kyc_repository_impl.dart';
import 'domain/repositories/kyc_repository.dart';
import 'domain/usecases/get_kyc_stats_usecase.dart';
import 'domain/usecases/get_kyc_submissions_usecase.dart';
import 'domain/usecases/get_kyc_document_usecase.dart';
import 'domain/usecases/approve_kyc_usecase.dart';
import 'domain/usecases/reject_kyc_usecase.dart';
import 'domain/usecases/get_document_url_usecase.dart';
import 'presentation/controllers/admin_controller.dart';
import 'presentation/controllers/kyc_controller.dart';

/// Admin Module - Manages admin dashboard and listing reviews
/// DEV ONLY: For testing and simulating admin functionalities
class AdminModule {
  static final AdminModule _instance = AdminModule._internal();
  static AdminModule get instance => _instance;

  AdminModule._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Datasources
  AdminSupabaseDataSource? _dataSource;
  KycSupabaseDataSource? _kycDataSource;

  // Repositories
  KycRepository? _kycRepository;

  // Use cases
  GetKycStatsUseCase? _getKycStatsUseCase;
  GetKycSubmissionsUseCase? _getKycSubmissionsUseCase;
  GetKycDocumentUseCase? _getKycDocumentUseCase;
  ApproveKycUseCase? _approveKycUseCase;
  RejectKycUseCase? _rejectKycUseCase;
  GetDocumentUrlUseCase? _getDocumentUrlUseCase;

  // Controllers
  AdminController? _controller;
  KycController? _kycController;

  // Initialization flag
  bool _isInitialized = false;

  /// Initialize module and datasources
  void initialize() {
    if (_isInitialized) {
      // Already initialized, skip
      return;
    }

    // Initialize datasources
    _dataSource = AdminSupabaseDataSource(_supabase);
    _kycDataSource = KycSupabaseDataSource(_supabase);

    // Initialize repositories
    _kycRepository = KycRepositoryImpl(_kycDataSource!);

    // Initialize use cases
    _getKycStatsUseCase = GetKycStatsUseCase(_kycRepository!);
    _getKycSubmissionsUseCase = GetKycSubmissionsUseCase(_kycRepository!);
    _getKycDocumentUseCase = GetKycDocumentUseCase(_kycRepository!);
    _approveKycUseCase = ApproveKycUseCase(_kycRepository!);
    _rejectKycUseCase = RejectKycUseCase(_kycRepository!);
    _getDocumentUrlUseCase = GetDocumentUrlUseCase(_kycRepository!);

    _isInitialized = true;
  }

  /// Get or create admin controller
  AdminController get controller {
    if (_dataSource == null) {
      throw StateError('AdminModule not initialized. Call initialize() first.');
    }
    _controller ??= AdminController(_dataSource!);
    return _controller!;
  }

  /// Create a new admin controller instance
  AdminController createController() {
    if (_dataSource == null) {
      throw StateError('AdminModule not initialized. Call initialize() first.');
    }
    return AdminController(_dataSource!);
  }

  /// Get or create KYC controller
  KycController get kycController {
    if (!_isInitialized) {
      throw StateError('AdminModule not initialized. Call initialize() first.');
    }
    _kycController ??= KycController(
      _getKycStatsUseCase!,
      _getKycSubmissionsUseCase!,
      _getKycDocumentUseCase!,
      _approveKycUseCase!,
      _rejectKycUseCase!,
      _getDocumentUrlUseCase!,
    );
    return _kycController!;
  }

  /// Create a new KYC controller instance
  KycController createKycController() {
    if (!_isInitialized) {
      throw StateError('AdminModule not initialized. Call initialize() first.');
    }
    return KycController(
      _getKycStatsUseCase!,
      _getKycSubmissionsUseCase!,
      _getKycDocumentUseCase!,
      _approveKycUseCase!,
      _rejectKycUseCase!,
      _getDocumentUrlUseCase!,
    );
  }

  /// Clean up resources
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _kycController?.dispose();
    _kycController = null;
  }
}
