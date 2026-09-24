import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_riverpod/legacy.dart';
import 'package:reeltune/core/logging/app_logger.dart';
import 'package:reeltune/core/services/audio_analysis_service.dart';
import 'package:reeltune/core/services/ffmpeg_service.dart';
import 'package:reeltune/core/utilities/srt_parser.dart';
import 'package:reeltune/data/models/audio_settings_model.dart';
import 'package:reeltune/data/models/caption_model.dart';
import 'package:reeltune/data/models/effect_model.dart';
import 'package:reeltune/data/models/media_file_model.dart';
import 'package:reeltune/data/models/project_model.dart';
import 'package:reeltune/data/models/timeline_item_model.dart';
import 'package:reeltune/data/models/timeline_track_model.dart';
import 'package:reeltune/data/repositories/media_repository.dart';
import 'package:reeltune/data/repositories/project_repository.dart';
import 'package:reeltune/data/repositories/timeline_repository.dart';
import 'package:reeltune/features/editor/editor_state.dart';

class EditorNotifier extends StateNotifier<EditorState> {
  final ProjectRepository _projectRepo;
  final MediaRepository _mediaRepo;
  final TimelineRepository _timelineRepo;
  final AudioAnalysisService _audioAnalysisService;
  final FFmpegService _ffmpegService;

  late final Future<void> _initFuture;
  Timer? _playbackTimer;

  EditorNotifier({
    required ProjectModel project,
    ProjectRepository? projectRepo,
    MediaRepository? mediaRepo,
    TimelineRepository? timelineRepo,
    AudioAnalysisService? audioAnalysisService,
    FFmpegService? ffmpegService,
  })  : _projectRepo = projectRepo ?? ProjectRepository(),
        _mediaRepo = mediaRepo ?? MediaRepository(),
        _timelineRepo = timelineRepo ?? TimelineRepository(),
        _audioAnalysisService = audioAnalysisService ?? AudioAnalysisService(),
        _ffmpegService = ffmpegService ?? FFmpegService(),
        super(
          EditorState(
            project: project,
            tracks: [
              TimelineTrackModel(projectId: project.id, type: TrackType.video, index: 0),
              TimelineTrackModel(projectId: project.id, type: TrackType.audio, index: 1),
              TimelineTrackModel(projectId: project.id, type: TrackType.text, index: 2),
              TimelineTrackModel(projectId: project.id, type: TrackType.effects, index: 3),
            ],
            audioSettings: AudioSettingsModel(projectId: project.id),
          ),
        ) {
    _initFuture = _initializeProject();
  }

  Future<void> _initializeProject() async {
    try {
      // 1. Load or create default 4 tracks
      var tracks = await _timelineRepo.getTracks(state.project.id);
      if (tracks.isEmpty) {
        tracks = [
          TimelineTrackModel(projectId: state.project.id, type: TrackType.video, index: 0),
          TimelineTrackModel(projectId: state.project.id, type: TrackType.audio, index: 1),
          TimelineTrackModel(projectId: state.project.id, type: TrackType.text, index: 2),
          TimelineTrackModel(projectId: state.project.id, type: TrackType.effects, index: 3),
        ];
        for (final t in tracks) {
          await _timelineRepo.saveTrack(t);
        }
      }

      // 2. Load media files, items, audio settings, effects, captions
      final mediaFiles = await _mediaRepo.getMediaForProject(state.project.id);
      final items = await _timelineRepo.getItems(state.project.id);
      final audioSettings = await _timelineRepo.getAudioSettings(state.project.id);
      final effects = await _timelineRepo.getEffects(state.project.id);
      final captions = await _timelineRepo.getCaptions(state.project.id);

      // Perform initial audio beat analysis
      AudioAnalysisData? analysis;
      if (mediaFiles.isNotEmpty) {
        analysis = await _audioAnalysisService.analyzeAudio(
          filePath: mediaFiles.first.originalPath,
          duration: state.project.duration > 0 ? state.project.duration : 15.0,
        );
      } else {
        analysis = AudioAnalysisData.mock(duration: 15.0);
      }

      state = state.copyWith(
        tracks: tracks,
        mediaFiles: mediaFiles,
        items: items,
        audioSettings: audioSettings,
        effects: effects,
        captions: captions,
        audioAnalysis: analysis,
      );

      AppLogger.i('EditorNotifier', 'Initialized project editor: ${state.project.name}');
    } catch (e, st) {
      AppLogger.e('EditorNotifier', 'Failed to initialize project editor', e, st);
    }
  }

  // --- Transport & Playback ---
  void seekPlayhead(double time) {
    final clamped = time.clamp(0.0, state.maxTimelineDuration);
    state = state.copyWith(playhead: clamped);
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      _playbackTimer?.cancel();
      state = state.copyWith(isPlaying: false);
    } else {
      state = state.copyWith(isPlaying: true);
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
        final newTime = state.playhead + 0.033;
        if (newTime >= state.maxTimelineDuration) {
          seekPlayhead(0.0);
          togglePlayPause();
        } else {
          seekPlayhead(newTime);
        }
      });
    }
  }

  void setZoom(double pixelsPerSecond) {
    state = state.copyWith(pixelsPerSecond: pixelsPerSecond.clamp(10.0, 200.0));
  }

  void setActiveTab(int tabIndex) {
    state = state.copyWith(activeInspectorTab: tabIndex);
  }

  void selectItem(String? itemId) {
    if (itemId == null) {
      state = state.copyWith(clearSelectedItemId: true);
    } else {
      state = state.copyWith(selectedItemId: itemId);
    }
  }

  // --- Non-destructive Media Import ---
  Future<void> importMediaFile(String filePath) async {
    await _initFuture;
    try {
      final probe = await _ffmpegService.probeMedia(filePath);
      final filename = filePath.split(Platform.pathSeparator).last;

      final media = MediaFileModel(
        projectId: state.project.id,
        originalPath: filePath, // Original file is preserved untouched
        filename: filename,
        fileSize: probe.fileSize,
        duration: probe.duration,
        width: probe.width,
        height: probe.height,
        fps: probe.fps,
        videoCodec: probe.videoCodec,
        audioCodec: probe.audioCodec,
        sampleRate: probe.sampleRate,
        channels: probe.channels,
        isOriginalPreserved: true,
      );

      await _mediaRepo.addMediaFile(media);
      final updatedMedia = [...state.mediaFiles, media];

      // Automatically add clips to timeline
      final videoTrack = state.tracks.firstWhere(
        (t) => t.type == TrackType.video,
        orElse: () => state.tracks.first,
      );

      _pushUndo();

      final newItem = TimelineItemModel(
        trackId: videoTrack.id,
        projectId: state.project.id,
        mediaFileId: media.id,
        title: filename,
        startTime: state.items.isEmpty ? 0.0 : state.maxTimelineDuration,
        duration: media.duration,
        sourceStartTime: 0.0,
        sourceDuration: media.duration,
      );

      await _timelineRepo.saveItem(newItem);
      final updatedItems = [...state.items, newItem];

      // Update project duration
      final newDuration = math.max(state.project.duration, newItem.startTime + newItem.duration);
      final updatedProj = state.project.copyWith(duration: newDuration);
      await _projectRepo.updateProject(updatedProj);

      // Perform audio analysis
      final analysis = await _audioAnalysisService.analyzeAudio(
        filePath: media.originalPath,
        duration: newDuration,
      );

      state = state.copyWith(
        project: updatedProj,
        mediaFiles: updatedMedia,
        items: updatedItems,
        audioAnalysis: analysis,
        selectedItemId: newItem.id,
      );

      _triggerAutosave();
      AppLogger.i('EditorNotifier', 'Imported media non-destructively: $filename');
    } catch (e, st) {
      AppLogger.e('EditorNotifier', 'Media import failed', e, st);
    }
  }

  /// Import an audio file (music, voiceover, sound effect) onto the Audio track
  Future<void> importAudioFile(String filePath) async {
    await _initFuture;
    try {
      final probe = await _ffmpegService.probeMedia(filePath);
      final filename = filePath.split(Platform.pathSeparator).last;

      final media = MediaFileModel(
        projectId: state.project.id,
        originalPath: filePath,
        filename: filename,
        fileSize: probe.fileSize,
        duration: probe.duration,
        width: 0,
        height: 0,
        fps: 0,
        videoCodec: '',
        audioCodec: probe.audioCodec.isNotEmpty ? probe.audioCodec : 'aac',
        sampleRate: probe.sampleRate,
        channels: probe.channels,
        isOriginalPreserved: true,
      );

      await _mediaRepo.addMediaFile(media);
      final updatedMedia = [...state.mediaFiles, media];

      final audioTrack = state.tracks.firstWhere(
        (t) => t.type == TrackType.audio,
        orElse: () => state.tracks.length > 1 ? state.tracks[1] : state.tracks.first,
      );

      _pushUndo();

      final newItem = TimelineItemModel(
        trackId: audioTrack.id,
        projectId: state.project.id,
        mediaFileId: media.id,
        title: filename,
        startTime: 0.0,
        duration: media.duration,
        sourceStartTime: 0.0,
        sourceDuration: media.duration,
      );

      await _timelineRepo.saveItem(newItem);
      final updatedItems = [...state.items, newItem];

      final newDuration = math.max(state.project.duration, newItem.startTime + newItem.duration);
      final updatedProj = state.project.copyWith(duration: newDuration);
      await _projectRepo.updateProject(updatedProj);

      final analysis = await _audioAnalysisService.analyzeAudio(
        filePath: media.originalPath,
        duration: newDuration,
      );

      state = state.copyWith(
        project: updatedProj,
        mediaFiles: updatedMedia,
        items: updatedItems,
        audioAnalysis: analysis,
        selectedItemId: newItem.id,
      );

      _triggerAutosave();
      AppLogger.i('EditorNotifier', 'Imported audio file non-destructively: $filename');
    } catch (e, st) {
      AppLogger.e('EditorNotifier', 'Audio import failed', e, st);
    }
  }

  // --- Timeline Edit Operations ---
  void _pushUndo() {
    final currentHistory = List<TimelineItemModel>.from(state.items);
    state = state.copyWith(
      undoStack: [...state.undoStack, currentHistory],
      redoStack: [], // clear redo on new action
    );
  }

  Future<void> undo() async {
    if (state.undoStack.isEmpty) return;
    final previous = state.undoStack.last;
    final newUndo = state.undoStack.sublist(0, state.undoStack.length - 1);
    final newRedo = [...state.redoStack, List<TimelineItemModel>.from(state.items)];

    // Persist restored items to database
    for (final item in previous) {
      await _timelineRepo.saveItem(item);
    }

    state = state.copyWith(
      items: previous,
      undoStack: newUndo,
      redoStack: newRedo,
    );
  }

  Future<void> redo() async {
    if (state.redoStack.isEmpty) return;
    final next = state.redoStack.last;
    final newRedo = state.redoStack.sublist(0, state.redoStack.length - 1);
    final newUndo = [...state.undoStack, List<TimelineItemModel>.from(state.items)];

    for (final item in next) {
      await _timelineRepo.saveItem(item);
    }

    state = state.copyWith(
      items: next,
      undoStack: newUndo,
      redoStack: newRedo,
    );
  }

  Future<void> splitItemAtPlayhead() async {
    final item = state.selectedItem;
    if (item == null) return;

    final playhead = state.playhead;
    if (playhead <= item.startTime || playhead >= item.startTime + item.duration) {
      return; // playhead not within selected item
    }

    _pushUndo();

    final splitOffset = playhead - item.startTime;
    final firstPart = item.copyWith(
      duration: splitOffset,
      sourceDuration: splitOffset * item.speed,
    );

    final secondPart = item.copyWith(
      id: null, // new UUID
      title: '${item.title} (Part 2)',
      startTime: playhead,
      duration: item.duration - splitOffset,
      sourceStartTime: item.sourceStartTime + (splitOffset * item.speed),
      sourceDuration: (item.duration - splitOffset) * item.speed,
    );

    await _timelineRepo.saveItem(firstPart);
    await _timelineRepo.saveItem(secondPart);

    final newItems = state.items.map((i) => i.id == item.id ? firstPart : i).toList()
      ..add(secondPart);

    state = state.copyWith(
      items: newItems,
      selectedItemId: secondPart.id,
    );

    _triggerAutosave();
    AppLogger.i('EditorNotifier', 'Split item ${item.title} at ${playhead.toStringAsFixed(2)}s');
  }

  Future<void> trimItemStart(String id, double newStartTime) async {
    final item = state.items.firstWhere((i) => i.id == id);
    final delta = newStartTime - item.startTime;
    if (item.duration - delta < 0.2) return;

    _pushUndo();
    final updated = item.copyWith(
      startTime: newStartTime,
      duration: item.duration - delta,
      sourceStartTime: item.sourceStartTime + delta,
    );

    await _timelineRepo.saveItem(updated);
    state = state.copyWith(
      items: state.items.map((i) => i.id == id ? updated : i).toList(),
    );
    _triggerAutosave();
  }

  Future<void> trimItemEnd(String id, double newDuration) async {
    if (newDuration < 0.2) return;
    final item = state.items.firstWhere((i) => i.id == id);

    _pushUndo();
    final updated = item.copyWith(
      duration: newDuration,
      sourceDuration: newDuration * item.speed,
    );

    await _timelineRepo.saveItem(updated);
    state = state.copyWith(
      items: state.items.map((i) => i.id == id ? updated : i).toList(),
    );
    _triggerAutosave();
  }

  Future<void> duplicateItem(String id) async {
    final item = state.items.firstWhere((i) => i.id == id);
    _pushUndo();

    final duplicated = item.copyWith(
      id: null,
      title: '${item.title} (Copy)',
      startTime: item.startTime + item.duration + 0.1,
    );

    await _timelineRepo.saveItem(duplicated);
    state = state.copyWith(
      items: [...state.items, duplicated],
      selectedItemId: duplicated.id,
    );
    _triggerAutosave();
  }

  Future<void> deleteItem(String id) async {
    _pushUndo();
    await _timelineRepo.deleteItem(id);
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
      clearSelectedItemId: state.selectedItemId == id,
    );
    _triggerAutosave();
  }

  Future<void> updateItemTransform({
    required String id,
    double? scale,
    double? rotation,
    bool? flipH,
    bool? flipV,
    String? cropPreset,
  }) async {
    final item = state.items.firstWhere((i) => i.id == id);
    final updated = item.copyWith(
      scale: scale ?? item.scale,
      rotation: rotation ?? item.rotation,
      flipHorizontal: flipH ?? item.flipHorizontal,
      flipVertical: flipV ?? item.flipVertical,
      cropPreset: cropPreset ?? item.cropPreset,
    );

    await _timelineRepo.saveItem(updated);
    state = state.copyWith(
      items: state.items.map((i) => i.id == id ? updated : i).toList(),
    );
    _triggerAutosave();
  }

  Future<void> updateItemColor({
    required String id,
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? temperature,
    double? vignette,
  }) async {
    final item = state.items.firstWhere((i) => i.id == id);
    final updated = item.copyWith(
      brightness: brightness ?? item.brightness,
      contrast: contrast ?? item.contrast,
      saturation: saturation ?? item.saturation,
      exposure: exposure ?? item.exposure,
      temperature: temperature ?? item.temperature,
      vignette: vignette ?? item.vignette,
    );

    await _timelineRepo.saveItem(updated);
    state = state.copyWith(
      items: state.items.map((i) => i.id == id ? updated : i).toList(),
    );
    _triggerAutosave();
  }

  Future<void> setSpeed(String id, double speed) async {
    final item = state.items.firstWhere((i) => i.id == id);
    final updated = item.copyWith(
      speed: speed,
      duration: item.sourceDuration / speed,
    );

    await _timelineRepo.saveItem(updated);
    state = state.copyWith(
      items: state.items.map((i) => i.id == id ? updated : i).toList(),
    );
    _triggerAutosave();
  }

  // --- Audio Enhancement & A/B Comparison ---
  Future<void> toggleAudioEnhanced(bool isEnhanced) async {
    final updated = state.audioSettings.copyWith(isEnhanced: isEnhanced);
    await _timelineRepo.saveAudioSettings(updated);
    state = state.copyWith(audioSettings: updated);
    _triggerAutosave();
    AppLogger.i('EditorNotifier', 'Switched audio mode: ${isEnhanced ? "Enhanced Copy" : "Original Audio"}');
  }

  Future<void> updateAudioSettings(AudioSettingsModel settings) async {
    await _timelineRepo.saveAudioSettings(settings);
    state = state.copyWith(audioSettings: settings);
    _triggerAutosave();
  }

  Future<void> resetAudioSettings() async {
    final initial = AudioSettingsModel(projectId: state.project.id);
    await _timelineRepo.saveAudioSettings(initial);
    state = state.copyWith(audioSettings: initial);
    _triggerAutosave();
  }

  Future<void> toggleMute() async {
    final updated = state.audioSettings.copyWith(isMuted: !state.audioSettings.isMuted);
    await updateAudioSettings(updated);
  }

  Future<void> applyEqPreset(String presetName) async {
    AudioSettingsModel updated;
    switch (presetName) {
      case 'Bass Boost':
        updated = state.audioSettings.copyWith(
          bassGainDb: 6.0,
          midGainDb: 0.0,
          trebleGainDb: 1.0,
          isEnhanced: true,
        );
        break;
      case 'Vocal Clarity':
        updated = state.audioSettings.copyWith(
          bassGainDb: -2.0,
          midGainDb: 4.0,
          trebleGainDb: 3.0,
          isEnhanced: true,
        );
        break;
      case 'Podcast':
        updated = state.audioSettings.copyWith(
          bassGainDb: 1.0,
          midGainDb: 3.0,
          trebleGainDb: 2.0,
          compressorEnabled: true,
          normalizeLoudness: true,
          isEnhanced: true,
        );
        break;
      case 'Flat':
      default:
        updated = state.audioSettings.copyWith(
          bassGainDb: 0.0,
          midGainDb: 0.0,
          trebleGainDb: 0.0,
        );
        break;
    }
    await updateAudioSettings(updated);
  }

  // --- Creative Effects & Beat Sync ---
  Future<void> addEffect(EffectType type, double startTime, double duration, {double intensity = 0.5}) async {
    final effect = EffectModel(
      projectId: state.project.id,
      type: type,
      startTime: startTime,
      duration: duration,
      intensity: intensity,
    );

    await _timelineRepo.saveEffect(effect);
    state = state.copyWith(effects: [...state.effects, effect]);
    _triggerAutosave();
  }

  Future<void> removeEffect(String effectId) async {
    await _timelineRepo.deleteEffect(effectId);
    state = state.copyWith(effects: state.effects.where((e) => e.id != effectId).toList());
    _triggerAutosave();
  }

  /// Generate randomized creative effects synchronized to beat timestamps
  Future<void> generateRandomCreativeEffects({int count = 4, int seed = 42}) async {
    final beats = state.audioAnalysis?.downbeats ?? [2.0, 4.0, 6.0, 8.0, 10.0, 12.0];
    final rand = math.Random(seed);
    final effectPool = [
      EffectType.gaussianBlur,
      EffectType.zoomBounce,
      EffectType.glitch,
      EffectType.colorShift,
      EffectType.flash,
    ];

    final newEffects = <EffectModel>[];
    for (int i = 0; i < count && i < beats.length; i++) {
      final beatTime = beats[i];
      final effectType = effectPool[rand.nextInt(effectPool.length)];
      final eff = EffectModel(
        projectId: state.project.id,
        type: effectType,
        startTime: beatTime,
        duration: 0.5,
        intensity: 0.6 + (rand.nextDouble() * 0.3),
        isRandomized: true,
        seed: seed + i,
      );
      await _timelineRepo.saveEffect(eff);
      newEffects.add(eff);
    }

    state = state.copyWith(effects: [...state.effects, ...newEffects]);
    _triggerAutosave();
    AppLogger.i('EditorNotifier', 'Generated $count beat-synced creative effects (seed: $seed)');
  }

  // --- Captions & SRT ---
  Future<void> addCaption(String text, double start, double duration) async {
    final caption = CaptionModel(
      projectId: state.project.id,
      text: text,
      startTime: start,
      duration: duration,
    );

    await _timelineRepo.saveCaption(caption);
    state = state.copyWith(captions: [...state.captions, caption]);
    _triggerAutosave();
  }

  Future<void> updateCaption(CaptionModel caption) async {
    await _timelineRepo.saveCaption(caption);
    state = state.copyWith(
      captions: state.captions.map((c) => c.id == caption.id ? caption : c).toList(),
    );
    _triggerAutosave();
  }

  Future<void> removeCaption(String captionId) async {
    await _timelineRepo.deleteCaption(captionId);
    state = state.copyWith(captions: state.captions.where((c) => c.id != captionId).toList());
    _triggerAutosave();
  }

  Future<void> importSrt(String srtContent) async {
    final parsed = SrtParser.parseSrt(srtContent, state.project.id);
    for (final c in parsed) {
      await _timelineRepo.saveCaption(c);
    }
    state = state.copyWith(captions: [...state.captions, ...parsed]);
    _triggerAutosave();
  }

  String exportSrt() {
    return SrtParser.exportToSrt(state.captions);
  }

  // --- Autosave ---
  Future<void> _triggerAutosave() async {
    final data = {
      'project': state.project.toMap(),
      'item_count': state.items.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _projectRepo.saveAutosave(state.project.id, data);
  }

  void cancelPlayback() {
    _playbackTimer?.cancel();
  }
}

final editorProvider = StateNotifierProvider.family<EditorNotifier, EditorState, ProjectModel>((ref, project) {
  return EditorNotifier(project: project);
});
