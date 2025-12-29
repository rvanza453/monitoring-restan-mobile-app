import '../models/panen.dart';
import '../models/pengiriman.dart';
import 'api_service.dart';
import 'database_helper.dart';

class SyncService {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
}