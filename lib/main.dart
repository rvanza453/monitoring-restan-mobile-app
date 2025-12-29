import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth_provider.dart';
import 'core/data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'core/database_helper.dart';

void main() async {
  // 1. Wajib dipanggil jika main() menjadi async
  WidgetsFlutterBinding.ensureInitialized();

  // --- 🔍 MULAI DIAGNOSA DATABASE ---
  print("\n=================================================================");
  print("🚀 STARTUP DIAGNOSIS: Memeriksa Database sebelum aplikasi mulai...");
  
  try {
    // Kita inisialisasi helper dan cek isinya langsung
    final dbHelper = DatabaseHelper();
    
    // Cek jumlah data Panen
    final panenCount = await dbHelper.getPanenCount();
    
    // Cek jumlah data Pengiriman
    final pengirimanCount = await dbHelper.getPengirimanCount();
    
    print("📊 Status Database Saat Ini:");
    print("   - Jumlah Data Panen      : $panenCount");
    print("   - Jumlah Data Pengiriman : $pengirimanCount");

    if (panenCount > 0 || pengirimanCount > 0) {
      print("✅ HASIL: Data ASLI ditemukan! Database aman & persisten.");
      print("   (Jika di layar masih kosong, berarti masalah ada di Filter UI/Provider)");
    } else {
      print("⚠️ HASIL: Database KOSONG (0 data).");
      print("   Kemungkinan penyebab:");
      print("   1. Aplikasi baru diinstall/direset.");
      print("   2. Proses Debugging mereset data.");
      print("   3. Ada kode 'clearDatabase' yang berjalan.");
    }
  } catch (e) {
    print("❌ ERROR saat cek database: $e");
  }
  print("=================================================================\n");
  // --- SELESAI DIAGNOSA ---

  runApp(const MonitoringRestanApp());
}

class MonitoringRestanApp extends StatelessWidget {
  const MonitoringRestanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'Monitoring Restan App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF4CAF50),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AuthWrapper now listens to both AuthProvider and DataProvider
    return Consumer2<AuthProvider, DataProvider>(
      builder: (context, authProvider, dataProvider, child) {
        
        final authContent = _buildAuthContent(authProvider);

        // Show offline banner if not connected, based on DataProvider's status
        if (dataProvider.isOffline) {
          return Scaffold(
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red,
                  child: const SafeArea(
                    bottom: false,
                    child: Text(
                      '❌ NO INTERNET CONNECTION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: authContent,
                ),
              ],
            ),
          );
        }
        
        return authContent;
      },
    );
  }

  Widget _buildAuthContent(AuthProvider authProvider) {
    print('🔍 Auth state: ${authProvider.authState}');
    
    switch (authProvider.authState) {
      case AuthState.initial:
      case AuthState.loading:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memuat aplikasi...'),
              ],
            ),
          ),
        );
      case AuthState.authenticated:
        return const HomeScreen();
      case AuthState.unauthenticated:
      case AuthState.error:
        return const LoginScreen();
    }
  }
}