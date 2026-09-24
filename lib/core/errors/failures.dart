class AppFailure implements Exception {
  final String message;
  final String? operation;
  final String? code;
  final dynamic details;
  final DateTime timestamp;

  AppFailure({
    required this.message,
    this.operation,
    this.code,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AppFailure(operation: $operation, code: $code, message: $message)';
}

class MediaValidationFailure extends AppFailure {
  MediaValidationFailure(String message, {String? operation, super.details})
      : super(message: message, operation: operation ?? 'media_validation', code: 'MEDIA_VALIDATION_ERR');
}

class FFmpegExecutionFailure extends AppFailure {
  final int? exitCode;
  final String? stdout;
  final String? stderr;

  FFmpegExecutionFailure(
    String message, {
    this.exitCode,
    this.stdout,
    this.stderr,
    String? operation,
  }) : super(
          message: message,
          operation: operation ?? 'ffmpeg_process',
          code: 'FFMPEG_EXECUTION_ERR',
          details: {
            'exitCode': exitCode,
            'stderr': stderr,
          },
        );
}

class StorageFailure extends AppFailure {
  StorageFailure(String message, {String? operation})
      : super(message: message, operation: operation ?? 'storage', code: 'STORAGE_ERR');
}

class DatabaseFailure extends AppFailure {
  DatabaseFailure(String message, {String? operation, super.details})
      : super(message: message, operation: operation ?? 'database', code: 'DB_ERR');
}

class ExportValidationFailure extends AppFailure {
  ExportValidationFailure(String message, {String? operation, super.details})
      : super(message: message, operation: operation ?? 'export_validation', code: 'EXPORT_VAL_ERR');
}
