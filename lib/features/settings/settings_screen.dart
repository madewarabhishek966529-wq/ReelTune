import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/services/ffmpeg_service.dart';
import 'package:reeltune/core/services/workspace_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, int> _storageStats = {};
  bool _hardwareAccel = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await WorkspaceService().getStorageStats();
    if (mounted) setState(() => _storageStats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final workspace = WorkspaceService();
    final ffmpeg = FFmpegService();

    final totalMb = ((_storageStats['total'] ?? 0) / 1024 / 1024).toStringAsFixed(2);
    final cacheMb = ((_storageStats['cache'] ?? 0) / 1024 / 1024).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Storage & Workspace Card
          Container(
            padding: const EdgeInsets.all(16),
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
                    Icon(Icons.folder_special_outlined, color: AppTheme.primaryAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Workspace Storage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Root Directory: ${workspace.rootDir.path}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total Used: $totalMb MB (Cache: $cacheMb MB)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cleaning_services, size: 16),
                      label: const Text('Clear Cache'),
                      onPressed: () async {
                        await workspace.cleanCache();
                        await _loadStats();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache cleared successfully.')),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep, size: 16),
                      label: const Text('Clear Temp Files'),
                      onPressed: () async {
                        await workspace.cleanTempFiles();
                        await _loadStats();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Temp files cleaned.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Engine & Processing Settings
          Container(
            padding: const EdgeInsets.all(16),
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
                    Icon(Icons.memory, color: AppTheme.secondary, size: 20),
                    SizedBox(width: 8),
                    Text('Media Processing Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hardware Acceleration', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Use GPU encoder (NVENC / QuickSync / MediaCodec) when available',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Switch(
                    value: _hardwareAccel,
                    activeThumbColor: AppTheme.secondary,
                    onChanged: (v) => setState(() => _hardwareAccel = v),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('FFmpeg Engine Status', style: TextStyle(fontSize: 13)),
                  subtitle: Text(
                    ffmpeg.isFFmpegAvailable
                        ? 'Detected: ${ffmpeg.ffmpegPath}'
                        : 'Built-in offline engine active (simulated render & proxy)',
                    style: TextStyle(
                      fontSize: 11,
                      color: ffmpeg.isFFmpegAvailable ? AppTheme.accentNeon : Colors.amberAccent,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await ffmpeg.checkAvailability();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceVariant),
                    child: const Text('Check PATH', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ReelTune Studio v1.0.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                const Text(
                  'Cross-platform, offline-first non-destructive video and audio editing studio for creators. Built with Flutter, Dart, Riverpod, SQLite, and native media processing.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  'Operating System: ${Platform.operatingSystem} (${Platform.operatingSystemVersion})',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
