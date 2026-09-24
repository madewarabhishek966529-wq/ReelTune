import 'package:reeltune/core/errors/failures.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/data/database/database_service.dart';
import 'package:reeltune/data/models/test_run_model.dart';

class TestRunRepository {
  final DatabaseService _dbService;
  TestRunRepository([DatabaseService? dbService]) : _dbService = dbService ?? DatabaseService();

  Future<List<TestRunModel>> getAllTestRuns() async {
    try {
      final rows = await _dbService.db.query('test_runs', orderBy: 'timestamp DESC');
      return rows.map((r) => TestRunModel.fromMap(r)).toList();
    } catch (e, st) {
      AppLogger.e('TestRunRepository', 'Failed to fetch test runs', e, st);
      return [];
    }
  }

  Future<void> saveTestRun(TestRunModel testRun) async {
    try {
      await _dbService.db.rawInsert(
        '''
        INSERT OR REPLACE INTO test_runs
        (id, test_name, test_suite, status, duration_ms, message, diagnostic_log, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          testRun.id,
          testRun.testName,
          testRun.testSuite,
          testRun.status.name,
          testRun.durationMs,
          testRun.message,
          testRun.diagnosticLog,
          testRun.timestamp.toIso8601String(),
        ],
      );
    } catch (e, st) {
      AppLogger.e('TestRunRepository', 'Failed to save test run', e, st);
      throw DatabaseFailure('Failed to save test run: $e');
    }
  }

  Future<void> clearTestRuns() async {
    try {
      await _dbService.db.delete('test_runs');
    } catch (_) {}
  }
}
