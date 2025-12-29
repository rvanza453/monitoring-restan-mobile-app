import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../widgets/filter_dialog.dart';

class RestanScreen extends StatefulWidget {
  const RestanScreen({Key? key}) : super(key: key);

  @override
  _RestanScreenState createState() => _RestanScreenState();
}

class _RestanScreenState extends State<RestanScreen> {
  // Controller untuk sinkronisasi scroll horizontal
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _dataHorizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().refreshRestanData();
    });

    // Listener untuk menghubungkan kedua controller horizontal
    _headerScrollController.addListener(() {
      if (_dataHorizontalScrollController.hasClients &&
          _headerScrollController.offset !=
              _dataHorizontalScrollController.offset) {
        _dataHorizontalScrollController.jumpTo(_headerScrollController.offset);
      }
    });

    _dataHorizontalScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _dataHorizontalScrollController.offset !=
              _headerScrollController.offset) {
        _headerScrollController.jumpTo(_dataHorizontalScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _dataHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Monitoring Restan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              final hasFilters = dataProvider.restanSelectedAfdeling != null ||
                  dataProvider.restanSelectedBlok != null ||
                  dataProvider.restanDateFrom != null ||
                  dataProvider.restanDateTo != null;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: hasFilters ? Colors.blue[600] : Colors.black87,
                    ),
                    onPressed: _showFilterDialog,
                  ),
                  if (hasFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      // PERUBAHAN UTAMA: Menggunakan CustomScrollView untuk Sticky Header
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          final restanData = dataProvider.restanData;

          if (dataProvider.isSyncing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data restan...'),
                ],
              ),
            );
          }

          if (restanData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data restan',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan login dan refresh untuk update data',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Hitung Statistik Dashboard
          final totalRestanJjg = restanData
              .where((item) => item.selisihJjg > 0)
              .fold(0, (sum, item) => sum + item.selisihJjg);

          final totalRestanKg = restanData
              .where((item) => item.selisihJjg > 0)
              .fold(0.0, (sum, item) => sum + (item.selisihJjg * item.bjr));

          final criticalRestan =
              restanData.where((item) => item.delayDays > 1).length;
          final affectedLocations =
              restanData.map((e) => "${e.blok}-${e.noTph}").toSet().length;

          return CustomScrollView(
            slivers: [
              // 1. BAGIAN DASHBOARD (Ikut terscroll hilang)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Restan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'Total Janjang',
                                  totalRestanJjg.toString(),
                                  Icons.agriculture,
                                  Colors.orange,
                                  isHighlight: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'Estimasi Berat',
                                  '${(totalRestanKg / 1000).toStringAsFixed(1)} Ton',
                                  Icons.scale,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'Restan > 1 Hari',
                                  '$criticalRestan Lokasi',
                                  Icons.warning_amber_rounded,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'Area Terdampak',
                                  '$affectedLocations TPH',
                                  Icons.map_outlined,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1, height: 1),
                    // Judul Tabel
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detail Data Restan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. HEADER TABEL (Sticky/Menempel saat discroll)
              SliverPersistentHeader(
                pinned: true, // Ini yang membuat header tetap muncul
                delegate: _TableHeaderDelegate(
                  minHeight: 60.0,
                  maxHeight: 60.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100], // Warna background header
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16, // Padding vertikal disesuaikan
                        ),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Tgl Panen',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Lokasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Status Delay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Sisa JJG',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'Sisa Kg',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'JJG Panen',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'JJG Kirim',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 80,
                              child: Text(
                                'BJR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 24),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Tgl Kirim',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. DATA TABEL (Scrollable)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    controller: _dataHorizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: restanData.map((restan) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // 1. Tanggal Panen
                              SizedBox(
                                width: 100,
                                child: Text(
                                  _formatDate(restan.tanggalPanen),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 2. Lokasi (Blok & TPH)
                              SizedBox(
                                width: 120,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Blok ${restan.blok}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'TPH ${restan.noTph}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 3. Status Delay
                              SizedBox(
                                width: 120,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDelayColor(
                                      restan.delayDays,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getDelayColor(
                                        restan.delayDays,
                                      ).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    '${restan.delayDays} Hari',
                                    style: TextStyle(
                                      color: _getDelayColor(
                                        restan.delayDays,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 4. Sisa JJG
                              SizedBox(
                                width: 80,
                                child: Text(
                                  restan.selisihJjg.toString(),
                                  style: TextStyle(
                                    color: restan.selisihJjg > 0
                                        ? Colors.red[700]
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 5. Sisa Kg (Kg Restan)
                              SizedBox(
                                width: 80,
                                child: Text(
                                  restan.selisihJjg > 0 
                                    ? (restan.selisihJjg * restan.bjr).toStringAsFixed(1)
                                    : '0.0',
                                  style: TextStyle(
                                    color: restan.selisihJjg > 0
                                        ? Colors.red[700]
                                        : Colors.black87,
                                    fontWeight: restan.selisihJjg > 0 
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 6. JJG Panen
                              SizedBox(
                                width: 80,
                                child: Text(
                                  restan.jjgPanen.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 7. JJG Kirim
                              SizedBox(
                                width: 80,
                                child: Text(
                                  restan.jjgPengiriman.toString(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 8. BJR
                              SizedBox(
                                width: 80,
                                child: Text(
                                  restan.bjr.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              const SizedBox(width: 24),

                              // 9. Tgl Kirim
                              SizedBox(
                                width: 100,
                                child: Text(
                                  _formatDate(restan.tanggalPengiriman),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              
              // Spasi bawah agar data paling bawah tidak tertutup nav bar (opsional)
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return '-';
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getDelayColor(int days) {
    if (days <= 1) return Colors.green;
    if (days <= 3) return Colors.orange;
    return Colors.red;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FilterDialog(
          onApplyFilters: (Map<String, dynamic> filters) {
            final dataProvider = Provider.of<DataProvider>(
              context,
              listen: false,
            );

            dataProvider.setRestanFilters(
              afdeling: filters['afdeling'],
              blok: filters['blok'],
              dateFrom: filters['startDate']?.toIso8601String().split('T')[0],
              dateTo: filters['endDate']?.toIso8601String().split('T')[0],
            );
          },
          onClearFilters: () {
            final dataProvider = Provider.of<DataProvider>(
              context,
              listen: false,
            );
            dataProvider.clearRestanFilters();
          },
          filterType: FilterType.restan,
          currentFilters: {
            'afdeling': Provider.of<DataProvider>(
              context,
              listen: false,
            ).restanSelectedAfdeling,
            'blok': Provider.of<DataProvider>(
              context,
              listen: false,
            ).restanSelectedBlok,
            'startDate': Provider.of<DataProvider>(
              context,
              listen: false,
            ).restanDateFrom,
            'endDate': Provider.of<DataProvider>(
              context,
              listen: false,
            ).restanDateTo,
          },
        );
      },
    );
  }
}

// === TAMBAHAN KELAS BARU DI BAWAH ===
class _TableHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _TableHeaderDelegate({
    required this.child,
    this.minHeight = 60.0,
    this.maxHeight = 60.0,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_TableHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}