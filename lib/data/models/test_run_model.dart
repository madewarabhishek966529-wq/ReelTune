import 'package:uuid/uuid.dart';

enum TestStatus { pass, fail, running }

class TestRunModel {
  final String id;
  final String testName;
  final String testSuite;
  final TestStatus status;
  final int durationMs;
  final String message;
  final String? diagnosticLog;
  final DateTime timestamp;

  TestRunModel({
    String? id,
    required this.testName,
    this.testSuite = 'Integration',
    this.status = TestStatus.running,
    this.durationMs = 0,
    this.message = '',
    this.diagnosticLog,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  TestRunModel copyWith({
    String? id,
    String? testName,
    String? testSuite,
    TestStatus? status,
    int? durationMs,
    String? message,
    String? diagnosticLog,
    DateTime? timestamp,
  }) {
    return TestRunModel(
      id: id ?? this.id,
      testName: testName ?? this.testName,
      testSuite: testSuite ?? this.testSuite,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
      message: message ?? this.message,
      diagnosticLog: diagnosticLog ?? this.diagnosticLog,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'test_name': testName,
      'test_suite': testSuite,
      'status': status.name,
      'duration_ms': durationMs,
      'message': message,
      'diagnostic_log': diagnosticLog,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TestRunModel.fromMap(Map<String, dynamic> map) {
    return TestRunModel(
      id: map['id'] as String,
      testName: map['test_name'] as String,
      testSuite: (map['test_suite'] as String?) ?? 'Integration',
      status: TestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TestStatus.pass,
      ),
      durationMs: (map['duration_ms'] as int?) ?? 0,
      message: (map['message'] as String?) ?? '',
      diagnosticLog: map['diagnostic_log'] as String?,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
