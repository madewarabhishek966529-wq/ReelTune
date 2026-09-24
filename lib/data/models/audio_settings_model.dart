import 'package:uuid/uuid.dart';

class AudioSettingsModel {
  final String id;
  final String projectId;
  final bool isEnhanced; // Original vs. Enhanced toggle
  final bool isMuted;

  // Equalizer & Gain
  final double gainDb; // -24 to +24 dB
  final double bassGainDb; // -15 to +15 dB (100 Hz shelf)
  final double midGainDb; // -15 to +15 dB (1 kHz bell)
  final double trebleGainDb; // -15 to +15 dB (10 kHz shelf)

  // Dynamics (Compressor & Limiter)
  final bool compressorEnabled;
  final double compressorThresholdDb; // -60 to 0 dB
  final double compressorRatio; // 1.0 to 20.0
  final double compressorAttackMs; // 1 to 200 ms
  final double compressorReleaseMs; // 10 to 1000 ms

  final bool limiterEnabled;
  final double limiterCeilingDb; // -6.0 to 0.0 dB

  // Loudness Normalization (EBU R128 standard)
  final bool normalizeLoudness;
  final double targetLufs; // Typically -14.0 LUFS for social media

  // Stereo & Fades
  final double stereoBalance; // -1.0 (Left) to 1.0 (Right)
  final double fadeInSeconds;
  final double fadeOutSeconds;

  AudioSettingsModel({
    String? id,
    required this.projectId,
    this.isEnhanced = false, // Preserves original by default!
    this.isMuted = false,
    this.gainDb = 0.0,
    this.bassGainDb = 0.0,
    this.midGainDb = 0.0,
    this.trebleGainDb = 0.0,
    this.compressorEnabled = true,
    this.compressorThresholdDb = -18.0,
    this.compressorRatio = 3.0,
    this.compressorAttackMs = 20.0,
    this.compressorReleaseMs = 150.0,
    this.limiterEnabled = true,
    this.limiterCeilingDb = -1.0,
    this.normalizeLoudness = true,
    this.targetLufs = -14.0,
    this.stereoBalance = 0.0,
    this.fadeInSeconds = 0.0,
    this.fadeOutSeconds = 0.0,
  }) : id = id ?? const Uuid().v4();

  AudioSettingsModel copyWith({
    String? id,
    String? projectId,
    bool? isEnhanced,
    bool? isMuted,
    double? gainDb,
    double? bassGainDb,
    double? midGainDb,
    double? trebleGainDb,
    bool? compressorEnabled,
    double? compressorThresholdDb,
    double? compressorRatio,
    double? compressorAttackMs,
    double? compressorReleaseMs,
    bool? limiterEnabled,
    double? limiterCeilingDb,
    bool? normalizeLoudness,
    double? targetLufs,
    double? stereoBalance,
    double? fadeInSeconds,
    double? fadeOutSeconds,
  }) {
    return AudioSettingsModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      isEnhanced: isEnhanced ?? this.isEnhanced,
      isMuted: isMuted ?? this.isMuted,
      gainDb: gainDb ?? this.gainDb,
      bassGainDb: bassGainDb ?? this.bassGainDb,
      midGainDb: midGainDb ?? this.midGainDb,
      trebleGainDb: trebleGainDb ?? this.trebleGainDb,
      compressorEnabled: compressorEnabled ?? this.compressorEnabled,
      compressorThresholdDb: compressorThresholdDb ?? this.compressorThresholdDb,
      compressorRatio: compressorRatio ?? this.compressorRatio,
      compressorAttackMs: compressorAttackMs ?? this.compressorAttackMs,
      compressorReleaseMs: compressorReleaseMs ?? this.compressorReleaseMs,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      limiterCeilingDb: limiterCeilingDb ?? this.limiterCeilingDb,
      normalizeLoudness: normalizeLoudness ?? this.normalizeLoudness,
      targetLufs: targetLufs ?? this.targetLufs,
      stereoBalance: stereoBalance ?? this.stereoBalance,
      fadeInSeconds: fadeInSeconds ?? this.fadeInSeconds,
      fadeOutSeconds: fadeOutSeconds ?? this.fadeOutSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'is_enhanced': isEnhanced ? 1 : 0,
      'is_muted': isMuted ? 1 : 0,
      'gain_db': gainDb,
      'bass_gain_db': bassGainDb,
      'mid_gain_db': midGainDb,
      'treble_gain_db': trebleGainDb,
      'compressor_enabled': compressorEnabled ? 1 : 0,
      'compressor_threshold_db': compressorThresholdDb,
      'compressor_ratio': compressorRatio,
      'compressor_attack_ms': compressorAttackMs,
      'compressor_release_ms': compressorReleaseMs,
      'limiter_enabled': limiterEnabled ? 1 : 0,
      'limiter_ceiling_db': limiterCeilingDb,
      'normalize_loudness': normalizeLoudness ? 1 : 0,
      'target_lufs': targetLufs,
      'stereo_balance': stereoBalance,
      'fade_in_seconds': fadeInSeconds,
      'fade_out_seconds': fadeOutSeconds,
    };
  }

  factory AudioSettingsModel.fromMap(Map<String, dynamic> map) {
    return AudioSettingsModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      isEnhanced: (map['is_enhanced'] as int?) == 1,
      isMuted: (map['is_muted'] as int?) == 1,
      gainDb: (map['gain_db'] as num?)?.toDouble() ?? 0.0,
      bassGainDb: (map['bass_gain_db'] as num?)?.toDouble() ?? 0.0,
      midGainDb: (map['mid_gain_db'] as num?)?.toDouble() ?? 0.0,
      trebleGainDb: (map['treble_gain_db'] as num?)?.toDouble() ?? 0.0,
      compressorEnabled: (map['compressor_enabled'] as int?) != 0,
      compressorThresholdDb: (map['compressor_threshold_db'] as num?)?.toDouble() ?? -18.0,
      compressorRatio: (map['compressor_ratio'] as num?)?.toDouble() ?? 3.0,
      compressorAttackMs: (map['compressor_attack_ms'] as num?)?.toDouble() ?? 20.0,
      compressorReleaseMs: (map['compressor_release_ms'] as num?)?.toDouble() ?? 150.0,
      limiterEnabled: (map['limiter_enabled'] as int?) != 0,
      limiterCeilingDb: (map['limiter_ceiling_db'] as num?)?.toDouble() ?? -1.0,
      normalizeLoudness: (map['normalize_loudness'] as int?) != 0,
      targetLufs: (map['target_lufs'] as num?)?.toDouble() ?? -14.0,
      stereoBalance: (map['stereo_balance'] as num?)?.toDouble() ?? 0.0,
      fadeInSeconds: (map['fade_in_seconds'] as num?)?.toDouble() ?? 0.0,
      fadeOutSeconds: (map['fade_out_seconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
