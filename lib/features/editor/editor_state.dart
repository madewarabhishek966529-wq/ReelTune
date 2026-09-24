import 'package:reeltune/core/services/audio_analysis_service.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/data/models/caption_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/media_file_model.dart';
import 'package:reeltune/data/models/project_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';
import 'package:reeltune/data/models/timeline_track_model.dart';

class EditorState {
  final ProjectModel project;
  final List<MediaFileModel> mediaFiles;
  final List<TimelineTrackModel> tracks;
  final List<TimelineItemModel> items;
  final AudioSettingsModel audioSettings;
  final List<EffectModel> effects;
  final List<CaptionModel> captions;

  // Timeline & Playback
  final double playhead; // in seconds
  final bool isPlaying;
  final String? selectedItemId;
  final double pixelsPerSecond;
  final int activeInspectorTab; // 0: Video, 1: Audio, 2: Effects, 3: Captions, 4: Export

  // Audio & Beat detection data
  final AudioAnalysisData? audioAnalysis;

  // History for Undo / Redo
  final List<List<TimelineItemModel>> undoStack;
  final List<List<TimelineItemModel>> redoStack;

  EditorState({
    required this.project,
    this.mediaFiles = const [],
    this.tracks = const [],
    this.items = const [],
    required this.audioSettings,
    this.effects = const [],
    this.captions = const [],
    this.playhead = 0.0,
    this.isPlaying = false,
    this.selectedItemId,
    this.pixelsPerSecond = 50.0,
    this.activeInspectorTab = 0,
    this.audioAnalysis,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  double get maxTimelineDuration {
    double maxEnd = 15.0;
    for (final item in items) {
      final end = item.startTime + item.duration;
      if (end > maxEnd) maxEnd = end;
    }
    return maxEnd;
  }

  TimelineItemModel? get selectedItem {
    if (selectedItemId == null) return null;
    try {
      return items.firstWhere((i) => i.id == selectedItemId);
    } catch (_) {
      return null;
    }
  }

  EditorState copyWith({
    ProjectModel? project,
    List<MediaFileModel>? mediaFiles,
    List<TimelineTrackModel>? tracks,
    List<TimelineItemModel>? items,
    AudioSettingsModel? audioSettings,
    List<EffectModel>? effects,
    List<CaptionModel>? captions,
    double? playhead,
    bool? isPlaying,
    String? selectedItemId,
    bool clearSelectedItemId = false,
    double? pixelsPerSecond,
    int? activeInspectorTab,
    AudioAnalysisData? audioAnalysis,
    List<List<TimelineItemModel>>? undoStack,
    List<List<TimelineItemModel>>? redoStack,
  }) {
    return EditorState(
      project: project ?? this.project,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      tracks: tracks ?? this.tracks,
      items: items ?? this.items,
      audioSettings: audioSettings ?? this.audioSettings,
      effects: effects ?? this.effects,
      captions: captions ?? this.captions,
      playhead: playhead ?? this.playhead,
      isPlaying: isPlaying ?? this.isPlaying,
      selectedItemId: clearSelectedItemId ? null : (selectedItemId ?? this.selectedItemId),
      pixelsPerSecond: pixelsPerSecond ?? this.pixelsPerSecond,
      activeInspectorTab: activeInspectorTab ?? this.activeInspectorTab,
      audioAnalysis: audioAnalysis ?? this.audioAnalysis,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}
