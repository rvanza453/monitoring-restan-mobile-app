class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://10.103.180.181/lubung-data-SAE/api';
  static const int apiTimeout = 30000; // 30 seconds
  
  // Database
  static const String databaseName = 'monitoring_restan.db';
  static const int databaseVersion = 1;
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String lastSyncKey = 'last_sync';
  static const String isLoggedInKey = 'is_logged_in';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Sync Settings
  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration connectionCheckInterval = Duration(seconds: 10);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Date Formats
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  
  // Error Messages
  static const String networkErrorMessage = 'Tidak ada koneksi internet. Data ditampilkan dari storage offline.';
  static const String loginErrorMessage = 'Login gagal. Periksa username dan password Anda.';
  static const String serverErrorMessage = 'Terjadi kesalahan server. Silakan coba lagi nanti.';
  static const String noDataMessage = 'Tidak ada data tersedia';
  static const String syncSuccessMessage = 'Data berhasil disinkronisasi';
  static const String syncErrorMessage = 'Gagal sinkronisasi data';
}