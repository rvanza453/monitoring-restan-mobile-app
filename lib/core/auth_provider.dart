import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../constants/app_constants.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthState _authState = AuthState.initial;
  User? _user;
  String? _token;
  DateTime? _tokenExpiry;
  String? _errorMessage;

  // Getters
  AuthState get authState => _authState;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authState == AuthState.authenticated && _token != null;
  bool get isLoading => _authState == AuthState.loading;
  bool get hasError => _authState == AuthState.error;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _setAuthState(AuthState.loading);
    
    try {
      // Try to load saved credentials
      final savedToken = await _secureStorage.read(key: AppConstants.authTokenKey);
      final savedUserData = await _secureStorage.read(key: AppConstants.userDataKey);
      final isLoggedIn = await _secureStorage.read(key: AppConstants.isLoggedInKey);
      
      if (savedToken != null && savedUserData != null && isLoggedIn == 'true') {
        _token = savedToken;
        _user = User.fromJson(jsonDecode(savedUserData));
        _apiService.setAuthToken(savedToken);
        
        // Verify token is still valid
        bool isValid = await _verifyToken();
        if (isValid) {
          _setAuthState(AuthState.authenticated);
        } else {
          await _clearStoredCredentials();
          _setAuthState(AuthState.unauthenticated);
        }
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      print('Auth initialization error: $e');
      _setAuthState(AuthState.unauthenticated);
    }
  }

  Future<bool> login(String username, String password) async {
    _setAuthState(AuthState.loading);
    _clearError();

    try {
      print('🚀 Starting login process...');
      print('📝 Username: $username');
      print('🌐 API Service Base URL: ${_apiService.activeBaseUrl}');
      
      final response = await _apiService.login(username, password);
      
      if (response.success && response.data != null) {
        final authData = response.data!;
        await _saveCredentials(authData);
        _setAuthState(AuthState.authenticated);
        return true;
      } else {
        _setError(response.message);
        _setAuthState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _setError('Login failed: $e');
      _setAuthState(AuthState.unauthenticated);
      return false;
    }
  }

  // Login with automatic endpoint detection and offline support
  Future<bool> loginWithAutoDetection(String username, String password) async {
    _setAuthState(AuthState.loading);
    _clearError();

    try {
      // First try normal login
      final response = await _apiService.login(username, password);
      
      if (response.success && response.data != null) {
        final authData = response.data!;
        await _saveCredentials(authData);
        _setAuthState(AuthState.authenticated);
        return true;
      } else {
        // If failed, try auto-detection
        print('🔄 Login failed, trying endpoint auto-detection...');
        bool foundEndpoint = await _apiService.findAndSetActiveEndpoint();
        
        if (foundEndpoint) {
          print('🔄 Retrying login with new endpoint...');
          final retryResponse = await _apiService.login(username, password);
          
          if (retryResponse.success && retryResponse.data != null) {
            final authData = retryResponse.data!;
            await _saveCredentials(authData);
            _setAuthState(AuthState.authenticated);
            return true;
          }
        }
        
        // If all online attempts failed, check for offline login
        print('🔄 Online login failed, checking offline mode...');
        bool offlineSuccess = await _tryOfflineLogin(username, password);
        if (offlineSuccess) {
          return true;
        }
        
        _setError(response.message);
        _setAuthState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      
      // Try offline login on network error
      print('🔄 Network error, trying offline mode...');
      bool offlineSuccess = await _tryOfflineLogin(username, password);
      if (offlineSuccess) {
        return true;
      }
      
      _setError('Login failed: $e');
      _setAuthState(AuthState.unauthenticated);
      return false;
    }
  }

  Future<bool> _tryOfflineLogin(String username, String password) async {
    try {
      // Check if we have stored credentials
      final prefs = await SharedPreferences.getInstance();
      final storedUsername = prefs.getString('username');
      final storedPassword = prefs.getString('password');
      
      if (storedUsername == username && storedPassword == password) {
        // Use stored token or create temporary one
        final storedToken = prefs.getString('token');
        if (storedToken != null) {
          _token = storedToken;
        } else {
          // Create temporary offline token
          _token = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        _user = User(
          id: prefs.getInt('userId') ?? 1,
          username: username,
          // email: prefs.getString('email') ?? '$username@offline.local',
          role: prefs.getString('role') ?? 'user',
        );
        
        _setAuthState(AuthState.authenticated);
        print('✅ Offline login successful');
        return true;
      }
      
      // Allow default credentials for first time offline use
      if (username == 'admin' && password == 'admin') {
        _token = 'offline_${DateTime.now().millisecondsSinceEpoch}';
        _user = User(
          id: 1,
          username: username,
          // email: '$username@offline.local',
          role: 'admin',
        );
        
        // Save credentials for next offline use
        await _saveOfflineCredentials(username, password);
        _setAuthState(AuthState.authenticated);
        print('✅ Default offline login successful');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Offline login error: $e');
      return false;
    }
  }

  Future<void> _saveOfflineCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
    await prefs.setString('email', '$username@offline.local');
    await prefs.setString('role', user?.role ?? '');
    await prefs.setInt('userId', 1);
  }

  // Guest login - masuk tanpa autentikasi
  Future<bool> loginAsGuest() async {
    _setAuthState(AuthState.loading);
    _clearError();

    try {
      // Create guest user
      _user = User(
        id: 0,
        username: 'Guest',
        role: 'guest',
      );
      
      // Create temporary guest token
      _token = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      
      _setAuthState(AuthState.authenticated);
      print('✅ Guest login successful');
      
      // Notify other providers to load local data
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Guest login error: $e');
      _setError('Gagal masuk sebagai guest: $e');
      _setAuthState(AuthState.unauthenticated);
      return false;
    }
  }

  Future<bool> _verifyToken() async {
    if (_token == null) return false;
    
    try {
      final response = await _apiService.verifyToken();
      
      if (response.success && response.data != null) {
        final authData = response.data!;
        await _saveCredentials(authData);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Token verification failed: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    if (_token == null) return false;
    
    try {
      final response = await _apiService.refreshToken();
      
      if (response.success && response.data != null) {
        final authData = response.data!;
        await _saveCredentials(authData);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Token refresh failed: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _setAuthState(AuthState.loading);
    
    await _clearStoredCredentials();
    _apiService.clearAuthToken();
    _user = null;
    _token = null;
    _tokenExpiry = null;
    
    _setAuthState(AuthState.unauthenticated);
  }

  Future<bool> checkTokenExpiry() async {
    if (_tokenExpiry != null) {
      final now = DateTime.now();
      final timeUntilExpiry = _tokenExpiry!.difference(now);
      
      // Refresh token if it expires in less than 1 hour
      if (timeUntilExpiry.inMinutes < 60) {
        return await refreshToken();
      }
    }
    return true;
  }

  Future<void> _saveCredentials(AuthResponse authData) async {
    _user = authData.user;
    _token = authData.token;
    
    // Parse expiry date from string
    try {
      _tokenExpiry = DateTime.parse(authData.expiresAt);
    } catch (e) {
      print('Error parsing token expiry: $e');
      _tokenExpiry = DateTime.now().add(const Duration(hours: 24)); // Default 24h
    }
    
    // Save to secure storage
    await _secureStorage.write(key: AppConstants.authTokenKey, value: authData.token);
    await _secureStorage.write(key: AppConstants.userDataKey, value: jsonEncode(authData.user.toJson()));
    await _secureStorage.write(key: AppConstants.isLoggedInKey, value: 'true');
    
    // Set token in API service
    _apiService.setAuthToken(authData.token);
    print('🔑 Token set successfully: ${authData.token.substring(0, 20)}...');
    
    notifyListeners();
  }

  Future<void> _clearStoredCredentials() async {
    await _secureStorage.delete(key: AppConstants.authTokenKey);
    await _secureStorage.delete(key: AppConstants.userDataKey);
    await _secureStorage.delete(key: AppConstants.isLoggedInKey);
  }

  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    _authState = AuthState.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}