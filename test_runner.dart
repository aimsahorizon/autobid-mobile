import 'dart:convert';
import 'dart:io';

class TestCase {
  final String name;
  final String result;
  final String? error;
  TestCase(this.name, this.result, this.error);
}

class TestFile {
  final String path;
  final List<TestCase> standard = [];
  final List<TestCase> regression = [];
  final List<TestCase> other = [];

  TestFile(this.path);
}

class TestModule {
  final String name;
  final Map<String, TestFile> unit = {};
  final Map<String, TestFile> widget = {};
  final Map<String, TestFile> integration = {};

  TestModule(this.name);
}

void main(List<String> args) async {
  print('\x1B[2J\x1B[0;0H'); // Clear screen
  print('\x1B[1;35m============================================================\x1B[0m');
  print('\x1B[1;35m🚀 AUTOBID INTERACTIVE TUI TEST RUNNER\x1B[0m');
  print('\x1B[1;35m============================================================\x1B[0m\n');

  stdout.write('\x1B[1;37mWhat would you like to test?\x1B[0m\n[1] Unit & Widget Tests\n[2] Integration Tests\n\x1B[36mSelect (1/2):\x1B[0m ');
  final testMode = stdin.readLineSync()?.trim();

  String targetPath = 'test/';
  if (testMode == '2') {
    targetPath = 'integration_test/';
  } else {
    stdout.write('\n\x1B[1;37mEnter module name (e.g., auth, bids, profile) or "all" for everything:\x1B[0m\n\x1B[36mModule:\x1B[0m ');
    final moduleName = stdin.readLineSync()?.trim().toLowerCase();
    
    if (moduleName != null && moduleName != 'all' && moduleName.isNotEmpty) {
      targetPath = 'test/modules/$moduleName/';
    }
  }

  print('\n\x1B[1;32m▶ Running tests in background. Please wait...\x1B[0m\n');

  final process = await Process.start(
    'flutter', 
    ['test', '--machine', '-j', '1', targetPath], 
    runInShell: true
  );

  final Map<int, Map<String, dynamic>> testMeta = {};
  final Map<int, String> suitePaths = {};
  final Map<int, String> groupNames = {};
  final Map<int, String> testErrors = {};

  int passCount = 0;
  int failCount = 0;
  int skipCount = 0;

  process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    if (!line.startsWith('{')) return;
    try {
      final data = jsonDecode(line);
      final type = data['type'];
      
      if (type == 'suite') {
        suitePaths[data['suite']['id']] = data['suite']['path'];
      } else if (type == 'group') {
        final group = data['group'];
        groupNames[group['id']] = group['name'];
      } else if (type == 'testStart') {
        final test = data['test'];
        testMeta[test['id']] = test;
      } else if (type == 'error') {
        final error = data['error'];
        final testId = data['testID'];
        testErrors[testId] = error;
      } else if (type == 'testDone') {
        final testId = data['testID'];
        final result = data['result'];
        final hidden = data['hidden'];
        if (hidden == true) return;
        
        final test = testMeta[testId];
        if (test == null) return;
        if (test['name'].toString().startsWith('loading ') && result == 'success') return;

        test['finalResult'] = result;
        test['finalError'] = testErrors[testId];
        
        if (result == 'success') passCount++;
        else if (result == 'skipped') skipCount++;
        else failCount++;
      }
    } catch (e) {}
  });

  process.stderr.transform(utf8.decoder).listen((data) {
     print('\x1B[31m$data\x1B[0m');
  });

  final exitCode = await process.exitCode;

  // Now process results
  final Map<String, TestModule> modules = {};

  for (final test in testMeta.values) {
    if (test['finalResult'] == null) continue; // Hidden or not done

    final suiteId = test['suiteID'];
    final suitePath = suitePaths[suiteId] ?? 'Unknown';
    if (test['name'].toString().startsWith('loading ') && test['finalResult'] == 'success') continue;

    // Determine module
    String moduleName = 'core';
    final normalizedPath = suitePath.replaceAll(r'\', '/');
    if (normalizedPath.contains('modules/')) {
       final parts = normalizedPath.split('modules/');
       if (parts.length > 1) {
          moduleName = parts[1].split('/')[0];
       }
    } else if (normalizedPath.contains('integration_test/')) {
       moduleName = 'integration';
    }

    modules.putIfAbsent(moduleName, () => TestModule(moduleName));
    final module = modules[moduleName]!;

    // Determine Test Type
    Map<String, TestFile> targetMap;
    if (normalizedPath.contains('integration_test/')) {
       targetMap = module.integration;
    } else if (normalizedPath.contains('presentation/pages') || normalizedPath.contains('presentation/widgets')) {
       targetMap = module.widget;
    } else {
       targetMap = module.unit;
    }

    targetMap.putIfAbsent(normalizedPath, () => TestFile(normalizedPath));
    final testFile = targetMap[normalizedPath]!;

    // Determine Category
    final groupIds = List<int>.from(test['groupIDs'] ?? []);
    bool isStandard = false;
    bool isRegression = false;

    String cleanName = test['name'];
    for (final gid in groupIds) {
       final gName = groupNames[gid] ?? '';
       if (gName.contains('STANDARD BEHAVIOR')) isStandard = true;
       if (gName.contains('REGRESSION')) isRegression = true;
       if (gName.isNotEmpty && cleanName.startsWith(gName)) {
           cleanName = cleanName.substring(gName.length).trim();
       }
    }

    if (cleanName.contains('✅')) cleanName = '✅' + cleanName.split('✅')[1];
    else if (cleanName.contains('❌')) cleanName = '❌' + cleanName.split('❌')[1];
    else if (cleanName.contains('BUG-')) cleanName = '🐛 BUG-' + cleanName.split('BUG-')[1];

    final tCase = TestCase(cleanName, test['finalResult'], test['finalError']);

    if (isStandard) {
       testFile.standard.add(tCase);
    } else if (isRegression) {
       testFile.regression.add(tCase);
    } else {
       testFile.other.add(tCase);
    }
  }

  // Print Tree
  print('\x1B[2J\x1B[0;0H'); // Clear screen
  print('\x1B[1;35m============================================================\x1B[0m');
  print('\x1B[1;35m🚀 AUTOBID INTERACTIVE TUI TEST RUNNER\x1B[0m');
  print('\x1B[1;35m============================================================\x1B[0m\n');

  void printCategory(String catName, List<TestFile> files, String type) {
     bool hasTests = files.any((f) {
        if (type == 'standard') return f.standard.isNotEmpty;
        if (type == 'regression') return f.regression.isNotEmpty;
        return f.other.isNotEmpty;
     });
     if (!hasTests) return;

     print('\n\x1B[1;36m🔹 $catName\x1B[0m');

     for (final f in files) {
        final List<TestCase> cases;
        if (type == 'standard') cases = f.standard;
        else if (type == 'regression') cases = f.regression;
        else cases = f.other;

        if (cases.isEmpty) continue;

        String rel = f.path;
        if (rel.contains('test/')) rel = rel.substring(rel.indexOf('test/'));
        else if (rel.contains('integration_test/')) rel = rel.substring(rel.indexOf('integration_test/'));

        print('  \x1B[3m📄 $rel\x1B[0m');
        for (final c in cases) {
           String resStr;
           if (c.result == 'success') resStr = '\x1B[32m[PASSED]\x1B[0m';
           else if (c.result == 'skipped') resStr = '\x1B[33m[SKIPPED]\x1B[0m';
           else resStr = '\x1B[31m[FAILED]\x1B[0m';

           print('      $resStr \x1B[90m${c.name}\x1B[0m');
           if (c.error != null) {
               final errStr = c.error!.split('\n').take(3).join('\n         ');
               print('         \x1B[41m\x1B[37m ERROR \x1B[0m \x1B[31m$errStr\x1B[0m');
           }
        }
     }
  }

  void printTestType(String title, Map<String, TestFile> fileMap) {
     if (fileMap.isEmpty) return;
     print('\n\x1B[1;33m$title\x1B[0m');
     print('\x1B[1;37m------------------------------------------------------------\x1B[0m');
     
     final files = fileMap.values.toList();
     printCategory('STANDARD BEHAVIOR', files, 'standard');
     printCategory('REGRESSION FIXES', files, 'regression');
     printCategory('OTHER TESTS', files, 'other');
  }

  for (final module in modules.values) {
     if (module.unit.isEmpty && module.widget.isEmpty && module.integration.isEmpty) continue;
     print('\n\x1B[1;35m============================================================\x1B[0m');
     print('\x1B[1;35m📦 MODULE: ${module.name.toUpperCase()}\x1B[0m');
     print('\x1B[1;35m============================================================\x1B[0m');

     printTestType('🧪 UNIT TESTS', module.unit);
     printTestType('📱 WIDGET TESTS', module.widget);
     printTestType('🌐 INTEGRATION TESTS', module.integration);
  }

  print('\n\x1B[1;37m------------------------------------------------------------\x1B[0m');
  if (failCount == 0) {
    print('\x1B[1;32m🎉 ALL TESTS PASSED SUCCESSFULLY!\x1B[0m');
  } else {
    print('\x1B[1;31m💥 SOME TESTS FAILED\x1B[0m');
  }
  print('\x1B[32m$passCount PASSED\x1B[0m | \x1B[31m$failCount FAILED\x1B[0m | \x1B[33m$skipCount SKIPPED\x1B[0m');
  print('\x1B[1;37m------------------------------------------------------------\x1B[0m\n');
  exit(exitCode);
}