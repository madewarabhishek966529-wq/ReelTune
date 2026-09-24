import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/services/workspace_service.dart';
import 'package:reeltune/data/models/test_run_model.dart';
import 'package:reeltune/features/developer/developer_test_runner.dart';

class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  int _selectedIterations = 1;

  @override
  Widget build(BuildContext context) {
    final devState = ref.watch(devTestRunnerProvider);
    final devNotifier = ref.read(devTestRunnerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.terminal_rounded, color: AppTheme.secondary),
            SizedBox(width: 10),
            Text('Automated Test Suite & Dev Loop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clean Temp Files',
            onPressed: () async {
              await WorkspaceService().cleanTempFiles();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Temporary workspace files cleaned.')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Test History',
            onPressed: () => devNotifier.clearHistory(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dev Loop Control Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.replay_circle_filled_rounded, color: AppTheme.primaryAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Continuous Test Loop (Video -> Import -> Process -> Export -> Validate)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Executes full end-to-end media pipeline tests offline. Verifies non-destructive preservation, SQLite persistence, audio beat detection, creative filters, and export integrity.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Iterations:', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _selectedIterations,
                        dropdownColor: AppTheme.surfaceVariant,
                        items: [1, 3, 5, 10].map((it) {
                          return DropdownMenuItem(value: it, child: Text('$it Run${it > 1 ? "s" : ""}'));
                        }).toList(),
                        onChanged: devState.isRunning ? null : (v) => setState(() => _selectedIterations = v ?? 1),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        icon: devState.isRunning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.play_arrow_rounded),
                        label: Text(devState.isRunning ? 'Testing ${devState.currentTestName}...' : 'Run Automated Loop'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        onPressed: devState.isRunning
                            ? null
                            : () => devNotifier.runEndToEndTestLoop(iterations: _selectedIterations),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Counters
            Row(
              children: [
                _buildStatCard('Total Runs', '${devState.totalRuns}', Icons.analytics_outlined, Colors.blueAccent),
                const SizedBox(width: 12),
                _buildStatCard('Passed', '${devState.passedRuns}', Icons.check_circle_outline, AppTheme.accentNeon),
                const SizedBox(width: 12),
                _buildStatCard('Failed', '${devState.failedRuns}', Icons.error_outline, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 20),

            // Test History Table Header
            const Text('Test Results & Diagnostic History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),

            // Test History List
            Expanded(
              child: devState.history.isEmpty
                  ? const Center(
                      child: Text('No test runs recorded yet. Click Run Automated Loop to test.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  : ListView.builder(
                      itemCount: devState.history.length,
                      itemBuilder: (context, index) {
                        final run = devState.history[index];
                        final isPass = run.status == TestStatus.pass;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isPass ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: isPass ? AppTheme.accentNeon : Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      run.testName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${run.message} • ${run.durationMs}ms',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    if (run.diagnosticLog != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          run.diagnosticLog!,
                                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white54),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isPass ? AppTheme.accentNeon : Colors.redAccent).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  run.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPass ? AppTheme.accentNeon : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
