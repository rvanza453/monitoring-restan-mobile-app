import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/data_provider.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/filter_dialog.dart';
import '../shared/widgets/detail_dialog.dart';

enum PengirimanView { bloks, tphs, details }

class PengirimanScreen extends StatefulWidget {
  const PengirimanScreen({Key? key}) : super(key: key);

  @override
  State<PengirimanScreen> createState() => _PengirimanScreenState();
}

class _PengirimanScreenState extends State<PengirimanScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _verticalScrollController = ScrollController();
  late TabController _tabController;
  
  // View state
  PengirimanView _currentView = PengirimanView.bloks;
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
      await dataProvider.loadPengirimanData(refresh: true);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FilterDialog(
          onApplyFilters: (Map<String, dynamic> filters) {
             final provider = Provider.of<DataProvider>(context, listen: false);
             setState(() {
               _selectedKerani = filters['kerani'];
             });
             provider.setPengirimanFilters(
               kendaraan: filters['kendaraan'],
               kerani: filters['kerani'],
             );
          },
          onClearFilters: () {
            setState(() {
              _selectedKerani = null;
            });
            Provider.of<DataProvider>(context, listen: false).clearPengirimanFilters();
          },
          filterType: FilterType.pengiriman,
          currentFilters: {
            'kendaraan': Provider.of<DataProvider>(context, listen: false).pengirimanSelectedKendaraan,
            'kerani': _selectedKerani,
          },
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Widget _buildPengirimanCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => DetailDialog.showPengirimanDetail(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Top: Date & Plat Nomor
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
                            _formatDate(item.tanggal),
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
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            item.nomorKendaraan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Middle: Lokasi & Main Stats
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lokasi Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[100]!, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[700]),
                              const SizedBox(width: 4),
                              Text(
                                "Lokasi",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Afd ${item.afdeling}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "Blok ${item.blok}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "TPH ${item.noTph}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Kerani: ${item.namaKerani}",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Stats Box (JJG & Kg)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: _buildStatColumn("Total JJG", "${item.jumlahJanjang + (item.koreksiKirim ?? 0)}"),
                                ),
                                Container(width: 1, height: 30, color: Colors.blue[300]),
                                Expanded(
                                  child: _buildStatColumn("Total Kg", item.kgTotal.toStringAsFixed(1)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "BJR: ${item.bjr?.toStringAsFixed(1) ?? '-'}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Kg Brd: ${item.kgBrd?.toStringAsFixed(1) ?? '-'}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

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
                  
                  _buildSortOption('Tanggal', 'tanggal', Icons.calendar_today, setDialogState),
                  _buildSortOption('Lokasi (Afd-Blok-TPH)', 'lokasi', Icons.location_on, setDialogState),
                  _buildSortOption('Kendaraan', 'kendaraan', Icons.local_shipping, setDialogState),
                  _buildSortOption('Kerani', 'kerani', Icons.badge, setDialogState),
                  _buildSortOption('Jumlah Janjang', 'janjang', Icons.agriculture, setDialogState),
                  _buildSortOption('BJR', 'bjr', Icons.scale, setDialogState),
                  _buildSortOption('Kg Total', 'kg_total', Icons.monitor_weight, setDialogState),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  
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
                    setState(() {});
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

  List<dynamic> _sortPengirimanData(List<dynamic> data) {
    List<dynamic> sortedData = List.from(data);
    
    sortedData.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'tanggal':
          comparison = a.tanggal.compareTo(b.tanggal);
          break;
        case 'lokasi':
          comparison = a.afdeling.compareTo(b.afdeling);
          if (comparison == 0) {
            comparison = a.blok.compareTo(b.blok);
            if (comparison == 0) {
              comparison = a.noTph.compareTo(b.noTph);
              if (comparison == 0) {
                comparison = a.tanggal.compareTo(b.tanggal);
              }
            }
          }
          break;
        case 'kendaraan':
          comparison = a.nomorKendaraan.compareTo(b.nomorKendaraan);
          break;
        case 'kerani':
          comparison = a.namaKerani.compareTo(b.namaKerani);
          break;
        case 'janjang':
          int totalA = a.jumlahJanjang + (a.koreksiKirim ?? 0);
          int totalB = b.jumlahJanjang + (b.koreksiKirim ?? 0);
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
          comparison = a.tanggal.compareTo(b.tanggal);
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
        if (_currentView != PengirimanView.bloks) {
          setState(() {
            if (_currentView == PengirimanView.details) {
              _currentView = PengirimanView.tphs;
              _selectedTph = null;
            } else if (_currentView == PengirimanView.tphs) {
              _currentView = PengirimanView.bloks;
              _selectedBlok = null;
            }
          });
          return false;
        }
        return true;
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
      case PengirimanView.bloks:
        title = 'Pilih Blok Pengiriman';
        actions = [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black54),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ];
        break;
      case PengirimanView.tphs:
        title = 'Blok $_selectedBlok';
        break;
      case PengirimanView.details:
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
      leading: _currentView != PengirimanView.bloks
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  if (_currentView == PengirimanView.details) {
                    _currentView = PengirimanView.tphs;
                    _selectedTph = null;
                  } else if (_currentView == PengirimanView.tphs) {
                    _currentView = PengirimanView.bloks;
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
        if (dataProvider.isSyncing && dataProvider.pengirimanData.isEmpty && _tabController.index == 0) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (dataProvider.pengirimanData.isEmpty && _tabController.index == 0) {
           return EmptyState(
              icon: Icons.local_shipping,
              title: 'Tidak ada data pengiriman',
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
                        _currentView = PengirimanView.bloks;
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
                    Tab(text: 'Data Pengiriman'),
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
                  _buildDataPengirimanTab(dataProvider),
                  _buildRecapTab(dataProvider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataPengirimanTab(DataProvider dataProvider) {
    // Always use filtered data (pengirimanData) to respect all applied filters
    // This ensures blok list only shows bloks that have matching data
    final dataSource = dataProvider.pengirimanData;
    
    switch (_currentView) {
      case PengirimanView.bloks:
        return _buildBlokList(dataSource);
      case PengirimanView.tphs:
        return _buildTphList(dataSource);
      case PengirimanView.details:
        return _buildDetailList(dataSource);
    }
  }

  Widget _buildBlokList(List<dynamic> pengirimanData) {
    // Group by block with normalization to handle case/whitespace differences
    final bloks = pengirimanData
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
          // Use normalization when comparing blok
          final itemsInBlok = pengirimanData.where((p) => 
            DataProvider.normalizeBlok(p.blok) == blok
          );
          // Normalize TPH when counting
          final tphCount = itemsInBlok
              .map((p) => DataProvider.normalizeTph(p.noTph))
              .toSet()
              .length;
          final totalJanjang = itemsInBlok.fold<num>(0, (sum, p) => sum + p.jumlahJanjang + (p.koreksiKirim ?? 0));
          final totalKg = itemsInBlok.fold<double>(0.0, (sum, p) => sum + p.kgTotal);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  blok.substring(0, 1),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
              ),
              title: Text('Blok $blok', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$tphCount TPH • $totalJanjang Janjang • ${totalKg.toStringAsFixed(0)} kg'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  _currentView = PengirimanView.tphs;
                  _selectedBlok = blok;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTphList(List<dynamic> pengirimanData) {
    // Use normalization for blok comparison to handle case/whitespace differences
    final normalizedSelectedBlok = DataProvider.normalizeBlok(_selectedBlok);
    final itemsInBlok = pengirimanData.where((p) => 
      DataProvider.normalizeBlok(p.blok) == normalizedSelectedBlok
    ).toList();
    
    // Normalize TPH values when grouping to handle formatting differences
    final tphs = itemsInBlok
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
        final itemsInTph = itemsInBlok.where((p) => 
          DataProvider.normalizeTph(p.noTph) == tph
        );
        final totalJanjang = itemsInTph.fold<num>(0, (sum, p) => sum + p.jumlahJanjang + (p.koreksiKirim ?? 0));
        final totalKg = itemsInTph.fold<double>(0.0, (sum, p) => sum + p.kgTotal);
        final detailCount = itemsInTph.length;

        return Card(
           elevation: 2,
           margin: const EdgeInsets.only(bottom: 12),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
                backgroundColor: Colors.lightBlue[100],
                child: const Icon(Icons.location_on_outlined, color: Colors.blue),
              ),
            title: Text('TPH $tph', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$detailCount Pengiriman'),
             trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$totalJanjang JJG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${totalKg.toStringAsFixed(0)} Kg', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            onTap: () {
              setState(() {
                _currentView = PengirimanView.details;
                _selectedTph = tph;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailList(List<dynamic> rawPengirimanData) {
    // Use normalization for both blok and TPH comparison
    final normalizedSelectedBlok = DataProvider.normalizeBlok(_selectedBlok);
    final normalizedSelectedTph = DataProvider.normalizeTph(_selectedTph);
    final filteredData = rawPengirimanData
        .where((p) => 
          DataProvider.normalizeBlok(p.blok) == normalizedSelectedBlok && 
          DataProvider.normalizeTph(p.noTph) == normalizedSelectedTph
        )
        .toList();
    
    final pengirimanData = _sortPengirimanData(filteredData);
    
    if (pengirimanData.isEmpty) {
      return const Center(child: Text("Tidak ada pengiriman di TPH ini."));
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _verticalScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: pengirimanData.length + 1,
        itemBuilder: (context, index) {
          if (index == pengirimanData.length) {
            return const SizedBox(height: 80);
          }
          return _buildPengirimanCard(pengirimanData[index]);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB REKAP
  // ---------------------------------------------------------------------------
  Widget _buildRecapTab(DataProvider dataProvider) {
    final pengirimanData = dataProvider.pengirimanData;
    
    if (pengirimanData.isEmpty) {
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

    final summary = _calculatePengirimanSummary(pengirimanData);
    
    // Group by afdeling
    Map<String, List<dynamic>> groupedByAfdeling = {};
    for (var pengiriman in pengirimanData) {
      final afdeling = _normalizeAfdeling(pengiriman.afdeling);
      if (!groupedByAfdeling.containsKey(afdeling)) {
        groupedByAfdeling[afdeling] = [];
      }
      groupedByAfdeling[afdeling]!.add(pengiriman);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGrandTotalCard(summary, Colors.blue),
        const SizedBox(height: 20),
        const Text(
          "Detail per Afdeling",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...groupedByAfdeling.entries.map((entry) {
          final afdelingData = entry.value;
          final afdelingSummary = _calculateAfdelingSummary(afdelingData);
          return _buildAfdelingCard(entry.key, afdelingSummary, Colors.blue);
        }),
      ],
    );
  }

  Map<String, dynamic> _calculatePengirimanSummary(List<dynamic> data) {
    int totalRecords = data.length;
    int totalJanjang = 0;
    double totalKg = 0.0;

    for (var item in data) {
      totalJanjang += ((item.jumlahJanjang as num) + ((item.koreksiKirim as num?) ?? 0)).toInt();
      totalKg += item.kgTotal as double;
    }

    return {
      'totalRecords': totalRecords,
      'totalJanjang': totalJanjang,
      'totalKg': totalKg,
    };
  }

  Map<String, dynamic> _calculateAfdelingSummary(List<dynamic> data) {
    int totalRecords = data.length;
    int totalJanjang = 0;
    double totalKg = 0.0;
    Set<String> locations = {};

    for (var item in data) {
      totalJanjang += ((item.jumlahJanjang as num) + ((item.koreksiKirim as num?) ?? 0)).toInt();
      totalKg += item.kgTotal as double;
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
    
    Color color600 = color == Colors.blue ? Colors.blue[600]! : Colors.green[600]!;
    Color color800 = color == Colors.blue ? Colors.blue[800]! : Colors.green[800]!;
    
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
    
    Color color50 = color == Colors.blue ? Colors.blue[50]! : Colors.green[50]!;
    Color color100 = color == Colors.blue ? Colors.blue[100]! : Colors.green[100]!;
    Color color200 = color == Colors.blue ? Colors.blue[200]! : Colors.green[200]!;
    Color color800 = color == Colors.blue ? Colors.blue[800]! : Colors.green[800]!;
    
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