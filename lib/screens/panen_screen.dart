import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/data_provider.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/filter_dialog.dart';
import '../shared/widgets/detail_dialog.dart';

enum PanenView { bloks, tphs, activities }

class PanenScreen extends StatefulWidget {
  const PanenScreen({Key? key}) : super(key: key);

  @override
  State<PanenScreen> createState() => _PanenScreenState();
}

class _PanenScreenState extends State<PanenScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _verticalScrollController = ScrollController();
  late TabController _tabController;
  
  // View state
  PanenView _currentView = PanenView.bloks;
  String? _selectedBlok;
  String? _selectedTph;

  // Sorting state
  String _sortBy = 'tanggal'; // Default sort by tanggal
  bool _sortAscending = false; // Default descending (terbaru dulu)
  
  // Filter state for kerani
  String? _selectedKerani;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verticalScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // All data is loaded at once, no pagination needed
    // if (_verticalScrollController.position.pixels >=
    //     _verticalScrollController.position.maxScrollExtent - 100) {
    //   final dataProvider = Provider.of<DataProvider>(context, listen: false);
    //   if (!dataProvider.isSyncing) {
    //     // All data already loaded
    //   }
    // }
  }

  Future<void> _onRefresh() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (dataProvider.isOnline) {
      await dataProvider.syncAllData();
    } else {
      await dataProvider.loadPanenData(refresh: true);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FilterDialog(
          onApplyFilters: (Map<String, dynamic> filters) {
            final dataProvider = Provider.of<DataProvider>(context, listen: false);
            setState(() {
              _selectedKerani = filters['kerani'];
            });
            dataProvider.setPanenFilters(
              pemanen: filters['pemanen'],
              kerani: filters['kerani'],
            );
          },
          onClearFilters: () {
            setState(() {
              _selectedKerani = null;
            });
            Provider.of<DataProvider>(context, listen: false).clearPanenFilters();
          },
          filterType: FilterType.panen,
          currentFilters: {
            'pemanen': Provider.of<DataProvider>(context, listen: false).panenSelectedPemanen,
            'kerani': _selectedKerani,
          },
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate); // Format lebih enak dibaca
    } catch (e) {
      return date;
    }
  }

  // WIDGET BARU: Kartu Panen Mobile Friendly
  Widget _buildPanenCard(dynamic panen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => DetailDialog.showPanenDetail(context, panen),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Tanggal & Lokasi (Afdeling/Blok)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(panen.tanggalPemeriksaan),
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Afd ${panen.afdeling} / Blok ${panen.blok}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Body: Pemanen & Jumlah Utama
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
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
                            panen.namaPemanen,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'TPH: ${panen.noTph}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kerani: ${panen.namaKerani}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Highlight Jumlah Janjang
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${panen.jumlahJanjang + (panen.koreksiPanen ?? 0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Janjang',
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
                
                const SizedBox(height: 16),
                
                // Footer: Detail Metrik (Grid Kecil)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[50]!, Colors.grey[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailItem('BJR', panen.bjr?.toStringAsFixed(1) ?? '-', Icons.scale_outlined),
                      _buildVerticalDivider(),
                      _buildDetailItem('Kg Total', panen.kgTotal?.toStringAsFixed(1) ?? '-', Icons.monitor_weight_outlined),
                      _buildVerticalDivider(),
                      _buildDetailItem('Kg Brd', panen.kgBrd?.toStringAsFixed(1) ?? '-', Icons.grain_outlined),
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
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
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 24, width: 1, color: Colors.grey[300]);
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
                    'Lokasi (Afd-Blok-TPH)',
                    'lokasi',
                    Icons.location_on,
                    setDialogState,
                  ),
                  _buildSortOption(
                    'Pemanen',
                    'pemanen',
                    Icons.person,
                    setDialogState,
                  ),
                  _buildSortOption(
                    'Kerani',
                    'kerani',
                    Icons.badge,
                    setDialogState,
                  ),
                  _buildSortOption(
                    'Jumlah Janjang',
                    'janjang',
                    Icons.agriculture,
                    setDialogState,
                  ),
                  _buildSortOption(
                    'BJR',
                    'bjr',
                    Icons.scale,
                    setDialogState,
                  ),
                  _buildSortOption(
                    'Kg Total',
                    'kg_total',
                    Icons.monitor_weight,
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
        leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.green : Colors.black87,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
        onTap: () {
          setDialogState(() {
            _sortBy = value;
          });
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: Colors.green.withOpacity(0.1),
      ),
    );
  }

  /// Sort panen data based on current sort settings
  List<dynamic> _sortPanenData(List<dynamic> data) {
    List<dynamic> sortedData = List.from(data);
    
    sortedData.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'tanggal':
          comparison = a.tanggalPemeriksaan.compareTo(b.tanggalPemeriksaan);
          break;
        case 'lokasi':
          // Sort by afdeling -> blok -> tph -> tanggal
          comparison = a.afdeling.compareTo(b.afdeling);
          if (comparison == 0) {
            comparison = a.blok.compareTo(b.blok);
            if (comparison == 0) {
              comparison = a.noTph.compareTo(b.noTph);
              if (comparison == 0) {
                comparison = a.tanggalPemeriksaan.compareTo(b.tanggalPemeriksaan);
              }
            }
          }
          break;
        case 'pemanen':
          comparison = a.namaPemanen.compareTo(b.namaPemanen);
          break;
        case 'kerani':
          comparison = a.namaKerani.compareTo(b.namaKerani);
          break;
        case 'janjang':
          int totalA = a.jumlahJanjang + (a.koreksiPanen ?? 0);
          int totalB = b.jumlahJanjang + (b.koreksiPanen ?? 0);
          comparison = totalA.compareTo(totalB);
          break;
        case 'bjr':
          final aVal = a.bjr ?? 0.0;
          final bVal = b.bjr ?? 0.0;
          comparison = aVal.compareTo(bVal);
          break;
        case 'kg_total':
          final aVal = a.kgTotal ?? 0.0;
          final bVal = b.kgTotal ?? 0.0;
          comparison = aVal.compareTo(bVal);
          break;
        default:
          comparison = a.tanggalPemeriksaan.compareTo(b.tanggalPemeriksaan);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sortedData;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: () async {
        if (_currentView != PanenView.bloks) {
          setState(() {
            if (_currentView == PanenView.activities) {
              _currentView = PanenView.tphs;
              _selectedTph = null;
            } else if (_currentView == PanenView.tphs) {
              _currentView = PanenView.bloks;
              _selectedBlok = null;
            }
          });
          return false; // Don't pop the route
        }
        return true; // Pop the route
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(),
        body: _buildContent(),
      ),
    );
  }

  AppBar _buildAppBar() {
    String title;
    List<Widget> actions = [];

    switch (_currentView) {
      case PanenView.bloks:
        title = 'Pilih Blok Panen';
        actions = [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black54),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ];
        break;
      case PanenView.tphs:
        title = 'Blok $_selectedBlok';
        break;
      case PanenView.activities:
        title = 'TPH $_selectedTph';
        actions = [
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.black54),
            onPressed: _showSortDialog,
            tooltip: 'Urutkan',
          ),
        ];
        break;
    }

    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      leading: _currentView != PanenView.bloks
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  if (_currentView == PanenView.activities) {
                    _currentView = PanenView.tphs;
                    _selectedTph = null;
                  } else if (_currentView == PanenView.tphs) {
                    _currentView = PanenView.bloks;
                    _selectedBlok = null;
                  }
                });
              },
            )
          : null,
      actions: actions,
    );
  }

  Widget _buildContent() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (dataProvider.isSyncing && dataProvider.panenData.isEmpty && _tabController.index == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (dataProvider.panenData.isEmpty && _tabController.index == 0) {
           return EmptyState(
              icon: Icons.agriculture,
              title: 'Tidak ada data panen',
              message: 'Belum ada data tersedia',
              actionLabel: dataProvider.isOnline ? 'Refresh' : null,
              onAction: dataProvider.isOnline ? _onRefresh : null,
            );
        }
        
        return Column(
          children: [
            // Tab Bar
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
                    setState(() {
                      if (index == 0) {
                        _currentView = PanenView.bloks;
                        _selectedBlok = null;
                        _selectedTph = null;
                      }
                    });
                  },
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
                    Tab(text: 'Data Panen'),
                    Tab(text: 'Rekap'),
                  ],
                ),
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDataPanenTab(dataProvider),
                  _buildRecapTab(dataProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataPanenTab(DataProvider dataProvider) {
    // Always use filtered data (panenData) to respect all applied filters
    // This ensures blok list only shows bloks that have matching data
    final dataSource = dataProvider.panenData;
    
    switch (_currentView) {
      case PanenView.bloks:
        return _buildBlokList(dataSource);
      case PanenView.tphs:
        return _buildTphList(dataSource);
      case PanenView.activities:
        return _buildActivityList(dataSource);
    }
  }

  Widget _buildBlokList(List<dynamic> panenData) {
    // Group by block with normalization to handle case/whitespace differences
    final bloks = panenData
        .map((p) => DataProvider.normalizeBlok(p.blok))
        .where((b) => b.isNotEmpty) // Filter out empty bloks
        .toSet()
        .toList();
    bloks.sort();

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bloks.length,
        itemBuilder: (context, index) {
          final blok = bloks[index];
          // Hitung jumlah TPH dan Janjang untuk ringkasan (use normalization)
          final activitiesInBlok = panenData.where((p) => 
            DataProvider.normalizeBlok(p.blok) == blok
          );
          final tphCount = activitiesInBlok
              .map((p) => DataProvider.normalizeTph(p.noTph))
              .toSet()
              .length;
          final totalJanjang = activitiesInBlok.fold<num>(0, (sum, p) => sum + p.jumlahJanjang + (p.koreksiPanen ?? 0));

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Text(
                  blok.substring(0, 1),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
              ),
              title: Text('Blok $blok', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$tphCount TPH • $totalJanjang Janjang'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  _currentView = PanenView.tphs;
                  _selectedBlok = blok;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTphList(List<dynamic> panenData) {
    // Use normalization for blok comparison to handle case/whitespace differences
    final normalizedSelectedBlok = DataProvider.normalizeBlok(_selectedBlok);
    final activitiesInBlok = panenData.where((p) => 
      DataProvider.normalizeBlok(p.blok) == normalizedSelectedBlok
    ).toList();
    
    // Normalize TPH values when grouping to handle formatting differences
    final tphs = activitiesInBlok
        .map((p) => DataProvider.normalizeTph(p.noTph))
        .toSet()
        .toList();
    tphs.sort((a, b) {
      // Sort numerically if both are numbers, otherwise alphabetically
      final aNum = int.tryParse(a);
      final bNum = int.tryParse(b);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.compareTo(b);
    });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tphs.length,
      itemBuilder: (context, index) {
        final tph = tphs[index];
        // Use normalization when comparing TPH
        final activitiesInTph = activitiesInBlok.where((p) => 
          DataProvider.normalizeTph(p.noTph) == tph
        );
        final totalJanjang = activitiesInTph.fold<num>(0, (sum, p) => sum + p.jumlahJanjang + (p.koreksiPanen ?? 0));
        final activityCount = activitiesInTph.length;

        return Card(
           elevation: 2,
           margin: const EdgeInsets.only(bottom: 12),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
                backgroundColor: Colors.orange[100],
                child: const Icon(Icons.location_on_outlined, color: Colors.orange),
              ),
            title: Text('TPH $tph', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$activityCount Aktivitas'),
             trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$totalJanjang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Janjang', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            onTap: () {
              setState(() {
                _currentView = PanenView.activities;
                _selectedTph = tph;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityList(List<dynamic> rawPanenData) {
    // Use normalization for both blok and TPH comparison
    final normalizedSelectedBlok = DataProvider.normalizeBlok(_selectedBlok);
    final normalizedSelectedTph = DataProvider.normalizeTph(_selectedTph);
    final filteredData = rawPanenData
        .where((p) => 
          DataProvider.normalizeBlok(p.blok) == normalizedSelectedBlok && 
          DataProvider.normalizeTph(p.noTph) == normalizedSelectedTph
        )
        .toList();
    
    final panenData = _sortPanenData(filteredData);
    
    if (panenData.isEmpty) {
      return const Center(child: Text("Tidak ada aktivitas di TPH ini."));
    }

    // Menggunakan kembali RefreshIndicator dan ListView dari implementasi lama
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _verticalScrollController,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        itemCount: panenData.length,
        itemBuilder: (context, index) {
          return _buildPanenCard(panenData[index]);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB REKAP
  // ---------------------------------------------------------------------------
  Widget _buildRecapTab(DataProvider dataProvider) {
    final panenData = dataProvider.panenData;
    
    if (panenData.isEmpty) {
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
            TextButton(onPressed: _onRefresh, child: const Text('Refresh'))
          ],
        ),
      );
    }

    final summary = _calculatePanenSummary(panenData);
    
    // Group by afdeling
    Map<String, List<dynamic>> groupedByAfdeling = {};
    for (var panen in panenData) {
      final afdeling = _normalizeAfdeling(panen.afdeling);
      if (!groupedByAfdeling.containsKey(afdeling)) {
        groupedByAfdeling[afdeling] = [];
      }
      groupedByAfdeling[afdeling]!.add(panen);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGrandTotalCard(summary, Colors.green),
        const SizedBox(height: 20),
        const Text(
          "Detail per Afdeling",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...groupedByAfdeling.entries.map((entry) {
          final afdelingData = entry.value;
          final afdelingSummary = _calculateAfdelingSummary(afdelingData);
          return _buildAfdelingCard(entry.key, afdelingSummary, Colors.green);
        }),
      ],
    );
  }

  Map<String, dynamic> _calculatePanenSummary(List<dynamic> data) {
    int totalRecords = data.length;
    int totalJanjang = 0;
    double totalKg = 0.0;
    double totalBjr = 0.0;
    int bjrCount = 0;

    for (var item in data) {
      totalJanjang += ((item.jumlahJanjang as num) + ((item.koreksiPanen as num?) ?? 0)).toInt();
      totalKg += ((item.kgTotal as num?) ?? 0.0).toDouble();
      if (item.bjr != null && (item.bjr as num) > 0) {
        totalBjr += (item.bjr as num).toDouble();
        bjrCount++;
      }
    }

    return {
      'totalRecords': totalRecords,
      'totalJanjang': totalJanjang,
      'totalKg': totalKg,
      'avgBjr': bjrCount > 0 ? totalBjr / bjrCount : 0.0,
    };
  }

  Map<String, dynamic> _calculateAfdelingSummary(List<dynamic> data) {
    int totalRecords = data.length;
    int totalJanjang = 0;
    double totalKg = 0.0;
    Set<String> locations = {};

    for (var item in data) {
      totalJanjang += ((item.jumlahJanjang as num) + ((item.koreksiPanen as num?) ?? 0)).toInt();
      totalKg += ((item.kgTotal as num?) ?? 0.0).toDouble();
      locations.add('${item.blok}_${item.noTph}');
    }

    return {
      'totalRecords': totalRecords,
      'totalJanjang': totalJanjang,
      'totalKg': totalKg,
      'totalLocations': locations.length,
    };
  }

  Widget _buildGrandTotalCard(Map<String, dynamic> summary, Color color) {
    final totalRecords = summary['totalRecords'] as int;
    final totalJanjang = summary['totalJanjang'] as int;
    
    Color color600 = color == Colors.green ? Colors.green[600]! : Colors.blue[600]!;
    Color color800 = color == Colors.green ? Colors.green[800]! : Colors.blue[800]!;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color600, color800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$totalRecords',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Aktivitas',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$totalJanjang',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Janjang',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
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

  Widget _buildAfdelingCard(String afdeling, Map<String, dynamic> summary, Color color) {
    final totalLocations = summary['totalLocations'] as int;
    final totalJanjang = summary['totalJanjang'] as int;
    
    Color color50 = color == Colors.green ? Colors.green[50]! : Colors.blue[50]!;
    Color color100 = color == Colors.green ? Colors.green[100]! : Colors.blue[100]!;
    Color color200 = color == Colors.green ? Colors.green[200]! : Colors.blue[200]!;
    Color color800 = color == Colors.green ? Colors.green[800]! : Colors.blue[800]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Afdeling $afdeling',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalLocations Lokasi',
                  style: TextStyle(
                    fontSize: 11,
                    color: color800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color100, color50],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color200),
            ),
            child: Column(
              children: [
                Text(
                  '$totalJanjang',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Janjang',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeAfdeling(String? val) {
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
}