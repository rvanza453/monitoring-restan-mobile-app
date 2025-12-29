import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/auth_response.dart';
import '../models/panen.dart';
import '../models/pengiriman.dart';
import '../constants/app_constants.dart';
import '../constants/network_utils.dart';

class ApiService {
  static ApiService? _instance;
  late Dio _dio;
  String? _authToken;
  String? _activeBaseUrl;

  ApiService._internal() {
    _initializeDio();
  }

  void _initializeDio([String? baseUrl]) {
    _activeBaseUrl = baseUrl ?? AppConstants.baseUrl;
    _dio = Dio(BaseOptions(
      baseUrl: _activeBaseUrl!,
      connectTimeout: const Duration(seconds: 10), // Reduced timeout
      receiveTimeout: const Duration(seconds: 15), // Reduced timeout
      sendTimeout: const Duration(seconds: 10),    // Added send timeout
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // Accept all status codes to handle them manually
        return status != null && status < 500;
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          // Try multiple token formats for PHP server compatibility
          options.headers['Authorization'] = 'Bearer $_authToken';
          options.headers['X-Authorization'] = _authToken; // Alternative header
          options.headers['X-Auth-Token'] = _authToken;   // Another common format
          
          // Also add as query parameter for PHP servers that don't read headers
          options.queryParameters ??= {};
          options.queryParameters['token'] = _authToken;
          
          print('🔑 Adding auth header: Bearer ${_authToken!.substring(0, 20)}...');
          print('🔑 Also added as X-Authorization, X-Auth-Token headers and ?token query');
        } else {
          print('⚠️ No auth token available for request');
        }
        print('🚀 Request: ${options.method} ${options.uri}');
        print('🌐 Full URL: ${options.uri.toString()}');
        if (options.data != null) {
          print('📤 Data: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.message}');
        if (error.response != null) {
          print('❌ Response: ${error.response?.data}');
        }
        handler.next(error);
      },
    ));
  }

  factory ApiService() {
    return _instance ??= ApiService._internal();
  }

  // Singleton getter
  static ApiService get instance {
    return _instance ??= ApiService._internal();
  }

  // Auto-detect working API endpoint
  Future<bool> findAndSetActiveEndpoint() async {
    print('🔍 Auto-detecting API endpoint...');
    
    String? workingHost = await NetworkUtils.findActiveApiHost();
    
    if (workingHost != null) {
      print('✅ Found working API: $workingHost');
      _initializeDio(workingHost);
      return true;
    } else {
      print('❌ No working API endpoint found');
      return false;
    }
  }

  // Get current active base URL
  String? get activeBaseUrl => _activeBaseUrl;

  // Set auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear auth token
  void clearAuthToken() {
    _authToken = null;
  }

  // Authentication endpoints
  Future<ApiResponse<AuthResponse>> login(String username, String password) async {
    try {
      print('🚀 Attempting login to: ${_activeBaseUrl}/auth.php/login');
      print('📤 Username: $username');
      print('🔧 Using Dio base URL: ${_dio.options.baseUrl}');
      
      final response = await _dio.post(
        '/auth.php/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      print('✅ Login response received: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        setAuthToken(apiResponse.data!.token);
        print('🔑 Token set successfully');
      }

      return apiResponse;
    } on DioException catch (e) {
      print('❌ DioException occurred:');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');
      
      return _handleDioError<AuthResponse>(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<AuthResponse>> verifyToken() async {
    try {
      print('🔐 Verifying token...');
      print('🔑 Token: ${_authToken?.substring(0, 20)}...');
      
      // Try multiple ways to send token
      final response = await _dio.get(
        '/auth.php/verify',
        queryParameters: {'token': _authToken}, // Add as query parameter
        options: Options(
          headers: {
            'Authorization': 'Bearer $_authToken',
            'X-Authorization': _authToken,
            'X-Auth-Token': _authToken,
          },
        ),
      );
      
      print('📨 Token verify status: ${response.statusCode}');
      print('📨 Token verify response: ${response.data}');

      return ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleDioError<AuthResponse>(e);
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<AuthResponse>> refreshToken() async {
    try {
      final response = await _dio.post('/auth.php/refresh');

      final apiResponse = ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.success && apiResponse.data != null) {
        setAuthToken(apiResponse.data!.token);
      }

      return apiResponse;
    } on DioException catch (e) {
      return _handleDioError<AuthResponse>(e);
    } catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // Panen endpoints
  Future<ApiListResponse<Panen>> getPanenData({
    int page = 1,
    int limit = 100,
    String sortBy = 'tanggal_pemeriksaan',
    String sortDirection = 'DESC',
    String? dateFrom,
    String? dateTo,
    String? afdeling,
    String? blok,
    String? pemanen,
    String? kerani,
    int? minJanjang,
    int? maxJanjang,
  }) async {
    try {
      print('🚜 Loading panen data...');
      print('📄 Page: $page, Limit: $limit');
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_direction': sortDirection,
      };

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (afdeling != null) queryParams['afdeling'] = afdeling;
      if (blok != null) queryParams['blok'] = blok;
      if (pemanen != null) queryParams['pemanen'] = pemanen;
      if (kerani != null) queryParams['kerani'] = kerani;
      if (minJanjang != null) queryParams['min_janjang'] = minJanjang;
      if (maxJanjang != null) queryParams['max_janjang'] = maxJanjang;

      final response = await _dio.get(
        '/panen.php/',
        queryParameters: queryParams,
      );

      return ApiListResponse<Panen>.fromJson(
        response.data,
        (json) => Panen.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final errorResponse = _handleDioError<ApiListData<Panen>>(e);
      return ApiListResponse<Panen>(
        success: errorResponse.success,
        message: errorResponse.message,
        timestamp: errorResponse.timestamp,
        details: errorResponse.details,
      );
    } catch (e) {
      return ApiListResponse<Panen>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<Panen>> getPanenById(int id) async {
    try {
      final response = await _dio.get('/panen.php/$id');

      return ApiResponse<Panen>.fromJson(
        response.data,
        (json) => Panen.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleDioError<Panen>(e);
    } catch (e) {
      return ApiResponse<Panen>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPanenStatistics({
    String? dateFrom,
    String? dateTo,
    String? afdeling,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (afdeling != null) queryParams['afdeling'] = afdeling;

      final response = await _dio.get(
        '/panen.php/statistics',
        queryParameters: queryParams,
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // Pengiriman endpoints
  Future<ApiListResponse<Pengiriman>> getPengirimanData({
    int page = 1,
    int limit = 100,
    String sortBy = 'tanggal',
    String sortDirection = 'DESC',
    String? dateFrom,
    String? dateTo,
    String? afdeling,
    String? blok,
    String? nopol,
    String? kerani,
    int? minJanjang,
    int? maxJanjang,
    double? minKg,
    double? maxKg,
    String? tipeAplikasi,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_direction': sortDirection,
      };

      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (afdeling != null) queryParams['afdeling'] = afdeling;
      if (blok != null) queryParams['blok'] = blok;
      if (nopol != null) queryParams['nopol'] = nopol;
      if (kerani != null) queryParams['kerani'] = kerani;
      if (minJanjang != null) queryParams['min_janjang'] = minJanjang;
      if (maxJanjang != null) queryParams['max_janjang'] = maxJanjang;
      if (minKg != null) queryParams['min_kg'] = minKg;
      if (maxKg != null) queryParams['max_kg'] = maxKg;
      if (tipeAplikasi != null) queryParams['tipe_aplikasi'] = tipeAplikasi;

      final response = await _dio.get(
        '/pengiriman.php/',
        queryParameters: queryParams,
      );

      return ApiListResponse<Pengiriman>.fromJson(
        response.data,
        (json) => Pengiriman.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      final errorResponse = _handleDioError<ApiListData<Pengiriman>>(e);
      return ApiListResponse<Pengiriman>(
        success: errorResponse.success,
        message: errorResponse.message,
        timestamp: errorResponse.timestamp,
        details: errorResponse.details,
      );
    } catch (e) {
      return ApiListResponse<Pengiriman>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<Pengiriman>> getPengirimanById(int id) async {
    try {
      final response = await _dio.get('/pengiriman.php/$id');

      return ApiResponse<Pengiriman>.fromJson(
        response.data,
        (json) => Pengiriman.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleDioError<Pengiriman>(e);
    } catch (e) {
      return ApiResponse<Pengiriman>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPengirimanStatistics({
    String? dateFrom,
    String? dateTo,
    String? afdeling,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (afdeling != null) queryParams['afdeling'] = afdeling;

      final response = await _dio.get(
        '/pengiriman.php/statistics',
        queryParameters: queryParams,
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // Monitoring Restan API Methods
  Future<ApiResponse<Map<String, dynamic>>> getMonitoringRecap({
    String? dateFrom,
    String? dateTo,
    String? afdeling,
    String? blok,
    String? status,
    int? minRestan,
  }) async {
    try {
      print('📊 Fetching monitoring recap data...');
      
      Map<String, String> params = {};
      
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (afdeling != null) params['afdeling'] = afdeling;
      if (blok != null) params['blok'] = blok;
      if (status != null) params['status'] = status;
      if (minRestan != null) params['min_restan'] = minRestan.toString();
      
      final response = await _dio.get(
        '/monitoring_restan.php/recap',
        queryParameters: params,
      );
      
      print('📊 Monitoring recap response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'] ?? 'Recap data retrieved successfully',
          data: data['data'],
          timestamp: data['timestamp'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to retrieve recap data',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on DioException catch (e) {
      print('❌ Error fetching monitoring recap: $e');
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getMonitoringStatistics({
    String? dateFrom,
    String? dateTo,
    String? afdeling,
    String? blok,
  }) async {
    try {
      print('📈 Fetching monitoring statistics...');
      
      Map<String, String> params = {};
      
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (afdeling != null) params['afdeling'] = afdeling;
      if (blok != null) params['blok'] = blok;
      
      final response = await _dio.get(
        '/monitoring_restan.php/statistics',
        queryParameters: params,
      );
      
      print('📈 Statistics response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'] ?? 'Statistics retrieved successfully',
          data: data['data'],
          timestamp: data['timestamp'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to retrieve statistics',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on DioException catch (e) {
      print('❌ Error fetching statistics: $e');
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getMonitoringSummary({
    String? dateFrom,
    String? dateTo,
    String? afdeling,
    String? blok,
  }) async {
    try {
      print('📋 Fetching monitoring summary...');
      
      Map<String, String> params = {};
      
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (afdeling != null) params['afdeling'] = afdeling;
      if (blok != null) params['blok'] = blok;
      
      final response = await _dio.get(
        '/monitoring_restan.php/summary',
        queryParameters: params,
      );
      
      print('📋 Summary response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'] ?? 'Summary retrieved successfully',
          data: data['data'],
          timestamp: data['timestamp'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to retrieve summary',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on DioException catch (e) {
      print('❌ Error fetching summary: $e');
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Unexpected error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // Utility methods
  Future<bool> checkConnection() async {
    try {
      print('🔍 Checking API connection...');
      final response = await _dio.get('/auth.php/verify');
      print('📶 Connection check response: ${response.statusCode}');
      
      // Even 401 (unauthorized) means the API is reachable
      // We only care if the server responds, not about authentication
      return response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      print('❌ Connection check failed: $e');
      return false;
    }
  }

  ApiResponse<T> _handleDioError<T>(DioException error) {
    String message;
    String? details;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          message = 'Authentication failed. Please login again.';
          clearAuthToken();
        } else if (statusCode == 403) {
          message = 'Access denied. You don\'t have permission to access this resource.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Server returned error ${statusCode ?? 'unknown'}';
        }
        
        if (error.response?.data != null) {
          try {
            final responseData = error.response!.data;
            if (responseData is Map<String, dynamic>) {
              message = responseData['message'] ?? message;
              details = responseData['details'];
            }
          } catch (e) {
            // Ignore parsing errors
          }
        }
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      default:
        message = 'Network error: ${error.message}';
        break;
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      timestamp: DateTime.now().toIso8601String(),
      details: details,
    );
  }
}