import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/data_provider.dart';
import '../models/restan_location_summary.dart';
import '../shared/widgets/detail_dialog.dart';

enum RestanView { bloks, tphs, activities }

class MonitoringRestanScreen extends StatefulWidget {
  const MonitoringRestanScreen({super.key});

  @override
  _MonitoringRestanScreenState createState() => _MonitoringRestanScreenState();
}

class _MonitoringRestanScreenState extends State<MonitoringRestanScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  // View state for Data Restan tab
  RestanView _currentView = RestanView.bloks;
  String? _selectedBlok;
  String? _selectedTph;
  
  // Sorting state for activities view
  String _sortBy = 'tanggal';
  bool _sortAscending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.calculateRestanByLocation();
  }

  Future<void> _onRefresh() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (dataProvider.isOnline) {
      await dataProvider.syncAllData();
    } else {
      await _loadData();
    }
  }

  /// Calculate summary from RestanLocationSummary
  Map<String, dynamic> _calculateSummary(List<RestanLocationSummary> data, DataProvider dataProvider) {
    int totalRestanJjg = 0;
    double totalRestanKg = 0;
    int totalKelebihanJjg = 0;
    int totalPanenJjg = 0;
    int totalKirimJjg = 0;
    
    int sesuaiCount = 0;
    int restanCount = 0;
    int kelebihanCount = 0;
    
    // Calculate total activities (not locations)
    // Use panenData and pengirimanData to match the same filters used in panen and pengiriman recap
    int totalPanenActivities = dataProvider.panenData.length;
    int totalPengirimanActivities = dataProvider.pengirimanData.length;
    int totalActivities = totalPanenActivities + totalPengirimanActivities;

    for (var item in data) {
      totalPanenJjg += item.totalPanenJjg;
      totalKirimJjg += item.totalKirimJjg;
      
      if (item.selisihJjg > 0) {
        totalRestanJjg += item.selisihJjg;
        totalRestanKg += item.estRestanKg;
        restanCount++;
      } else if (item.selisihJjg < 0) {
        totalKelebihanJjg += item.selisihJjg.abs();
        kelebihanCount++;
      } else {
        sesuaiCount++;
      }
    }

    return {
      'totalRecords': data.length, 
      'totalActivities': totalActivities, 
      'totalPanenActivities': totalPanenActivities,
      'totalPengirimanActivities': totalPengirimanActivities,
      'totalPanenJjg': totalPanenJjg,
      'totalKirimJjg': totalKirimJjg,
      'totalRestanJjg': totalRestanJjg,
      'totalKelebihanJjg': totalKelebihanJjg,
      'totalRestanKg': totalRestanKg,
      'sesuaiCount': sesuaiCount,
      'restanCount': restanCount,
      'kelebihanCount': kelebihanCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return WillPopScope(
      onWillPop: () async {
        if (_currentView != RestanView.bloks && _tabController.index == 0) {
          setState(() {
            if (_currentView == RestanView.activities) {
              _currentView = RestanView.tphs;
              _selectedTph = null;
            } else if (_currentView == RestanView.tphs) {
              _currentView = RestanView.bloks;
              _selectedBlok = null;
            }
          });
          return false; 
        }
        return true; 
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Consumer<DataProvider>(
          builder: (context, dataProvider, child) {
            if (dataProvider.isSyncing && dataProvider.restanLocationSummary.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                if (_tabController.index == 0 && _currentView != RestanView.bloks)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black87),
                            onPressed: () {
                              setState(() {
                                if (_currentView == RestanView.activities) {
                                  _currentView = RestanView.tphs;
                                  _selectedTph = null;
                                } else if (_currentView == RestanView.tphs) {
                                  _currentView = RestanView.bloks;
                                  _selectedBlok = null;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentView == RestanView.activities 
                                ? 'TPH $_selectedTph' 
                                : 'Blok $_selectedBlok',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (_currentView == RestanView.activities)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.sort, color: Colors.black54, size: 20),
                              onPressed: _showSortDialog,
                              tooltip: 'Urutkan',
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // 2. SEGMENTED CONTROL (Tab Kapsul Modern)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        // Reset view when switching tabs
                        if (index != 0) {
                          setState(() {
                            _currentView = RestanView.bloks;
                            _selectedBlok = null;
                            _selectedTph = null;
                          });
                        }
                      },
                      // Style Tab Kapsul
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.black87,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Data Restan'),
                        Tab(text: 'Rekap'),
                        Tab(text: 'Stats'),
                      ],
                    ),
                  ),
                ),

                // TAB CONTENT
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDataRestanTab(dataProvider),
                      _buildRecapTab(dataProvider),
                      _buildStatisticsTab(dataProvider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }



  // ---------------------------------------------------------------------------
  // TAB 1: DATA RESTAN (View-based: bloks -> tphs -> activities)
  // ---------------------------------------------------------------------------
  Widget _buildDataRestanTab(DataProvider dataProvider) {
    final restanData = dataProvider.restanLocationSummary;
    
    if (restanData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              dataProvider.isOffline 
                ? 'Data tidak tersedia (offline)' 
                : 'Tidak ada data restan ditemukan'
            ),
            TextButton(onPressed: _loadData, child: const Text('Refresh'))
          ],
        ),
      );
    }

    switch (_currentView) {
      case RestanView.bloks:
        return _buildBlokList(restanData);
      case RestanView.tphs:
        return _buildTphList(restanData);
      case RestanView.activities:
        return _buildActivityList(dataProvider);
    }
  }

  Widget _buildBlokList(List<RestanLocationSummary> restanData) {
    // Group by blok
    final bloks = restanData.map((r) => r.blok).toSet().toList();
    bloks.sort();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bloks.length,
        itemBuilder: (context, index) {
          final blok = bloks[index];
          final itemsInBlok = restanData.where((r) => r.blok == blok).toList();
          final tphCount = itemsInBlok.map((r) => r.noTph).toSet().length;
          final totalRestanJjg = itemsInBlok.fold<int>(0, (sum, r) => sum + (r.selisihJjg > 0 ? r.selisihJjg : 0));
          final totalKelebihanJjg = itemsInBlok.fold<int>(0, (sum, r) => sum + (r.selisihJjg < 0 ? r.selisihJjg.abs() : 0));

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.orange[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentView = RestanView.tphs;
                    _selectedBlok = blok;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[400]!, Colors.orange[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            blok.substring(0, 1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Blok $blok',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '$tphCount TPH',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (totalRestanJjg > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalRestanJjg',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (totalKelebihanJjg > 0)
                            Container(
                              margin: EdgeInsets.only(top: totalRestanJjg > 0 ? 4 : 0),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up, size: 14, color: Colors.blue[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalKelebihanJjg',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (totalRestanJjg == 0 && totalKelebihanJjg == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sesuai',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTphList(List<RestanLocationSummary> restanData) {
    final itemsInBlok = restanData.where((r) => r.blok == _selectedBlok).toList();
    final tphs = itemsInBlok.map((r) => r.noTph).toSet().toList();
    tphs.sort();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tphs.length,
      itemBuilder: (context, index) {
        final tph = tphs[index];
        final item = itemsInBlok.firstWhere((r) => r.noTph == tph);
        final restanJjg = item.selisihJjg > 0 ? item.selisihJjg : 0;
        final kelebihanJjg = item.selisihJjg < 0 ? item.selisihJjg.abs() : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.red[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _currentView = RestanView.activities;
                  _selectedTph = tph;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TPH $tph',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Flexible(
                                child: _buildInfoChip(
                                  Icons.agriculture,
                                  'Panen',
                                  '${item.totalPanenJjg}',
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: _buildInfoChip(
                                  Icons.local_shipping,
                                  'Kirim',
                                  '${item.totalKirimJjg}',
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (restanJjg > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red[400]!, Colors.red[600]!],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$restanJjg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Restan',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (kelebihanJjg > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$kelebihanJjg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Kelebihan',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (restanJjg == 0 && kelebihanJjg == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green[400]!, Colors.green[600]!],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Sesuai',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityList(DataProvider dataProvider) {
    final restanData = dataProvider.restanLocationSummary;
    final selectedItem = restanData.firstWhere(
      (r) => r.blok == _selectedBlok && r.noTph == _selectedTph,
      orElse: () => restanData.first,
    );
    
    // Get activities for this TPH
    final activities = dataProvider.getActivitiesForTph(
      selectedItem.afdeling,
      selectedItem.blok,
      selectedItem.noTph,
    );
    
    final panenActivities = activities['panen'] as List;
    final pengirimanActivities = activities['pengiriman'] as List;
    
    // Combine and sort activities
    List<Map<String, dynamic>> allActivities = [];
    
    for (var panen in panenActivities) {
      allActivities.add({
        'type': 'Panen',
        'date': panen.tanggalPemeriksaan,
        'data': panen,
      });
    }
    
    for (var pengiriman in pengirimanActivities) {
      allActivities.add({
        'type': 'Pengiriman',
        'date': pengiriman.tanggal,
        'data': pengiriman,
      });
    }
    
    // Sort by date
    allActivities.sort((a, b) {
      if (_sortAscending) {
        return a['date'].compareTo(b['date']);
      } else {
        return b['date'].compareTo(a['date']);
      }
    });

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          // Summary card for this TPH
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Blok ${selectedItem.blok}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TPH ${selectedItem.noTph}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildActivityStat('Panen Jjg', '${selectedItem.totalPanenJjg}', Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActivityStat('Kirim Jjg', '${selectedItem.totalKirimJjg}', Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActivityStat(
                        'Restan', 
                        '${selectedItem.selisihJjg > 0 ? selectedItem.selisihJjg : 0}', 
                        selectedItem.selisihJjg > 0 ? Colors.red : Colors.green
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Activities list
          Expanded(
            child: allActivities.isEmpty
                ? const Center(child: Text('Tidak ada aktivitas di TPH ini.'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allActivities.length,
                    itemBuilder: (context, index) {
                      final activity = allActivities[index];
                      return _buildActivityCard(activity['type'], activity['data']);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getDarkerColor(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    if (color == Colors.green) return Colors.green[700]!;
    if (color == Colors.blue) return Colors.blue[700]!;
    if (color == Colors.red) return Colors.red[700]!;
    return color;
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: _getDarkerColor(color)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getDarkerColor(color),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String type, dynamic data) {
    final isPanen = type == 'Panen';
    final date = isPanen ? data.tanggalPemeriksaan : data.tanggal;
    final jjg = isPanen 
        ? (data.jumlahJanjang + (data.koreksiPanen ?? 0))
        : (data.jumlahJanjang + (data.koreksiKirim ?? 0));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isPanen 
            ? [Colors.green[50]!, Colors.white]
            : [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isPanen 
            ? Colors.green[200]!
            : Colors.blue[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPanen ? Colors.green : Colors.blue).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isPanen) {
              DetailDialog.showPanenDetail(context, data);
            } else {
              DetailDialog.showPengirimanDetail(context, data);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPanen
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isPanen ? Colors.green : Colors.blue).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPanen ? Icons.agriculture : Icons.local_shipping,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPanen ? Colors.green[100] : Colors.blue[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isPanen ? Colors.green[800] : Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(date),
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPanen 
                          ? 'Pemanen: ${data.namaPemanen}'
                          : 'Kendaraan: ${data.nomorKendaraan}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kerani: ${data.namaKerani}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPanen
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isPanen ? Colors.green : Colors.blue).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$jjg',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Jjg',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: RECAP (Summary per Afdeling)
  // ---------------------------------------------------------------------------
  Widget _buildRecapTab(DataProvider dataProvider) {
    final restanData = dataProvider.restanLocationSummary;
    
    if (restanData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              dataProvider.isOffline 
                ? 'Data tidak tersedia (offline)' 
                : 'Tidak ada data ditemukan'
            ),
            TextButton(onPressed: _loadData, child: const Text('Refresh'))
          ],
        ),
      );
    }

    final summary = _calculateSummary(restanData, dataProvider);
    
    // Group by afdeling
    Map<String, List<RestanLocationSummary>> groupedByAfdeling = {};
    for (var item in restanData) {
      if (!groupedByAfdeling.containsKey(item.afdeling)) {
        groupedByAfdeling[item.afdeling] = [];
      }
      groupedByAfdeling[item.afdeling]!.add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGrandTotalCard(summary),
        const SizedBox(height: 20),
        const Text("Detail per Afdeling", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...groupedByAfdeling.entries.map((entry) {
          final afdelingData = entry.value;
          // For afdeling summary, we need to filter activities by afdeling
          // entry.key is already normalized afdeling from RestanLocationSummary
          // Use panenData and pengirimanData to match the same filters used in panen and pengiriman recap
          final afdelingPanenActivities = dataProvider.panenData
              .where((p) => _normalizeAfdelingString(p.afdeling) == entry.key)
              .length;
          final afdelingPengirimanActivities = dataProvider.pengirimanData
              .where((p) => _normalizeAfdelingString(p.afdeling) == entry.key)
              .length;
          final afdelingSummary = _calculateSummary(afdelingData, dataProvider);
          // Override activities count for afdeling
          afdelingSummary['totalActivities'] = afdelingPanenActivities + afdelingPengirimanActivities;
          afdelingSummary['totalPanenActivities'] = afdelingPanenActivities;
          afdelingSummary['totalPengirimanActivities'] = afdelingPengirimanActivities;
          return _buildAfdelingCard(entry.key, afdelingSummary, afdelingData.length);
        }),
      ],
    );
  }






  // ---------------------------------------------------------------------------
  // TAB 2 & 3: SUMMARY & STATS (Tidak banyak berubah, hanya penyesuaian scroll)
  // ---------------------------------------------------------------------------

  Widget _buildGrandTotalCard(Map<String, dynamic> summary) {
    final totalActivities = summary['totalActivities'] as int? ?? summary['totalRecords'] as int;
    final totalRestanJjg = summary['totalRestanJjg'] as int;
    final totalRestanKg = summary['totalRestanKg'] as double;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'GRAND TOTAL',
              style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('$totalActivities', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const Text('Total Aktivitas', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: Column(
                    children: [
                      Text('$totalRestanJjg', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('${totalRestanKg.toStringAsFixed(0)} Kg Restan', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfdelingCard(String afdeling, Map<String, dynamic> summary, int totalLocations) {
    final restanCount = summary['restanCount'] as int;
    final sesuaiCount = summary['sesuaiCount'] as int;
    final kelebihanCount = summary['kelebihanCount'] as int;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Afdeling $afdeling', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$totalLocations Lokasi', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Restan', '$restanCount', Colors.red),
              _buildMiniStat('Sesuai', '$sesuaiCount', Colors.green),
              _buildMiniStat('Kelebihan', '$kelebihanCount', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  // Helper method to normalize afdeling (same logic as DataProvider)
  String _normalizeAfdelingString(String? val) {
    if (val == null || val.isEmpty) return '';
    String clean = val.trim().toUpperCase();
    if (int.tryParse(clean) != null) return int.parse(clean).toString();
    const romanMap = {
      'I': '1', 'II': '2', 'III': '3', 'IV': '4', 'V': '5',
      'VI': '6', 'VII': '7', 'VIII': '8', 'IX': '9', 'X': '10',
      'XI': '11', 'XII': '12', 'XIII': '13', 'XIV': '14', 'XV': '15'
    };
    return romanMap[clean] ?? clean;
  }

  Widget _buildStatisticsTab(DataProvider dataProvider) {
    final restanData = dataProvider.restanLocationSummary;
    
    if (restanData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              dataProvider.isOffline 
                ? 'Data tidak tersedia (offline)' 
                : 'Tidak ada data statistik'
            ),
            TextButton(onPressed: _loadData, child: const Text('Refresh'))
          ],
        ),
      );
    }

    // Calculate statistics
    // Use panenData and pengirimanData to match the same filters used in panen and pengiriman recap
    int totalPanenActivities = dataProvider.panenData.length;
    int totalPanenJjg = 0;
    double totalPanenKg = 0.0;
    
    int totalTransportActivities = dataProvider.pengirimanData.length;
    int totalTransportJjg = 0;
    double totalTransportKg = 0.0;
    
    int totalLocations = restanData.length;
    int totalRestanJjg = 0;
    double totalRestanKg = 0.0;
    
    // Calculate from actual panen and pengiriman data (with same filters)
    for (var panen in dataProvider.panenData) {
      totalPanenJjg += panen.jumlahJanjang + (panen.koreksiPanen ?? 0);
      totalPanenKg += (panen.kgTotal ?? 0.0);
    }
    
    for (var pengiriman in dataProvider.pengirimanData) {
      totalTransportJjg += pengiriman.jumlahJanjang + (pengiriman.koreksiKirim ?? 0);
      totalTransportKg += pengiriman.kgTotal;
    }
    
    // Calculate restan from location summary
    for (var item in restanData) {
      if (item.selisihJjg > 0) {
        totalRestanJjg += item.selisihJjg;
        totalRestanKg += item.estRestanKg;
      }
    }
    
    double restanPercentage = totalPanenJjg > 0 ? (totalRestanJjg / totalPanenJjg) * 100 : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatisticsCard('Statistik Panen', Icons.agriculture, [
          StatItem('Total Aktivitas', totalPanenActivities.toString()),
          StatItem('Total JJG', totalPanenJjg.toString()),
          StatItem('Total Kg', totalPanenKg.toStringAsFixed(1)),
        ]),
        const SizedBox(height: 12),
        _buildStatisticsCard('Statistik Transport', Icons.local_shipping, [
          StatItem('Total Aktivitas', totalTransportActivities.toString()),
          StatItem('Total JJG', totalTransportJjg.toString()),
          StatItem('Total Kg', totalTransportKg.toStringAsFixed(1)),
        ]),
        const SizedBox(height: 12),
        _buildStatisticsCard('Statistik Restan', Icons.warning_amber_rounded, [
          StatItem('Total Lokasi', totalLocations.toString()),
          StatItem('Total JJG Restan', totalRestanJjg.toString()),
          StatItem('Total Kg Restan', totalRestanKg.toStringAsFixed(1)),
          StatItem('Persentase', '${restanPercentage.toStringAsFixed(1)}%'),
        ]),
      ],
    );
  }

  Widget _buildStatisticsCard(String title, IconData icon, List<StatItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }



  /// --------------------------------------------------------------------------
  /// SORTING DIALOG & LOGIC
  /// --------------------------------------------------------------------------
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Urutkan Data'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Urutkan berdasarkan:', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  
                  // Sort options
                  _buildSortOption(
                    'Tanggal',
                    'tanggal',
                    Icons.calendar_today,
                    setDialogState,
                  ),
                  _buildSortOption(
                    'Jenis',
                    'jenis',
                    Icons.category,
                    setDialogState,
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  
                  // Sort direction
                  Row(
                    children: [
                      const Text('Urutan:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      ToggleButtons(
                        isSelected: [_sortAscending, !_sortAscending],
                        onPressed: (index) {
                          setDialogState(() {
                            _sortAscending = index == 0;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_upward, size: 16),
                                SizedBox(width: 4),
                                Text('A-Z'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_downward, size: 16),
                                SizedBox(width: 4),
                                Text('Z-A'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {}); // Refresh UI with new sorting
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon, StateSetter setDialogState) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
        onTap: () {
          setDialogState(() {
            _sortBy = value;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: Colors.blue.withOpacity(0.1),
      ),
    );
  }
}

class StatItem {
  final String label;
  final String value;
  StatItem(this.label, this.value);
}