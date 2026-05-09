import 'dart:io';
import 'package:path/path.dart' as p;

String _getProjectName() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) return 'your_app';
  
  final content = pubspecFile.readAsStringSync();
  final nameMatch = RegExp(r'^name:\s+([a-z0-9_]+)', multiLine: true).firstMatch(content);
  return nameMatch?.group(1) ?? 'your_app';
}

void main() {
  final libDir = Directory('lib');
  final projectName = _getProjectName();
  int updatedCount = 0;

  final rawTemplate = r'''
// ==============================================================================
// 🧪 CLEAN ARCHITECTURE TEST: __CLASS_NAME__
// 📍 LAYER: Domain (UseCase)
// 🎯 MODULE: __MODULE_NAME__
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:__PROJECT_NAME__/core/error/failures.dart';

// TODO: Import the actual Usecase and Repository from lib
// import 'package:__PROJECT_NAME__/modules/__MODULE_NAME__/domain/usecases/...';
// import 'package:__PROJECT_NAME__/modules/__MODULE_NAME__/domain/repositories/...';

// ------------------------------------------------------------------------------
// 🛠️ MOCK DEFINITIONS
// ------------------------------------------------------------------------------
class Mock__REPO_NAME__ extends Mock implements __REPO_NAME__ {}

void main() {
  late __CLASS_NAME__ usecase;
  late Mock__REPO_NAME__ mockRepository;

  setUp(() {
    mockRepository = Mock__REPO_NAME__();
    // TODO: inject the mockRepository into the usecase constructor
    // usecase = __CLASS_NAME__(mockRepository);
  });

  // ============================================================================
  // 🔹 STANDARD BEHAVIOR TESTS
  // ============================================================================
  group('🔹 STANDARD BEHAVIOR - __CLASS_NAME__', () {
    
    test('✅ should return Right(data) when repository call is successful', () async {
      // 1. ARRANGE
      // when(() => mockRepository.__METHOD_NAME__(any())).thenAnswer((_) async => Right(testData));

      // 2. ACT
      // final result = await usecase.__METHOD_NAME__(testParams);

      // 3. ASSERT
      // expect(result, equals(Right(testData)));
      // verify(() => mockRepository.__METHOD_NAME__(any())).called(1);
      // verifyNoMoreInteractions(mockRepository);
    });

    test('❌ should return Left(Failure) when repository call fails', () async {
      // 1. ARRANGE
      // final tFailure = ServerFailure('Server Error');
      // when(() => mockRepository.__METHOD_NAME__(any())).thenAnswer((_) async => Left(tFailure));

      // 2. ACT
      // final result = await usecase.__METHOD_NAME__(testParams);

      // 3. ASSERT
      // expect(result, equals(Left(tFailure)));
      // verify(() => mockRepository.__METHOD_NAME__(any())).called(1);
    });
  });

  // ============================================================================
  // 🔴 REGRESSION FIXES
  // ============================================================================
  group('🔴 REGRESSION FIXES', () {
    
    test('BUG-000: Example format - handle edge case correctly without crashing', () async {
      // Write a failing test here first when a bug is reported,
      // Then fix the implementation in lib/ to make this test pass.
    });

  });
}
''';

  void processFiles(Directory targetDir) {
    if (!targetDir.existsSync()) return;
    for (final entity in targetDir.listSync(recursive: true)) {
      if (entity is File && (entity.path.endsWith('usecase.dart') || entity.path.endsWith('usecases.dart'))) {
        if (entity.path.contains('unused') || entity.path.contains('core' + Platform.pathSeparator + 'utils')) continue;

        final relativePath = p.relative(entity.path, from: libDir.path);
        final testPath = p.join('test', p.withoutExtension(relativePath) + '_test.dart');
        final testFile = File(testPath);

        if (testFile.existsSync()) {
          final content = entity.readAsStringSync();
          final classNameMatch = RegExp(r'class\s+([A-Za-z0-9_]+UseCase|[A-Za-z0-9_]+Usecase)').firstMatch(content);
          final repoMatch = RegExp(r'final\s+([A-Za-z0-9_]+Repository)\s+').firstMatch(content);
          final methodMatch = RegExp(r'(Future|Either)<.*?>\s+(call|[A-Za-z0-9_]+)\s*\(').firstMatch(content);

          if (classNameMatch != null && repoMatch != null) {
            final className = classNameMatch.group(1)!;
            final repoName = repoMatch.group(1)!;
            final methodName = methodMatch != null ? methodMatch.group(2)! : 'call';

            final pathParts = relativePath.split(Platform.pathSeparator);
            final moduleName = pathParts.length > 1 ? pathParts[1] : 'core';

            final testContent = rawTemplate
                .replaceAll('__PROJECT_NAME__', projectName)
                .replaceAll('__CLASS_NAME__', className)
                .replaceAll('__REPO_NAME__', repoName)
                .replaceAll('__MODULE_NAME__', moduleName)
                .replaceAll('__METHOD_NAME__', methodName);

            testFile.writeAsStringSync(testContent);
            updatedCount++;
          }
        }
      }
    }
  }

  processFiles(libDir);
  print('Replaced ' + updatedCount.toString() + ' UseCase test files with Clean Architecture strict format.');
}
