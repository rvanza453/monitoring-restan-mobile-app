import 'package:dio/dio.dart';

class NetworkUtils {
  static const List<String> possibleHosts = [
    'http://192.168.1.219',
    'http://192.168.0.219', 
    'http://10.0.0.219',
    'http://172.16.0.219',
    'http://localhost',
    'http://127.0.0.1',
  ];

  static Future<String?> findActiveApiHost() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    for (String host in possibleHosts) {
      try {
        print('🔍 Testing host: $host');
        final response = await dio.get('$host/lubung-data-SAE/api/auth.php/verify');
        
        if (response.statusCode == 200 || response.statusCode == 401) {
          print('✅ Active host found: $host');
          return '$host/lubung-data-SAE/api';
        }
      } catch (e) {
        print('❌ Host $host failed: $e');
        continue;
      }
    }
    
    print('🚨 No active API host found');
    return null;
  }

  static Future<bool> testApiEndpoint(String baseUrl) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      print('🧪 Testing API endpoint: $baseUrl/auth.php/login');
      
      final response = await dio.post(
        '$baseUrl/auth.php/login',
        data: {'username': 'test', 'password': 'test'},
      );

      // Even if login fails, if we get a response, API is working
      return response.statusCode != null;
    } catch (e) {
      print('❌ API test failed: $e');
      return false;
    }
  }

  static Future<String> getDeviceIP() async {
    try {
      final dio = Dio();
      // Use a simple service to get device IP
      final response = await dio.get('https://api.ipify.org');
      return response.data.toString();
    } catch (e) {
      return 'Unknown';
    }
  }
}