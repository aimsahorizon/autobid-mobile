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
  final testDir = Directory('test');
  final projectName = _getProjectName();

  if (!libDir.existsSync()) {
    print('lib directory not found.');
    return;
  }

  int createdCount = 0;

  void processDirectory(Directory dir) {
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        if (p.split(entity.path).contains('unused')) continue;
        processDirectory(entity);
      } else if (entity is File) {
        final path = entity.path;
        if (!path.endsWith('.dart') || 
            path.endsWith('.g.dart') || 
            path.endsWith('.freezed.dart') || 
            p.basename(path) == 'main.dart') {
          continue;
        }

        final relativePath = p.relative(path, from: libDir.path);
        final testPath = p.join(testDir.path, p.withoutExtension(relativePath) + '_test.dart');

        final testFile = File(testPath);
        if (!testFile.existsSync()) {
          testFile.parent.createSync(recursive: true);
          
          final baseName = p.basenameWithoutExtension(path);
          final className = baseName.split('_').map((s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1)).join('');
          
          // Construct the package import path
          final importPath = 'package:$projectName/${relativePath.replaceAll(r'\', '/')}';
          
          String content = '';
          if (relativePath.contains('presentation')) {
            content = '''
import 'package:flutter_test/flutter_test.dart';
import '$importPath';

void main() {
  group('$className Tests', () {
    testWidgets('renders successfully', (WidgetTester tester) async {
      // TODO: Implement widget/controller test following the pyramid
    });
  });
}
''';
          } else {
            content = '''
import 'package:flutter_test/flutter_test.dart';
import '$importPath';

void main() {
  group('$className Tests', () {
    test('initial behavior', () {
      // TODO: Implement unit test following the pyramid
    });
  });
}
''';
          }
          
          testFile.writeAsStringSync(content);
          createdCount++;
        }
      }
    }
  }

  processDirectory(libDir);
  print('Total test files created: $createdCount');
}
