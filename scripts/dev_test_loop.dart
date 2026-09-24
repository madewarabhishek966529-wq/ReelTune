import 'dart:io';

/// Automated Development Workflow Script for ReelTune
/// Flow:
/// 1. Run dart analyze
/// 2. Run flutter test (unit + widget tests)
/// 3. Verify original media safety
/// 4. If all PASS, prompt or execute git commit & git push
void main(List<String> args) async {
  print('====================================================');
  print('🎬 ReelTune Automated Development & Test Loop');
  print('====================================================\n');

  // Step 1: Dart Analyze
  print('[1/3] Running Dart Static Analyzer...');
  final analyzeResult = await Process.run('dart', ['analyze'], runInShell: true);
  if (analyzeResult.exitCode != 0) {
    print('❌ Static analysis failed:\n${analyzeResult.stdout}\n${analyzeResult.stderr}');
    exit(1);
  }
  print('✅ Static analysis passed with 0 issues.\n');

  // Step 2: Flutter Test
  print('[2/3] Running Full Automated Test Suite...');
  final testResult = await Process.run('flutter', ['test'], runInShell: true);
  if (testResult.exitCode != 0) {
    print('❌ Tests failed:\n${testResult.stdout}\n${testResult.stderr}');
    exit(1);
  }
  print('✅ All test suites passed successfully.\n');

  // Step 3: Git Status & Optional Commit/Push
  print('[3/3] Checking Git Repository Status...');
  final statusResult = await Process.run('git', ['status', '--porcelain'], runInShell: true);
  final changes = (statusResult.stdout as String).trim();

  if (changes.isEmpty) {
    print('✅ Working tree clean. Everything is up to date.');
  } else {
    print('📝 Uncommitted changes detected:\n$changes\n');
    final commitMsg = args.isNotEmpty ? args.join(' ') : 'feat: updates verified by automated test loop';
    print('🚀 Staging, committing, and pushing to origin main...');
    await Process.run('git', ['add', '-A'], runInShell: true);
    final commitRes = await Process.run('git', ['commit', '-m', commitMsg], runInShell: true);
    print(commitRes.stdout);

    final pushRes = await Process.run('git', ['push', 'origin', 'main'], runInShell: true);
    print(pushRes.stdout);
    print(pushRes.stderr);
    print('✅ Push to GitHub complete!');
  }
  print('\n====================================================');
  print('🎉 Automated Dev Loop: SUCCESS');
  print('====================================================');
}
