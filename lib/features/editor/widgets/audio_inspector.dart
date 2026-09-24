import 'package:flutter/material.dart';
import 'package:reeltune/app/theme.dart';
import 'package:reeltune/core/services/audio_analysis_service.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/features/editor/editor_provider.dart';
import 'package:reeltune/shared/widgets/volume_meter.dart';
import 'package:reeltune/shared/widgets/waveform_painter.dart';

class AudioInspector extends StatelessWidget {
  final AudioSettingsModel audioSettings;
  final AudioAnalysisData? audioAnalysis;
  final EditorNotifier editorNotifier;

  const AudioInspector({
    super.key,
    required this.audioSettings,
    this.audioAnalysis,
    required this.editorNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // A/B Comparison Switch Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: audioSettings.isEnhanced
                ? AppTheme.accentNeon.withValues(alpha: 0.1)
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: audioSettings.isEnhanced ? AppTheme.accentNeon : AppTheme.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                audioSettings.isEnhanced ? Icons.auto_awesome : Icons.music_note,
                color: audioSettings.isEnhanced ? AppTheme.accentNeon : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audioSettings.isEnhanced ? 'Enhanced Audio (Processing Copy)' : 'Original Source Audio',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      audioSettings.isEnhanced
                          ? 'EQ, Dynamics, and EBU R128 active'
                          : 'Pristine original sound preserved',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: audioSettings.isEnhanced,
                activeThumbColor: AppTheme.accentNeon,
                onChanged: (val) => editorNotifier.toggleAudioEnhanced(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Waveform & Beat Analytics Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141721),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: AppTheme.secondary, size: 16),
                      const SizedBox(width: 6),
                      const Text('Beat & Waveform Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${audioAnalysis?.bpm.toStringAsFixed(1) ?? '124.0'} BPM',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Waveform Canvas
              SizedBox(
                height: 48,
                width: double.infinity,
                child: CustomPaint(
                  painter: WaveformPainter(
                    points: audioAnalysis?.waveformPoints ?? List.filled(60, 0.4),
                    waveColor: audioSettings.isEnhanced ? AppTheme.accentNeon : AppTheme.secondary,
                    beatColor: Colors.amberAccent,
                    beatTimestamps: audioAnalysis?.downbeats ?? [],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Peak: -0.8 dB', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const Text('LUFS: -14.2', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const VolumeMeterWidget(leftDb: -12.0, rightDb: -14.0),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Equalizer Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('3-Band Parametric EQ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            TextButton(
              onPressed: () => editorNotifier.resetAudioSettings(),
              child: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
        _buildSlider(
          label: 'Master Gain',
          value: audioSettings.gainDb,
          min: -24.0,
          max: 24.0,
          display: '${audioSettings.gainDb.toStringAsFixed(1)} dB',
          onChanged: (v) => editorNotifier.updateAudioSettings(audioSettings.copyWith(gainDb: v)),
        ),
        _buildSlider(
          label: 'Bass (100 Hz)',
          value: audioSettings.bassGainDb,
          min: -15.0,
          max: 15.0,
          display: '${audioSettings.bassGainDb.toStringAsFixed(1)} dB',
          onChanged: (v) => editorNotifier.updateAudioSettings(audioSettings.copyWith(bassGainDb: v)),
        ),
        _buildSlider(
          label: 'Mid Range (1 kHz)',
          value: audioSettings.midGainDb,
          min: -15.0,
          max: 15.0,
          display: '${audioSettings.midGainDb.toStringAsFixed(1)} dB',
          onChanged: (v) => editorNotifier.updateAudioSettings(audioSettings.copyWith(midGainDb: v)),
        ),
        _buildSlider(
          label: 'Treble (10 kHz)',
          value: audioSettings.trebleGainDb,
          min: -15.0,
          max: 15.0,
          display: '${audioSettings.trebleGainDb.toStringAsFixed(1)} dB',
          onChanged: (v) => editorNotifier.updateAudioSettings(audioSettings.copyWith(trebleGainDb: v)),
        ),
        const SizedBox(height: 16),

        // Dynamics & Normalization
        const Text('Dynamics & Loudness Normalization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Compressor & Brickwall Limiter', style: TextStyle(fontSize: 12)),
          subtitle: const Text('Tames harsh volume spikes and boosts punch', style: TextStyle(fontSize: 10, color: Colors.grey)),
          value: audioSettings.compressorEnabled,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => editorNotifier.updateAudioSettings(audioSettings.copyWith(compressorEnabled: v)),
        ),
        SwitchListTile(
          title: const Text('EBU R128 Social Loudness (-14 LUFS)', style: TextStyle(fontSize: 12)),
          subtitle: const Text('Standard loudness target for Reels & Shorts', style: TextStyle(fontSize: 10, color: Colors.grey)),
          value: audioSettings.normalizeLoudness,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => editorNotifier.updateAudioSettings(audioSettings.copyWith(normalizeLoudness: v)),
        ),
        _buildSlider(
          label: 'Stereo Balance (L <-> R)',
          value: audioSettings.stereoBalance,
          min: -1.0,
          max: 1.0,
          display: audioSettings.stereoBalance == 0.0
              ? 'Center'
              : (audioSettings.stereoBalance < 0 ? 'L ${(audioSettings.stereoBalance * -100).toInt()}%' : 'R ${(audioSettings.stereoBalance * 100).toInt()}%'),
          onChanged: (v) => editorNotifier.updateAudioSettings(audioSettings.copyWith(stereoBalance: v)),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(display, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
