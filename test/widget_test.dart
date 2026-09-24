import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reeltune/app/app.dart';
import 'package:reeltune/core/services/workspace_service.dart';
import 'package:reeltune/data/database/database_service.dart';
import 'package:reeltune/shared/widgets/volume_meter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await WorkspaceService().init('build/test_workspace');
    await DatabaseService().init();
  });

  testWidgets('ReelTuneApp launches and renders Home Screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ReelTuneApp(),
      ),
    );

    // Pump frames
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify ReelTune branding and main actions
    expect(find.text('ReelTune'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('Import Video'), findsOneWidget);
  });

  testWidgets('VolumeMeterWidget renders stereo bars', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VolumeMeterWidget(leftDb: -12.0, rightDb: -18.0),
        ),
      ),
    );

    expect(find.text('L'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });
}
