# testing guidelines

# purpose
this document serves as a strict guideline for any ai or developer writing tests in this flutter clean architecture project. it explains the testing pyramid, the mirror directory testing method, specific development scenarios, and provides concrete code examples and ai prompt templates.

# general overview of tests

1. unit tests
why to implement: to verify business logic and data parsing in isolation. they are fast, deterministic, and provide high volume coverage.
how to implement: target domain layer (usecases, entities) and data layer (repositories, datasources). use mockito to mock dependencies. for example, when testing a usecase, mock its repository interface. when testing a repository implementation, mock its remote or local datasource.

2. widget tests
why to implement: to verify ui components and state management controllers. they ensure the ui renders correctly and user interactions trigger the right state changes without needing a full device emulator.
how to implement: target presentation layer (controllers, complex widgets). use pumpwidget to render the component in a test environment, provide mock usecases to the controller, and assert state changes or the presence of specific ui elements.

3. end to end tests
why to implement: to verify critical user journeys across the entire application stack on real devices or emulators, ensuring all layers work together correctly.
how to implement: located in the integration_test folder. use the integration_test package to simulate real user taps, text input, and scrolls across multiple screens.

4. golden tests
why to implement: to verify exact visual representation and catch unintended styling, layout, or theme changes.
how to implement: take a pixel perfect screenshot of a widget and compare it against a baseline image file during the test run using matchesgoldenfile.

# scenarios and ai prompt templates

1. project initialization and preparation
description: setting up the testing environment, creating the mirror directory structure, and establishing mocking standards. the mirror directory method dictates that for every file in lib, there must be an exact corresponding file in test with the same directory path and name appended with _test.dart.
ai prompt template: analyze the lib/[MODULE_NAME] directory and generate a missing test files report based on the mirror directory method. then, generate the build.yaml and mockito annotations required for [MODULE_NAME].

2. feature implementation
description: creating a new feature using behavior driven development and inside out implementation. you must define domain contracts first, test and build usecases, test and build the data layer, and finally test and build the presentation layer.
ai prompt template: i need to implement the [FEATURE_NAME] feature. follow inside out implementation. start by writing the unit tests for the [USECASE_NAME] usecase and its repository interface in the domain layer. once tests are written, implement the usecase to make the tests pass.

3. bug fixing
description: using test driven development specifically for bugs. the failing test first rule applies. identify the flaw, write a regression test that reproduces the bug and fails, fix the implementation code, and watch the regression test pass.
ai prompt template: bug reported in [FILE_NAME]: [BUG_DESCRIPTION]. write a failing regression test in [TEST_FILE_NAME] for this scenario labeled as [BUG_TICKET]. after confirming it fails, modify the implementation to handle it gracefully and make the test pass.

4. requirement change
description: updating existing features where the business logic or expected outcome changes. the existing test must be updated first to reflect the new expected behavior (causing it to fail) before modifying the actual implementation.
ai prompt template: the requirement for [FEATURE_NAME] is changing from [OLD_BEHAVIOR] to [NEW_BEHAVIOR]. update the relevant unit tests in [TEST_FILE_NAME] to expect the new behavior. after they fail, update the implementation code in [FILE_NAME] to make them pass.

5. refactoring
description: cleaning up code, optimizing performance, or restructuring internal logic without changing the expected output. existing tests act as a safety net and must not be modified.
ai prompt template: refactor the [FILE_NAME] to optimize [OPTIMIZATION_GOAL]. do not modify any existing tests. run the tests in [TEST_FILE_NAME] after refactoring to ensure the existing contract is completely unbroken.

6. performance and continuous integration
description: ensuring code quality at scale using automated gates, strict linting, and code coverage thresholds. tests must run automatically on every pull request.
ai prompt template: update the github actions workflow to run flutter analyze, execute all unit and widget tests, and enforce that domain layer code coverage remains above [PERCENTAGE] percent.

# guideline how to test and code examples

1. always maintain the mirror directory structure.
example: if the implementation is at lib/modules/auth/domain/usecases/sign_in_usecase.dart, the test must be at test/modules/auth/domain/usecases/sign_in_usecase_test.dart.

2. test the left and right paths for functional error handling.
since the architecture uses fpdart, every usecase test must explicitly assert both the success data return (Right) and the failure error return (Left).

3. segregate standard tests from regression tests.
professionals group tests logically. use the dart group function to separate standard behavior tests from historical regression tests. label regression tests clearly with the bug ticket number or date.

code example of a professional clean architecture test file:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

// mock definitions go here

void main() {
  late MockMyRepository mockRepository;
  late MyUseCase usecase;

  setUp(() {
    mockRepository = MockMyRepository();
    usecase = MyUseCase(mockRepository);
  });

  group('standard behavior', () {
    test('should return right(data) when repository succeeds', () async {
      // arrange
      when(mockRepository.getData()).thenAnswer((_) async => const Right('success'));
      
      // act
      final result = await usecase.call();
      
      // assert
      expect(result, equals(const Right('success')));
      verify(mockRepository.getData()).called(1);
    });

    test('should return left(failure) when repository fails', () async {
      // arrange
      when(mockRepository.getData()).thenAnswer((_) async => const Left(ServerFailure('error')));
      
      // act
      final result = await usecase.call();
      
      // assert
      expect(result, equals(const Left(ServerFailure('error'))));
      verify(mockRepository.getData()).called(1);
    });
  });

  group('regression tests', () {
    test('bug-104: should handle null input gracefully instead of crashing', () async {
      // arrange
      when(mockRepository.processData(null)).thenAnswer((_) async => const Left(ValidationFailure('input cannot be null')));
      
      // act
      final result = await usecase.call(input: null);
      
      // assert
      expect(result, equals(const Left(ValidationFailure('input cannot be null'))));
    });

    test('bug-219: should not calculate negative dates during timezone shift', () async {
      // arrange specific timezone edge case
      // act
      // assert correct handling
    });
  });
}
```

4. never skip tests during refactoring. if tests fail after a refactor, the refactor is flawed, not the test.

5. keep ui tests focused. widget tests should verify interaction and state delegation (e.g. tapping a button calls controller.submit()), not deep business logic. pure business logic belongs entirely in unit tests. 

# executing tests with preserved output and beautiful tui

to ensure test outputs are displayed clearly, organized by groups, and fully preserved in the terminal (preventing flutter's default behavior where it overwrites passing lines), an interactive custom tui test runner has been added to the project.

simply run the following command and answer the prompts to select what to test:
`dart run test_runner.dart`

for traditional ci/cd logging, you can still use the expanded reporter:
`flutter test --reporter expanded > test_results.log`

for integration tests, run them targeting a specific device or emulator:
`flutter test integration_test/ --reporter expanded`