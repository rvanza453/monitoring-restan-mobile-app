import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/panen.dart';
import '../models/pengiriman.dart';
import '../models/restan_location_summary.dart';
import 'api_service.dart';
import 'database_helper.dart';
import '../constants/app_constants.dart';
import '../utils/normalization_helper.dart';


enum ConnectionStatus { online, offline, checking }

enum SyncStatus { idle, syncing, success, error }

class DataProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;

  // Connection Status
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  // Sync Status
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _syncMessage;
  DateTime? _lastSyncTime;

  // --- DATA VARIABLES ---

  // 1. Display Data (Filtered & Paginated for UI Table)
  List<Panen> _panenData = [];
  List<Pengiriman> _pengirimanData = [];
  // NEW: Restan data based on location summary
  List<RestanLocationSummary> _restanLocationSummary = [];


  // 2. Master Data (Unfiltered - Source for Dropdowns & Restan Calc)
  List<Panen> _masterPanenData = [];
  List<Pengiriman> _masterPengirimanData = [];
  
  // 3. Filtered data used for restan calculation (with global filters applied)
  List<Panen> _filteredPanenForRestan = [];
  List<Pengiriman> _filteredPengirimanForRestan = [];

  Map<String, int> _databaseStats = {};

  // Global Filters (applied to all tabs)
  String? _globalSelectedAfdeling;
  String? _globalSelectedBlok;
  String? _globalDateFrom;
  String? _globalDateTo;

  // Pagination & Filters for Panen (specific filters only)
  String? _panenSearchQuery;
  String? _panenSelectedPemanen;
  String? _panenSelectedKerani;

  // Pagination & Filters for Pengiriman (specific filters only)
  String? _pengirimanSearchQuery;
  String? _pengirimanSelectedKerani;
  String? _pengirimanSelectedKendaraan;

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isOnline => _connectionStatus == ConnectionStatus.online;
  bool get isOffline => _connectionStatus == ConnectionStatus.offline;

  SyncStatus get syncStatus => _syncStatus;
  String? get syncMessage => _syncMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _syncStatus == SyncStatus.syncing;

  List<Panen> get panenData => _panenData;
  List<Pengiriman> get pengirimanData => _pengirimanData;
  // NEW: Getter for the new restan summary data
  List<RestanLocationSummary> get restanLocationSummary => _restanLocationSummary;
  
  // Getters for master data (unfiltered - for showing all bloks/TPHs)
  List<Panen> get masterPanenData => _masterPanenData;
  List<Pengiriman> get masterPengirimanData => _masterPengirimanData;
  
  // Getters for filtered data used in restan calculation
  List<Panen> get filteredPanenForRestan => _filteredPanenForRestan;
  List<Pengiriman> get filteredPengirimanForRestan => _filteredPengirimanForRestan;
  
  Map<String, int> get databaseStats => _databaseStats;

  // Global filters
  String? get globalSelectedAfdeling => _globalSelectedAfdeling;
  String? get globalSelectedBlok => _globalSelectedBlok;
  String? get globalDateFrom => _globalDateFrom;
  String? get globalDateTo => _globalDateTo;

  // Panen filters (specific only)
  String? get panenSearchQuery => _panenSearchQuery;
  String? get panenSelectedPemanen => _panenSelectedPemanen;
  String? get panenSelectedKerani => _panenSelectedKerani;

  // Pengiriman filters (specific only)
  String? get pengirimanSearchQuery => _pengirimanSearchQuery;
  String? get pengirimanSelectedKerani => _pengirimanSelectedKerani;
  String? get pengirimanSelectedKendaraan => _pengirimanSelectedKendaraan;
  
  // Computed getters for backward compatibility
  String? get panenSelectedAfdeling => _globalSelectedAfdeling;
  String? get panenSelectedBlok => _globalSelectedBlok;
  String? get panenDateFrom => _globalDateFrom;
  String? get panenDateTo => _globalDateTo;
  String? get pengirimanSelectedAfdeling => _globalSelectedAfdeling;
  String? get pengirimanSelectedBlok => _globalSelectedBlok;
  String? get pengirimanDateFrom => _globalDateFrom;
  String? get pengirimanDateTo => _globalDateTo;
  String? get restanSelectedAfdeling => _globalSelectedAfdeling;
  String? get restanSelectedBlok => _globalSelectedBlok;
  String? get restanDateFrom => _globalDateFrom;
  String? get restanDateTo => _globalDateTo;

  DataProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    _globalDateTo = DateFormat('yyyy-MM-dd').format(now);
    _globalDateFrom = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    
    print('📅 Default Date Filter Set: $_globalDateFrom to $_globalDateTo');

    await _checkConnectivity();
    _setupConnectivityListener();
    _setupPeriodicSync();
    await _loadLocalData();
    await _updateDatabaseStats();
  }

  Future<void> _checkConnectivity() async {
    try {
      _connectivityResult = await _connectivity.checkConnectivity();
      await _updateConnectionStatus();
    } catch (e) {
      print('Error checking connectivity: $e');
      _setConnectionStatus(ConnectionStatus.offline);
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) async {
      _connectivityResult = result;
      await _updateConnectionStatus();
    });
  }

  Future<void> _updateConnectionStatus() async {
    if (_connectivityResult == ConnectivityResult.none) {
      _setConnectionStatus(ConnectionStatus.offline);
    } else {
      _setConnectionStatus(ConnectionStatus.checking);
      final hasConnection = await _apiService.checkConnection();
      _setConnectionStatus(
        hasConnection ? ConnectionStatus.online : ConnectionStatus.offline,
      );
      if (hasConnection && _syncStatus == SyncStatus.idle) {
        print('📶 Connection restored, starting background sync...');
        Future.delayed(const Duration(seconds: 2), () async {
          await syncAllData();
        });
      }
    }
  }

  void _setupPeriodicSync() {
    _syncTimer = Timer.periodic(AppConstants.syncInterval, (timer) async {
      if (isOnline && _syncStatus == SyncStatus.idle) {
        await syncAllData();
      }
    });
  }

  void _setConnectionStatus(ConnectionStatus status) {
    _connectionStatus = status;
    notifyListeners();
  }

  void _setSyncStatus(SyncStatus status, {String? message}) {
    _syncStatus = status;
    _syncMessage = message;
    if (status == SyncStatus.success) {
      _lastSyncTime = DateTime.now();
    }
    notifyListeners();
  }

  void _setError(String message) {
    _syncStatus = SyncStatus.error;
    _syncMessage = message;
    notifyListeners();
  }

  Future<void> _loadMasterData() async {
    try {
      print('📥 Loading Master Data (for filters & restan)...');
      _masterPanenData = await _databaseHelper.getAllPanen(limit: null);
      _masterPengirimanData = await _databaseHelper.getAllPengiriman(
        limit: null,
      );
      print(
        '✅ Master Data loaded: ${_masterPanenData.length} Panen, ${_masterPengirimanData.length} Pengiriman',
      );
    } catch (e) {
      print('❌ Error loading master data: $e');
    }
  }

  Future<void> _loadLocalData() async {
    if (isOnline) {
      print('🌐 Online detected, attempting initial data sync...');
      try {
        await _syncPanenData();
        await _syncPengirimanData();
        print('✅ Initial sync completed successfully');
      } catch (e) {
        print('⚠️ Initial sync failed: $e, will use local data');
      }
    }
    await _loadMasterData();
    await Future.wait([
      loadPanenData(refresh: true),
      loadPengirimanData(refresh: true),
    ]);
    // NEW: Call the new calculation method
    await calculateRestanByLocation();
  }

  Future<void> reloadAllLocalData() async {
    print('🔄 Force reloading all local data...');
    await _loadLocalData();
    notifyListeners();
  }

  Future<void> ensureDataAvailable() async {
    final stats = await _databaseHelper.getDatabaseStats();
    if ((stats['panen'] == 0 || stats['pengiriman'] == 0) && isOnline) {
      print('📥 Database empty but online - attempting sync...');
      try {
        if (stats['panen'] == 0) await _syncPanenData();
        if (stats['pengiriman'] == 0) await _syncPengirimanData();
      } catch (e) {
        print('⚠️ Sync failed: $e');
      }
    }
    await _loadMasterData();
    await Future.wait([
      loadPanenData(refresh: true),
      loadPengirimanData(refresh: true),
    ]);
    // NEW: Call the new calculation method
    await calculateRestanByLocation();
  }

  Future<void> loadPanenData({bool refresh = false}) async {
    try {
      if (refresh) notifyListeners();
      final data = await _databaseHelper.getAllPanen(
        search: _panenSearchQuery,
        afdeling: _globalSelectedAfdeling,
        blok: _globalSelectedBlok,
        pemanen: _panenSelectedPemanen,
        kerani: _panenSelectedKerani,
        dateFrom: _globalDateFrom,
        dateTo: _globalDateTo,
        limit: null,
        offset: null,
        sortDirection: 'DESC',
      );
      _panenData = data.toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load data: $e');
    }
  }

  Future<void> loadPengirimanData({bool refresh = false}) async {
    try {
      if (refresh) notifyListeners();
      final data = await _databaseHelper.getAllPengiriman(
        search: _pengirimanSearchQuery,
        afdeling: _globalSelectedAfdeling,
        blok: _globalSelectedBlok,
        kendaraan: _pengirimanSelectedKendaraan,
        kerani: _pengirimanSelectedKerani,
        dateFrom: _globalDateFrom,
        dateTo: _globalDateTo,
        limit: null,
        offset: null,
        sortDirection: 'DESC',
      );
      _pengirimanData = data.toList();
      notifyListeners();
    } catch (e) {
      print('Error loading pengiriman data: $e');
    }
  }

  Future<void> syncAllData() async {
    if (isOffline || isSyncing) return;
    _setSyncStatus(SyncStatus.syncing, message: 'Sinkronisasi data...');
    try {
      await Future.wait([_syncPanenData(), _syncPengirimanData()]);
      await _updateDatabaseStats();
      await _loadMasterData();
      _setSyncStatus(
        SyncStatus.success,
        message: AppConstants.syncSuccessMessage,
      );
      await Future.wait([
        loadPanenData(refresh: true),
        loadPengirimanData(refresh: true),
      ]);
      // NEW: Call the new calculation method
      await calculateRestanByLocation();
    } catch (e) {
      _setSyncStatus(SyncStatus.error, message: 'Error: $e');
    }
    Timer(const Duration(seconds: 3), () {
      if (_syncStatus != SyncStatus.syncing) {
        _setSyncStatus(SyncStatus.idle);
      }
    });
  }

  Future<void> _syncPanenData() async {
    List<Panen> allServerData = [];
    int page = 1;
    bool hasMoreData = true;
    while (hasMoreData) {
      final response = await _apiService.getPanenData(
        page: page,
        limit: AppConstants.maxPageSize,
      );
      if (response.success && response.data != null) {
        final panenList = response.data!.items;
        if (panenList.isNotEmpty) {
          allServerData.addAll(panenList);
          page++;
          hasMoreData = response.data!.pagination.hasNext;
        } else {
          hasMoreData = false;
        }
      } else {
        throw Exception('Failed to fetch panen data on page $page: ${response.message}');
      }
    }
    await _databaseHelper.clearAllPanen();
    if (allServerData.isNotEmpty) {
      await _databaseHelper.insertMultiplePanen(allServerData);
    }
  }

  Future<void> _syncPengirimanData() async {
    List<Pengiriman> allServerData = [];
    int page = 1;
    bool hasMoreData = true;
    while (hasMoreData) {
      final response = await _apiService.getPengirimanData(
        page: page,
        limit: AppConstants.maxPageSize,
      );
      if (response.success && response.data != null) {
        final pengirimanList = response.data!.items;
        if (pengirimanList.isNotEmpty) {
          allServerData.addAll(pengirimanList);
          page++;
          hasMoreData = response.data!.pagination.hasNext;
        } else {
          hasMoreData = false;
        }
      } else {
        throw Exception('Failed to fetch pengiriman data on page $page: ${response.message}');
      }
    }
    await _databaseHelper.clearAllPengiriman();
    if (allServerData.isNotEmpty) {
      await _databaseHelper.insertMultiplePengiriman(allServerData);
    }
  }

  Future<void> _updateDatabaseStats() async {
    _databaseStats = await _databaseHelper.getDatabaseStats();
    notifyListeners();
  }

  void setGlobalFilters({
    String? afdeling,
    String? blok,
    String? dateFrom,
    String? dateTo,
  }) {
    _globalSelectedAfdeling = afdeling;
    _globalSelectedBlok = blok;
    if (dateFrom != null) _globalDateFrom = dateFrom;
    if (dateTo != null) _globalDateTo = dateTo;
    loadPanenData(refresh: true);
    loadPengirimanData(refresh: true);
    // NEW: Call the new calculation method
    calculateRestanByLocation();
    notifyListeners();
  }

  void clearGlobalFilters() {
    _globalSelectedAfdeling = null;
    _globalSelectedBlok = null;
    _globalDateFrom = null;
    _globalDateTo = null;
    loadPanenData(refresh: true);
    loadPengirimanData(refresh: true);
    // NEW: Call the new calculation method
    calculateRestanByLocation();
    notifyListeners();
  }

  void setPanenFilters({ String? search, String? pemanen, String? kerani, }) {
    _panenSearchQuery = search;
    _panenSelectedPemanen = pemanen;
    _panenSelectedKerani = kerani;
    loadPanenData(refresh: true);
  }

  void setPengirimanFilters({ String? search, String? kendaraan, String? kerani, }) {
    _pengirimanSearchQuery = search;
    _pengirimanSelectedKendaraan = kendaraan;
    _pengirimanSelectedKerani = kerani;
    loadPengirimanData(refresh: true);
  }

  void clearPanenFilters() {
    _panenSearchQuery = null;
    _panenSelectedPemanen = null;
    _panenSelectedKerani = null;
    loadPanenData(refresh: true);
  }

  void clearPengirimanFilters() {
    _pengirimanSearchQuery = null;
    _pengirimanSelectedKendaraan = null;
    _pengirimanSelectedKerani = null;
    loadPengirimanData(refresh: true);
  }

  void setRestanFilters({ String? afdeling, String? blok, String? dateFrom, String? dateTo, }) {
    setGlobalFilters(afdeling: afdeling, blok: blok, dateFrom: dateFrom, dateTo: dateTo);
  }

  void clearRestanFilters() {
    clearGlobalFilters();
  }

  Future<void> refreshMonitoringData() async {
    print('🔄 Refreshing monitoring data (new logic)...');
    _setSyncStatus(SyncStatus.syncing, message: 'Calculating restan...');
    await calculateRestanByLocation();
    _setSyncStatus(SyncStatus.success, message: 'Calculation complete');
     Timer(const Duration(seconds: 3), () {
      if (_syncStatus != SyncStatus.syncing) {
        _setSyncStatus(SyncStatus.idle);
      }
    });
  }
  
  // --- NEW RESTAN CALCULATION LOGIC ---
  Future<void> calculateRestanByLocation() async {
    try {
      print('🧮 Calculating restan by location...');
      _restanLocationSummary.clear();
      
      List<Panen> sourcePanen = _masterPanenData;
      List<Pengiriman> sourcePengiriman = _masterPengirimanData;

      // --- Apply Global Filters ---
      if (_globalDateFrom != null) {
        sourcePanen = sourcePanen.where((p) => p.tanggalPemeriksaan.split(' ')[0].compareTo(_globalDateFrom!) >= 0).toList();
        sourcePengiriman = sourcePengiriman.where((p) => p.tanggal.split(' ')[0].compareTo(_globalDateFrom!) >= 0).toList();
      }
      if (_globalDateTo != null) {
        sourcePanen = sourcePanen.where((p) => p.tanggalPemeriksaan.split(' ')[0].compareTo(_globalDateTo!) <= 0).toList();
        sourcePengiriman = sourcePengiriman.where((p) => p.tanggal.split(' ')[0].compareTo(_globalDateTo!) <= 0).toList();
      }
      if (_globalSelectedAfdeling != null) {
        sourcePanen = sourcePanen.where((p) => _normalizeAfdeling(p.afdeling) == _normalizeAfdeling(_globalSelectedAfdeling!)).toList();
        sourcePengiriman = sourcePengiriman.where((p) => _normalizeAfdeling(p.afdeling) == _normalizeAfdeling(_globalSelectedAfdeling!)).toList();
      }
      if (_globalSelectedBlok != null) {
        sourcePanen = sourcePanen.where((p) => _normalizeBlok(p.blok) == _normalizeBlok(_globalSelectedBlok!)).toList();
        sourcePengiriman = sourcePengiriman.where((p) => _normalizeBlok(p.blok) == _normalizeBlok(_globalSelectedBlok!)).toList();
      }
      
      // --- Aggregation ---
      Map<String, Map<String, dynamic>> locationData = {};

      // Aggregate Panen
      for (var panen in sourcePanen) {
        String key = '${_normalizeAfdeling(panen.afdeling)}_${_normalizeBlok(panen.blok)}_${_normalizeTph(panen.noTph)}';
        locationData.putIfAbsent(key, () => {
          'afdeling': _normalizeAfdeling(panen.afdeling),
          'blok': _normalizeBlok(panen.blok),
          'noTph': _normalizeTph(panen.noTph),
          'totalPanenJjg': 0, 'totalKirimJjg': 0,
          'totalPanenKg': 0.0, 'totalKirimKg': 0.0,
          'bjrSum': 0.0, 'panenCount': 0
        });
        
        locationData[key]!['totalPanenJjg'] += (panen.jumlahJanjang + (panen.koreksiPanen ?? 0));
        locationData[key]!['totalPanenKg'] += (panen.kgTotal ?? 0.0);
        if (panen.bjr != null && panen.bjr! > 0) {
          locationData[key]!['bjrSum'] += panen.bjr!;
          locationData[key]!['panenCount'] += 1;
        }
      }

      // Aggregate Pengiriman
      for (var kirim in sourcePengiriman) {
        String key = '${_normalizeAfdeling(kirim.afdeling)}_${_normalizeBlok(kirim.blok)}_${_normalizeTph(kirim.noTph)}';
        locationData.putIfAbsent(key, () => {
          'afdeling': _normalizeAfdeling(kirim.afdeling),
          'blok': _normalizeBlok(kirim.blok),
          'noTph': _normalizeTph(kirim.noTph),
          'totalPanenJjg': 0, 'totalKirimJjg': 0,
          'totalPanenKg': 0.0, 'totalKirimKg': 0.0,
          'bjrSum': 0.0, 'panenCount': 0
        });
        
        locationData[key]!['totalKirimJjg'] += (kirim.jumlahJanjang + (kirim.koreksiKirim ?? 0));
        locationData[key]!['totalKirimKg'] += kirim.kgTotal;
      }

      // --- Store filtered data for activity count ---
      _filteredPanenForRestan = sourcePanen;
      _filteredPengirimanForRestan = sourcePengiriman;
      
      // --- Create Summary List ---
      List<RestanLocationSummary> summaries = [];
      locationData.forEach((key, data) {
        int selisih = data['totalPanenJjg'] - data['totalKirimJjg'];
        // Only include if there is a difference
        if (selisih != 0) {
           double avgBjr = (data['panenCount'] > 0) ? data['bjrSum'] / data['panenCount'] : 15.0; // default bjr
           summaries.add(RestanLocationSummary(
            afdeling: data['afdeling'],
            blok: data['blok'],
            noTph: data['noTph'],
            totalPanenJjg: data['totalPanenJjg'],
            totalKirimJjg: data['totalKirimJjg'],
            totalPanenKg: data['totalPanenKg'],
            totalKirimKg: data['totalKirimKg'],
            bjr: avgBjr,
          ));
        }
      });
      
      _restanLocationSummary = summaries;
      print('✅ Calculated ${_restanLocationSummary.length} restan location summaries.');
      
    } catch (e) {
      print('❌ Error calculating restan by location: $e');
    } finally {
      notifyListeners();
    }
  }

  // --- NEW: Method to get activities for a specific TPH ---
  Map<String, List> getActivitiesForTph(String afdeling, String blok, String noTph) {
    List<Panen> panenActivities = _masterPanenData.where((p) => 
        _normalizeAfdeling(p.afdeling) == afdeling &&
        _normalizeBlok(p.blok) == blok &&
        _normalizeTph(p.noTph) == noTph
      ).toList();

    List<Pengiriman> pengirimanActivities = _masterPengirimanData.where((p) => 
        _normalizeAfdeling(p.afdeling) == afdeling &&
        _normalizeBlok(p.blok) == blok &&
        _normalizeTph(p.noTph) == noTph
      ).toList();
    
    // Sort by date descending
    panenActivities.sort((a, b) => b.tanggalPemeriksaan.compareTo(a.tanggalPemeriksaan));
    pengirimanActivities.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    
    return {'panen': panenActivities, 'pengiriman': pengirimanActivities};
  }


  // --- UTILITY METHODS ---

  String getConnectionStatusText() {
    switch (_connectionStatus) {
      case ConnectionStatus.online: return 'Online';
      case ConnectionStatus.offline: return 'Offline';
      case ConnectionStatus.checking: return 'Checking...';
    }
  }

  Color getConnectionStatusColor() {
    switch (_connectionStatus) {
      case ConnectionStatus.online: return Colors.green;
      case ConnectionStatus.offline: return Colors.red;
      case ConnectionStatus.checking: return Colors.orange;
    }
  }

  // --- DROPDOWN SOURCE GETTERS ---

  List<String> getPanenAfdelings() {
    final source = _masterPanenData.isNotEmpty ? _masterPanenData : _panenData;
    return source.map<String>((p) => _normalizeAfdeling(p.afdeling)).toSet().toList()..sort();
  }

  List<String> getPanenBloks() {
    final source = _masterPanenData.isNotEmpty ? _masterPanenData : _panenData;
    return source.map((p) => p.blok).toSet().toList()..sort();
  }

  List<String> getPanenPemanen() {
    final source = _masterPanenData.isNotEmpty ? _masterPanenData : _panenData;
    return source.map((p) => p.namaPemanen).toSet().toList()..sort();
  }

  List<String> getPanenKerani() {
    final source = _masterPanenData.isNotEmpty ? _masterPanenData : _panenData;
    return source.map((p) => p.namaKerani).toSet().toList()..sort();
  }

  List<String> getPengirimanAfdelings() {
    final source = _masterPengirimanData.isNotEmpty ? _masterPengirimanData : _pengirimanData;
    return source.map<String>((p) => _normalizeAfdeling(p.afdeling)).toSet().toList()..sort();
  }

  List<String> getPengirimanBloks() {
    final source = _masterPengirimanData.isNotEmpty ? _masterPengirimanData : _pengirimanData;
    return source.map((p) => p.blok).toSet().toList()..sort();
  }

  List<String> getPengirimanKendaraan() {
    final source = _masterPengirimanData.isNotEmpty ? _masterPengirimanData : _pengirimanData;
    return source.map((p) => p.nomorKendaraan).toSet().toList()..sort();
  }

  List<String> getPengirimanKerani() {
    final source = _masterPengirimanData.isNotEmpty ? _masterPengirimanData : _pengirimanData;
    return source.map((p) => p.namaKerani).toSet().toList()..sort();
  }

  List<String> getRestanAfdelings() {
    final source = _masterPanenData.isNotEmpty ? _masterPanenData : _panenData;
    return source.map<String>((p) => _normalizeAfdeling(p.afdeling)).toSet().where((s) => s.isNotEmpty).toList()..sort();
  }

  List<String> getRestanBloks() {
    final source = _masterPanenData.isNotEmpty ? _masterPanenData : _panenData;
    return source.map((p) => p.blok).toSet().toList()..sort();
  }

  List<String> getRestanKerani() {
    Set<String> keraniSet = {};
    final panenSource = _masterPanenData.isNotEmpty ? _masterPanenData : _panenData;
    keraniSet.addAll(panenSource.map((p) => p.namaKerani));
    final pengirimanSource = _masterPengirimanData.isNotEmpty ? _masterPengirimanData : _pengirimanData;
    keraniSet.addAll(pengirimanSource.map((p) => p.namaKerani));
    return keraniSet.toList()..sort();
  }

  // Use NormalizationHelper for consistency (private methods)
  String _normalizeAfdeling(String? val) => NormalizationHelper.normalizeAfdeling(val);
  String _normalizeBlok(String? val) => NormalizationHelper.normalizeBlok(val);
  String _normalizeTph(String? val) => NormalizationHelper.normalizeTph(val);
  
  // Static methods for backward compatibility (used in UI screens)
  static String normalizeAfdeling(String? val) => NormalizationHelper.normalizeAfdeling(val);
  static String normalizeBlok(String? val) => NormalizationHelper.normalizeBlok(val);
  static String normalizeTph(String? val) => NormalizationHelper.normalizeTph(val);

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
