import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/send_password_reset_usecase.dart';
import 'domain/usecases/sign_in_usecase.dart';
import 'domain/usecases/sign_in_with_google_usecase.dart';
import 'domain/usecases/verify_otp_usecase.dart';
import 'presentation/controllers/forgot_password_controller.dart';
import 'presentation/controllers/login_controller.dart';
import 'presentation/controllers/registration_controller.dart';

class AuthModule {
  static AuthModule? _instance;

  // Datasources
  late final AuthRemoteDataSource _remoteDataSource;

  // Repositories
  late final AuthRepository _authRepository;

  // Use cases
  late final SignInUseCase _signInUseCase;
  late final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  late final SendPasswordResetUseCase _sendPasswordResetUseCase;
  late final VerifyOtpUseCase _verifyOtpUseCase;

  AuthModule._() {
    _initializeDependencies();
  }

  static AuthModule get instance {
    _instance ??= AuthModule._();
    return _instance!;
  }

  void _initializeDependencies() {
    // Datasources
    _remoteDataSource = AuthRemoteDataSourceImpl();

    // Repositories
    _authRepository = AuthRepositoryImpl(_remoteDataSource);

    // Use cases
    _signInUseCase = SignInUseCase(_authRepository);
    _signInWithGoogleUseCase = SignInWithGoogleUseCase(_authRepository);
    _sendPasswordResetUseCase = SendPasswordResetUseCase(_authRepository);
    _verifyOtpUseCase = VerifyOtpUseCase(_authRepository);
  }

  // Controllers
  LoginController createLoginController() {
    return LoginController(
      signInUseCase: _signInUseCase,
      signInWithGoogleUseCase: _signInWithGoogleUseCase,
    );
  }

  ForgotPasswordController createForgotPasswordController() {
    return ForgotPasswordController(
      sendPasswordResetUseCase: _sendPasswordResetUseCase,
      verifyOtpUseCase: _verifyOtpUseCase,
    );
  }

  RegistrationController createRegistrationController() {
    return RegistrationController();
  }
}
