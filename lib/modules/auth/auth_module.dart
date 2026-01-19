import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../profile/profile_module.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/send_email_otp_usecase.dart';
import 'domain/usecases/send_password_reset_usecase.dart';
import 'domain/usecases/send_phone_otp_usecase.dart';
import 'domain/usecases/sign_in_usecase.dart';
import 'domain/usecases/sign_in_with_google_usecase.dart';
import 'domain/usecases/sign_up_usecase.dart';
import 'domain/usecases/verify_email_otp_usecase.dart';
import 'domain/usecases/verify_otp_usecase.dart';
import 'domain/usecases/verify_phone_otp_usecase.dart';
import 'domain/usecases/reset_password_usecase.dart';
import '../profile/domain/usecases/check_email_exists_usecase.dart';
import '../profile/domain/usecases/get_user_profile_by_email_usecase.dart';

import 'presentation/controllers/forgot_password_controller.dart';
import 'presentation/controllers/kyc_registration_controller.dart';
import 'presentation/controllers/login_controller.dart';
import 'presentation/controllers/login_otp_controller.dart';
import 'presentation/controllers/registration_controller.dart';

/// Initialize Auth module dependencies
Future<void> initAuthModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SendEmailOtpUseCase(sl()));
  sl.registerLazySingleton(() => SendPhoneOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyEmailOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPhoneOtpUseCase(sl()));

  // Controllers (Factory)
  sl.registerFactory(() => LoginController(
    signInUseCase: sl(),
    signInWithGoogleUseCase: sl(),
    checkEmailExistsUseCase: sl(), // Registered in initProfileModule
    getUserProfileByEmailUseCase: sl(), // Registered in initProfileModule
  ));

  sl.registerFactory(() => LoginOtpController(
    sendEmailOtpUseCase: sl(),
    sendPhoneOtpUseCase: sl(),
    verifyEmailOtpUseCase: sl(),
    verifyPhoneOtpUseCase: sl(),
  ));

  sl.registerFactory(() => ForgotPasswordController(
    sendPasswordResetUseCase: sl(),
    verifyOtpUseCase: sl(),
    resetPasswordUseCase: sl(),
  ));

  sl.registerFactory(() => RegistrationController(
    signUpUseCase: sl(),
  ));

  sl.registerFactory(() => KYCRegistrationController(
    authDataSource: sl(), // Needs AuthRemoteDataSource
    sendEmailOtpUseCase: sl(),
    sendPhoneOtpUseCase: sl(),
    verifyEmailOtpUseCase: sl(),
    verifyPhoneOtpUseCase: sl(),
  ));
}

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
  late final ResetPasswordUseCase _resetPasswordUseCase;
  late final SignUpUseCase _signUpUseCase;
  late final SendEmailOtpUseCase _sendEmailOtpUseCase;
  late final SendPhoneOtpUseCase _sendPhoneOtpUseCase;
  late final VerifyEmailOtpUseCase _verifyEmailOtpUseCase;
  late final VerifyPhoneOtpUseCase _verifyPhoneOtpUseCase;

  // Profile Use Cases (Cross-module)
  late final CheckEmailExistsUseCase _checkEmailExistsUseCase;
  late final GetUserProfileByEmailUseCase _getUserProfileByEmailUseCase;


  AuthModule._() {
    _initializeDependencies();
  }

  static AuthModule get instance {
    _instance ??= AuthModule._();
    return _instance!;
  }

  void _initializeDependencies() {
    // Datasources - inject Supabase client
    _remoteDataSource = AuthRemoteDataSourceImpl(SupabaseConfig.client);

    // Repositories
    _authRepository = AuthRepositoryImpl(_remoteDataSource);
    final profileRepository = ProfileModule.instance.repository;

    // Use cases
    _signInUseCase = SignInUseCase(_authRepository);
    _signInWithGoogleUseCase = SignInWithGoogleUseCase(_authRepository);
    _sendPasswordResetUseCase = SendPasswordResetUseCase(_authRepository);
    _verifyOtpUseCase = VerifyOtpUseCase(_authRepository);
    _resetPasswordUseCase = ResetPasswordUseCase(_authRepository);
    _signUpUseCase = SignUpUseCase(_authRepository);
    _sendEmailOtpUseCase = SendEmailOtpUseCase(_authRepository);
    _sendPhoneOtpUseCase = SendPhoneOtpUseCase(_authRepository);
    _verifyEmailOtpUseCase = VerifyEmailOtpUseCase(_authRepository);
    _verifyPhoneOtpUseCase = VerifyPhoneOtpUseCase(_authRepository);
    
    // Profile Use Cases
    _checkEmailExistsUseCase = CheckEmailExistsUseCase(profileRepository);
    _getUserProfileByEmailUseCase = GetUserProfileByEmailUseCase(profileRepository);
  }

  // Controllers
  LoginController createLoginController() {
    return LoginController(
      signInUseCase: _signInUseCase,
      signInWithGoogleUseCase: _signInWithGoogleUseCase,
      checkEmailExistsUseCase: _checkEmailExistsUseCase,
      getUserProfileByEmailUseCase: _getUserProfileByEmailUseCase,
    );
  }

  LoginOtpController createLoginOtpController() {
    return LoginOtpController(
      sendEmailOtpUseCase: _sendEmailOtpUseCase,
      sendPhoneOtpUseCase: _sendPhoneOtpUseCase,
      verifyEmailOtpUseCase: _verifyEmailOtpUseCase,
      verifyPhoneOtpUseCase: _verifyPhoneOtpUseCase,
    );
  }

  ForgotPasswordController createForgotPasswordController() {
    return ForgotPasswordController(
      sendPasswordResetUseCase: _sendPasswordResetUseCase,
      verifyOtpUseCase: _verifyOtpUseCase,
      resetPasswordUseCase: _resetPasswordUseCase,
    );
  }

  RegistrationController createRegistrationController() {
    return RegistrationController(
      signUpUseCase: _signUpUseCase,
    );
  }

  /// Create KYC registration controller with Supabase integration
  /// Injects AuthRemoteDataSource and OTP use cases for KYC registration
  KYCRegistrationController createKYCRegistrationController() {
    return KYCRegistrationController(
      authDataSource: _remoteDataSource,
      sendEmailOtpUseCase: _sendEmailOtpUseCase,
      sendPhoneOtpUseCase: _sendPhoneOtpUseCase,
      verifyEmailOtpUseCase: _verifyEmailOtpUseCase,
      verifyPhoneOtpUseCase: _verifyPhoneOtpUseCase,
    );
  }
}