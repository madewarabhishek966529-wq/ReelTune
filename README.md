# ReelTune

ReelTune is a cross-platform, offline-first video and audio editing application for Windows and Android.

It helps creators turn raw video footage into polished, beat-synchronized, audio-enhanced short-form videos (Instagram Reels, YouTube Shorts, TikTok) while strictly preserving original source media.

---

## 🌟 Core Architecture & Principles

- **Framework**: Flutter + Dart (Material 3 Dark Theme)
- **State Management**: Riverpod (reactive providers, decoupled state)
- **Database**: SQLite (`sqflite` + `sqflite_common_ffi` cross-platform)
- **Media Engine**: FFmpeg + native processing pipelines
- **Offline-First**: Zero mandatory cloud services or API keys
- **Non-Destructive Editing**: Input files are never overwritten; non-destructive timeline edit instructions
- **Audio First**: Original audio preserved by default, non-destructive EQ, dynamics, loudness normalization, and beat detection
- **Cross-Platform**: Android + Windows Desktop support

---

## 📂 Architecture Flow

```
Dart UI -> Riverpod Providers -> Use Cases / Services -> Repositories / Platform Adapter -> FFmpeg / Native -> Output
```

---

## 🚀 Key Features

1. **Home & Project Management**:
   - Recent projects with thumbnail previews, duration, last modified date, and resolution
   - Non-destructive project creation and workspace storage tracking
   - Crash recovery & project autosave

2. **Media Import & Safety**:
   - Import MP4, MOV, WebM, MKV
   - Metadata extraction (resolution, duration, FPS, codecs, sample rate)
   - Input media integrity protection (sources are never modified or overwritten)

3. **Multi-Track Non-Destructive Timeline**:
   - Tracks: Video, Audio, Captions/Text, Effects
   - Operations: Trim, Split, Duplicate, Reorder, Delete, Undo/Redo, Zoom
   - CustomPainter timeline rendering with waveform visualization and playhead scrubbing

4. **Visual Transformations & Creative Effects**:
   - Crop (9:16, 16:9, 1:1, 4:5), Scale, Rotate, Flip, Speed Ramping (0.25x - 2.0x)
   - Color grading: Brightness, Contrast, Saturation, Exposure, Vignette, Sharpen
   - Creative FX: Blur (Gaussian/Motion/Background), Zoom bounce, Glitch, Shake, Flash, Color shift
   - Side-by-side & Picture-in-picture layouts

5. **Audio Studio & Beat Detection**:
   - Original vs. Enhanced A/B comparison
   - Waveform visualization, RMS loudness meter, clipping indicator, peak detection
   - Beat detection: BPM estimation, beat timestamps, downbeat candidates
   - Multi-band parametric EQ (bass, mid, treble), dynamic compressor, brickwall limiter, and EBU R128 loudness normalization

6. **Captions & Overlays**:
   - Manual subtitle creation with timestamps
   - SRT import & export
   - Typography, alignment, colors, outlines, and positioning

7. **Export Engine & Presets**:
   - Social Presets: Instagram Reel (1080x1920 9:16), YouTube Shorts, TikTok, and Custom
   - Background export queue with progress tracking
   - Post-export output integrity validation (file existence, duration, stream checks)

8. **Developer Mode & Automated Testing**:
   - End-to-end automated test loop: Test Video -> Import -> Process -> Export -> Validate
   - Test fixtures and diagnostic report generation

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (3.13+ / 3.47+ stable)
- Dart SDK
- Windows: Visual Studio C++ build tools (for Flutter desktop)
- Android: Android SDK & NDK

### Setup
```bash
# Clone the repository
git clone https://github.com/madewarabhishek966529-wq/ReelTune.git
cd ReelTune

# Install dependencies
dart pub get

# Run on Windows Desktop
flutter run -d windows

# Run on Android
flutter run -d android
```

---

## 📜 License
MIT License
