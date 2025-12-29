# 📱 Monitoring Restan Mobile App

Aplikasi mobile Flutter untuk monitoring data panen dan pengiriman kelapa sawit. Aplikasi ini dapat bekerja secara offline dengan menyimpan data di SQLite lokal dan melakukan sinkronisasi otomatis saat terhubung ke internet.

## ✨ Fitur Utama

### 🔐 Authentication
- Login menggunakan JWT token
- Secure storage untuk menyimpan credentials
- Auto-refresh token sebelum expired
- Persistent login session

### 📊 Data Management
- **Data Panen**: Menampilkan data panen dengan detail pemanen, kerani, afdeling, blok, dll
- **Data Pengiriman**: Menampilkan data pengiriman dengan detail kendaraan, kerani, berat, dll
- **Real-time Sync**: Sinkronisasi otomatis dengan API server
- **Offline Mode**: Data tersimpan lokal dan dapat diakses tanpa internet

### 🔍 Search & Filter
- Search real-time berdasarkan keyword
- Filter berdasarkan tanggal, afdeling, kerani, dll
- Pagination dengan infinite scroll
- Sort data berdasarkan berbagai kriteria

### 🌐 Connectivity
- Auto-detect status koneksi internet
- Indikator online/offline di UI
- Automatic sync saat koneksi kembali
- Error handling yang robust

### 📱 User Experience
- Material Design 3
- Responsive layout
- Pull-to-refresh
- Loading indicators
- Error notifications
- Smooth animations

## 🛠️ Teknologi Stack

### Framework & Language
- **Flutter** 3.10+ - Cross-platform mobile framework
- **Dart** 3.10+ - Programming language

### State Management
- **Provider** - State management solution
- **ChangeNotifier** - For reactive programming

### Networking
- **Dio** - HTTP client for API communication
- **Connectivity Plus** - Network connectivity detection

### Database
- **SQLite** via **sqflite** - Local data storage
- **Automatic migrations** - Database versioning

### Security
- **Flutter Secure Storage** - Secure credentials storage
- **JWT Token** - API authentication

### UI Components
- **Material Design 3** - Modern UI components
- **Pull to Refresh** - Refresh gestures
- **Infinite Scroll** - Pagination

## 📋 Prasyarat

### Development Environment
- Flutter SDK 3.10.0 atau lebih baru
- Dart SDK 3.10.0 atau lebih baru
- Android Studio / VS Code dengan Flutter plugin
- Android SDK (untuk platform Android)

### API Server
- Server API yang berjalan di: `http://192.168.1.219/lubung-data-SAE/api`
- Endpoint yang diperlukan:
  - `POST /auth.php/login`
  - `GET /auth.php/verify`
  - `POST /auth.php/refresh`
  - `GET /panen.php/`
  - `GET /pengiriman.php/`

### Credentials Default
- **Username**: `admin`
- **Password**: `admin123`

## 🚀 Instalasi & Setup

### 1. Clone Repository
```bash
cd C:\Revanza\Flutter\try1\monitoring_restan_app\monitoring_restan_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code (JSON Serialization)
```bash
flutter packages pub run build_runner build
```

### 4. Konfigurasi API
Edit file `lib/utils/app_constants.dart` untuk mengubah base URL API:
```dart
static const String baseUrl = 'http://192.168.1.219/lubung-data-SAE/api';
```

### 5. Build APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

### 6. Install di Device
```bash
flutter install
```
atau copy file APK dari `build/app/outputs/flutter-apk/` ke device Android.

## 📱 Cara Penggunaan

### 1. Login
- Buka aplikasi
- Masukkan username dan password
- Tekan tombol "Login"
- App akan otomatis menyimpan session

### 2. Sync Data
- Setelah login, app otomatis download data dari server
- Pull-to-refresh untuk sync manual
- Tombol sync tersedia di floating action button

### 3. Browse Data
- **Tab Data Panen**: List data panen dengan search dan filter
- **Tab Data Pengiriman**: List data pengiriman dengan search dan filter
- Tap item untuk melihat detail lengkap

### 4. Search & Filter
- Gunakan search bar untuk pencarian real-time
- Tap icon filter untuk options filter lanjutan
- Filter berdasarkan tanggal, afdeling, dll

### 5. Offline Mode
- Saat tidak ada internet, data tetap tersedia dari storage lokal
- Indikator "Offline" ditampilkan di app bar
- Data akan ter-sync otomatis saat koneksi kembali

## 🏗️ Arsitektur Aplikasi

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── panen.dart
│   ├── pengiriman.dart
│   ├── api_response.dart
│   └── ...
├── services/                 # Business logic layer
│   ├── api_service.dart     # HTTP API client
│   └── database_helper.dart # SQLite operations
├── providers/               # State management
│   ├── auth_provider.dart   # Authentication state
│   └── data_provider.dart   # Data & sync state
├── screens/                 # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── panen_screen.dart
│   └── pengiriman_screen.dart
├── widgets/                 # Reusable UI components
│   ├── search_filter_bar.dart
│   ├── panen_card.dart
│   ├── pengiriman_card.dart
│   └── empty_state.dart
└── utils/
    └── app_constants.dart   # App constants
```

### Architecture Pattern
- **Provider Pattern** untuk state management
- **Repository Pattern** untuk data layer
- **Service Layer** untuk business logic
- **Clean Architecture** principles

### Data Flow
1. **UI Layer** (Screens/Widgets) → 
2. **State Layer** (Providers) → 
3. **Service Layer** (ApiService/DatabaseHelper) → 
4. **Data Layer** (Models)

## 📊 Database Schema

### Tables

#### 1. panen
```sql
CREATE TABLE panen (
    id INTEGER PRIMARY KEY,
    upload_id INTEGER,
    nama_kerani TEXT NOT NULL,
    tanggal_pemeriksaan TEXT NOT NULL,
    afdeling TEXT NOT NULL,
    nama_pemanen TEXT NOT NULL,
    nik_pemanen TEXT NOT NULL,
    blok TEXT NOT NULL,
    no_ancak TEXT NOT NULL,
    no_tph TEXT NOT NULL,
    jam TEXT NOT NULL,
    last_modified TEXT NOT NULL,
    koordinat_lat REAL,
    koordinat_lng REAL,
    jumlah_janjang INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    synced_at TEXT
);
```

#### 2. pengiriman
```sql
CREATE TABLE pengiriman (
    id INTEGER PRIMARY KEY,
    upload_id INTEGER,
    tipe_aplikasi TEXT,
    nama_kerani TEXT NOT NULL,
    nik_kerani TEXT NOT NULL,
    tanggal TEXT NOT NULL,
    afdeling TEXT NOT NULL,
    nopol TEXT NOT NULL,
    nomor_kendaraan TEXT NOT NULL,
    blok TEXT NOT NULL,
    no_tph TEXT NOT NULL,
    jumlah_janjang INTEGER NOT NULL,
    waktu TEXT NOT NULL,
    koordinat_lat REAL,
    koordinat_lng REAL,
    kg REAL NOT NULL,
    created_at TEXT NOT NULL,
    synced_at TEXT
);
```

#### 3. sync_metadata
```sql
CREATE TABLE sync_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    last_sync TEXT NOT NULL,
    total_records INTEGER DEFAULT 0
);
```

## 🔧 Konfigurasi

### App Constants
File: `lib/utils/app_constants.dart`

```dart
class AppConstants {
    // API Configuration
    static const String baseUrl = 'http://192.168.1.219/lubung-data-SAE/api';
    
    // Pagination
    static const int defaultPageSize = 20;
    static const int maxPageSize = 100;
    
    // Sync Settings
    static const Duration syncInterval = Duration(minutes: 30);
    
    // Default Credentials
    static const String defaultUsername = 'admin';
    static const String defaultPassword = 'admin123';
}
```

### Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  dio: ^5.4.0                      # HTTP client
  sqflite: ^2.3.0                  # SQLite database
  provider: ^6.1.1                 # State management
  flutter_secure_storage: ^9.0.0   # Secure storage
  connectivity_plus: ^5.0.2        # Connectivity check
  json_annotation: ^4.8.1          # JSON serialization
  intl: ^0.19.0                    # Date formatting
  flutter_spinkit: ^5.2.0          # Loading animations
  pull_to_refresh: ^2.0.0          # Pull to refresh

dev_dependencies:
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
  flutter_lints: ^6.0.0
```

## 🔒 Security Features

### 1. Authentication
- JWT token dengan expiry time
- Auto-refresh token mechanism
- Secure token storage menggunakan FlutterSecureStorage
- Session persistence

### 2. API Security
- HTTPS support ready
- Request timeout handling
- Error response sanitization
- No sensitive data logging

### 3. Data Security
- SQLite database dengan auto-encryption ready
- Secure credentials storage
- No plaintext password storage

## 🐛 Troubleshooting

### 1. Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs

# Rebuild APK
flutter build apk --release
```

### 2. Database Issues
```dart
// Reset database (untuk development)
await DatabaseHelper().clearAllData();
```

### 3. API Connection Issues
- Pastikan server API berjalan di IP yang benar
- Check firewall/network connectivity
- Verify API endpoints menggunakan Postman

### 4. Authentication Issues
```dart
// Clear stored credentials
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.logout();
```

## 📈 Performance Tips

### 1. Database Optimization
- Index pada kolom yang sering di-query
- Pagination untuk dataset besar
- Batch insert untuk sync

### 2. Network Optimization
- Request timeout yang appropriate
- Retry mechanism untuk failed requests
- Efficient pagination

### 3. UI Optimization
- Lazy loading dengan ListView.builder
- Image optimization
- Minimal rebuilds dengan Consumer

## 🔄 Future Enhancements

### 1. Planned Features
- [ ] Export data ke Excel/CSV
- [ ] Push notifications
- [ ] Dark mode support
- [ ] Multi-language support
- [ ] Advanced filtering options
- [ ] Data visualization charts
- [ ] Photo upload support
- [ ] GPS location tracking
- [ ] Barcode scanning

### 2. Technical Improvements
- [ ] Unit tests coverage
- [ ] Integration tests
- [ ] CI/CD pipeline
- [ ] Performance monitoring
- [ ] Crash analytics
- [ ] A/B testing framework

## 👥 Tim Developer

- **Lead Developer**: Revanza
- **Backend API**: Lubung Data SAE Team
- **Testing**: QA Team

## 📄 License

Copyright © 2025 Monitoring Restan App. All rights reserved.

---

## 📞 Support

Untuk bantuan teknis atau bug report, hubungi:
- **Developer**: Revanza
- **Email**: [contact-email]
- **Project Repository**: [repository-url]

---

## 🎯 Quick Start Checklist

- [ ] Flutter SDK installed (3.10+)
- [ ] Android development environment ready
- [ ] API server accessible at specified URL
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] Code generation completed (`build_runner build`)
- [ ] App successfully built (`flutter build apk`)
- [ ] Login credentials verified (admin/admin123)
- [ ] API connection tested
- [ ] Database functionality verified
- [ ] Offline mode tested

**Selamat menggunakan Monitoring Restan Mobile App! 🚀**
