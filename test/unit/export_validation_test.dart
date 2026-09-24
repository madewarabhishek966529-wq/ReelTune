import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reeltune/core/errors/failures.dart';
import 'package:reeltune/core/services/export_validation_service.dart';
import 'package:reeltune/data/models/export_job_model.dart';
import 'package:reeltune/data/models/media_file_model.dart';

void main() {
  group('ExportValidationService Tests', () {
    final validationService = ExportValidationService();

    test('Fails validation if output file does not exist', () async {
      final job = ExportJobModel(
        projectId: 'p_1',
        projectName: 'Test Proj',
        outputFilename: 'missing.mp4',
        outputPath: 'non_existent_dir/missing.mp4',
        presetName: 'Instagram Reel',
        width: 1080,
        height: 1920,
      );

      expect(
        () => validationService.validateExport(job: job, sourceMediaFiles: []),
        throwsA(isA<ExportValidationFailure>()),
      );
    });

    test('Validates successfully when file exists with valid payload', () async {
      final tempFile = File('test/temp_test_export.mp4');
      await tempFile.writeAsBytes(List.filled(100, 0x11));

      final job = ExportJobModel(
        projectId: 'p_1',
        projectName: 'Test Proj',
        outputFilename: 'temp_test_export.mp4',
        outputPath: tempFile.path,
        presetName: 'Instagram Reel',
        width: 1080,
        height: 1920,
      );

      final media = MediaFileModel(
        projectId: 'p_1',
        originalPath: 'test/fixtures/original_input.mp4',
        filename: 'original_input.mp4',
        fileSize: 500,
        duration: 10.0,
      );

      final res = await validationService.validateExport(job: job, sourceMediaFiles: [media]);
      expect(res.isValid, true);
      expect(res.isOriginalSourceSafe, true);

      // Clean up
      if (await tempFile.exists()) await tempFile.delete();
    });

    test('Fails if output path matches source media file path (critical safety)', () async {
      final tempFile = File('test/temp_safety_check.mp4');
      await tempFile.writeAsBytes(List.filled(100, 0x11));

      final job = ExportJobModel(
        projectId: 'p_1',
        projectName: 'Test Proj',
        outputFilename: 'temp_safety_check.mp4',
        outputPath: tempFile.path,
        presetName: 'Instagram Reel',
        width: 1080,
        height: 1920,
      );

      final conflictingMedia = MediaFileModel(
        projectId: 'p_1',
        originalPath: tempFile.path, // Same as output!
        filename: 'temp_safety_check.mp4',
        fileSize: 100,
        duration: 5.0,
      );

      expect(
        () => validationService.validateExport(job: job, sourceMediaFiles: [conflictingMedia]),
        throwsA(isA<ExportValidationFailure>()),
      );

      if (await tempFile.exists()) await tempFile.delete();
    });
  });
}
