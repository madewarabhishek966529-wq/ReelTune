class AppConstants {
  static const String appName = 'ReelTune';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Offline-first, Non-Destructive Video & Audio Studio';

  // Workspace subdirectories
  static const String dirInput = 'input';
  static const String dirProjects = 'projects';
  static const String dirOutput = 'output';
  static const String dirTemp = 'temp';
  static const String dirCache = 'cache';
  static const String dirTest = 'test';
  static const String dirTestFixtures = 'test/fixtures';
  static const String dirTestResults = 'test/results';
  static const String dirTestReports = 'test/reports';

  // Social Video Presets
  static const int instagramWidth = 1080;
  static const int instagramHeight = 1920;
  static const double aspect9x16 = 9 / 16;
  static const double aspect16x9 = 16 / 9;
  static const double aspect1x1 = 1 / 1;
  static const double aspect4x5 = 4 / 5;

  // Audio defaults
  static const int defaultSampleRate = 44100;
  static const int defaultAudioBitrate = 192; // kbps
  static const double defaultTargetLufs = -14.0; // Streaming standard

  // Timeline
  static const double defaultPixelsPerSecond = 50.0;
  static const double minPixelsPerSecond = 10.0;
  static const double maxPixelsPerSecond = 200.0;
}
