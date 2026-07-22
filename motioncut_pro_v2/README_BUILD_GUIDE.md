# MotionCut Mobile Pro v2.0 - Hướng dẫn Build & Cài đặt

## 📥 Tải file ZIP
File: `motioncut_pro_v2_fixed.zip`
Giải nén ra thư mục `motioncut_pro_v2/`

---

## 🛠️ Cách 1: Build APK trên máy tính (Windows/Mac/Linux) - KHUYẾN NGHỊ

### Bước 1: Cài đặt môi trường

#### 1.1 Cài Flutter SDK
```bash
# Windows: Tải từ https://docs.flutter.dev/get-started/install
# Giải nén và thêm vào PATH

# macOS/Linux:
sudo snap install flutter --classic
# hoặc
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
```

Kiểm tra:
```bash
flutter doctor
```
> Cần fix tất cả lỗi trước khi build (cài Android SDK, accept licenses...)

#### 1.2 Cài Android Studio + SDK
- Tải Android Studio: https://developer.android.com/studio
- Mở Android Studio → SDK Manager → cài:
  - Android SDK (API 33-34)
  - Android SDK Command-line Tools
  - Android SDK Build-Tools
- Chạy: `flutter doctor --android-licenses` và accept all

#### 1.3 Cài VS Code (khuyến nghị)
- Extension: Flutter, Dart

---

### Bước 2: Mở project
```bash
cd motioncut_pro_v2
flutter pub get
```

> ⚠️ **Lưu ý quan trọng về ffmpeg_kit_flutter:**
> Package này đôi khi gây lỗi build do NDK. Nếu gặp lỗi:
> 1. Mở `android/app/build.gradle`
> 2. Thêm vào `defaultConfig`:
>    ```gradle
>    ndk {
>        abiFilters 'arm64-v8a', 'armeabi-v7a'
>    }
>    ```
> 3. Hoặc tạm thời xóa `ffmpeg_kit_flutter` khỏi `pubspec.yaml` nếu chỉ test UI

---

### Bước 3: Build APK

#### Debug APK (test nhanh):
```bash
flutter build apk --debug
```
File output: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release APK (nhẹ, tối ưu):
```bash
flutter build apk --release
```
File output: `build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle (để upload Google Play):
```bash
flutter build appbundle
```

---

### Bước 4: Cài vào điện thoại

#### Cách A: Cài trực tiếp qua USB
```bash
# Kết nối điện thoại, bật USB Debugging trong Developer Options
flutter install
```

#### Cách B: Copy file APK
1. Kết nối điện thoại với máy tính
2. Copy `app-release.apk` vào điện thoại
3. Trên điện thoại: mở file APK → Cài đặt
4. Nếu báo "Unknown sources": Vào Settings → Security → cho phép cài app từ nguồn này

---

## 📱 Cách 2: Build trực tiếp trên điện thoại Android (không cần máy tính)

> ⚠️ Yêu cầu: Điện thoại Android mạnh (RAM 6GB+), bộ nhớ trống 5GB+

### Bước 1: Cài Termux
- Tải Termux từ F-Droid (KHÔNG dùng Google Play version - đã outdated)
- Link: https://f-droid.org/packages/com.termux/

### Bước 2: Cài Flutter trong Termux
```bash
pkg update && pkg upgrade
pkg install git dart flutter
```

### Bước 3: Clone/copy project vào Termux
```bash
# Copy file zip vào điện thoại rồi:
cd ~
unzip /sdcard/Download/motioncut_pro_v2_fixed.zip
cd motioncut_pro_v2
flutter pub get
```

### Bước 4: Build
```bash
flutter build apk --debug
```

> ⚠️ **Lưu ý:** Termux không hỗ trợ Android SDK đầy đủ, nên cách này rất hạn chế và thường chỉ build được project đơn giản. Với project này (có ffmpeg), **KHÔNG KHUYẾN KHÍCH** dùng cách này.

---

## 🍎 Cách 3: Build cho iOS (cần Mac)

```bash
# Chỉ chạy được trên macOS
flutter build ios --release
```
Sau đó mở Xcode → Product → Archive → Distribute App

---

## 🔧 Sửa lỗi thường gặp

### Lỗi 1: `Could not find dart in PATH`
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Lỗi 2: `Gradle task assembleDebug failed`
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### Lỗi 3: `ffmpeg_kit_flutter` build failed
**Cách fix:**
1. Mở `android/build.gradle`, thêm:
   ```gradle
   allprojects {
       repositories {
           mavenCentral()
           google()
       }
   }
   ```
2. Hoặc tạm thời xóa dòng `ffmpeg_kit_flutter` trong `pubspec.yaml` nếu chưa cần export video

### Lỗi 4: `minSdkVersion` too low
Mở `android/app/build.gradle`, sửa:
```gradle
android {
    defaultConfig {
        minSdkVersion 24  // hoặc 21
    }
}
```

### Lỗi 5: `compileSdkVersion` too low
```gradle
android {
    compileSdkVersion 34
}
```

---

## 🚀 Chạy app lần đầu

```bash
# Chạy debug trên điện thoại đã kết nối
flutter run

# Hoặc chạy trên emulator
flutter emulators --launch <emulator_id>
flutter run
```

---

## 📂 Cấu trúc project

```
lib/
├── main.dart                    # Entry point
├── models/                      # Data models
│   ├── effect_model.dart        # 19 effect types
│   ├── filter_model.dart        # 13 filter presets
│   ├── velocity_model.dart      # 8 velocity curves
│   ├── vector_shape_model.dart  # 10 vector shapes
│   ├── keyframe_model.dart      # 15 properties + 15 easings
│   ├── clip_model.dart          # Video/image/audio/text clips
│   ├── layer_model.dart         # Layer with effects/filters/vectors
│   └── project_model.dart       # Project container
├── providers/                   # Riverpod state management
├── screens/                     # UI screens
│   ├── editor/                  # Main editor
│   ├── export/                  # Export video
│   ├── home/                    # Project list
│   └── media_picker/            # Import media
├── services/                    # Business logic
│   ├── ffmpeg_export_service.dart
│   ├── beat_detection_service.dart
│   ├── media_import_service.dart
│   └── project_storage_service.dart
├── core/                        # Utilities
│   ├── constants/app_theme.dart
│   └── utils/
│       ├── easing_utils.dart
│       ├── color_filter_utils.dart
│       └── undo_redo_manager.dart
└── widgets/common/              # Reusable widgets
```

---

## 🎯 Tính năng đã có

| Tính năng | Mô tả |
|-----------|-------|
| **Effect** | Glow, Blur, Shadow, Vignette, Pixelate, RGB Shift, Chromatic Aberration, Shake, Pulse, Glitch, Wave... |
| **Vector** | Rectangle, Circle, Star, Heart, Arrow, Polygon, Path với gradient fill |
| **Velocity** | Speed ramping: constant, rampIn/Out/InOut, hold, reverse, pingPong, custom curve |
| **Shake** | Camera shake với cường độ điều chỉnh được |
| **Filter** | Grayscale, Sepia, Vintage, Cinematic, Dramatic, Warm, Cool, Brightness, Contrast, Saturation, Hue Rotate |
| **Keyframe** | 15 properties với 15 easing curves (elastic, bounce, spring...) |
| **Timeline** | Drag clips, zoom, snap, playhead scrubbing |
| **Export** | FFmpeg-based video export (720p/1080p/4K) |

---

## 📝 License
MIT License - Free to use and modify.

## 🆘 Hỗ trợ
Nếu gặp lỗi build, hãy chạy `flutter doctor -v` và gửi output để được hỗ trợ.
