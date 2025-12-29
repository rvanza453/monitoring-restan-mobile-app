import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/data_provider.dart';
import '../widgets/quick_stats_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

  Map<String, dynamic> _calculateDashboardSummary(DataProvider dataProvider) {
    final restanData = dataProvider.restanLocationSummary;

    int totalPanenJjg = 0;
    int totalKirimJjg = 0;
    int totalRestanJjg = 0;
    double totalRestanKg = 0;
    int totalLocations = restanData.length;

    int sesuaiCount = 0;
    int restanCount = 0;
    int kelebihanCount = 0;

    // Hitung dari data restan location
    for (var item in restanData) {
      totalPanenJjg += item.totalPanenJjg;
      totalKirimJjg += item.totalKirimJjg;

      if (item.selisihJjg > 0) {
        totalRestanJjg += item.selisihJjg;
        totalRestanKg += item.estRestanKg;
        restanCount++;
      } else if (item.selisihJjg < 0) {
        kelebihanCount++;
      } else {
        sesuaiCount++;
      }
    }

    // Hitung dari data panen dan pengiriman langsung
    int totalPanenActivities = dataProvider.panenData.length;
    int totalPengirimanActivities = dataProvider.pengirimanData.length;
    int totalActivities = totalPanenActivities + totalPengirimanActivities;

    double restanPercentage = totalPanenJjg > 0 ? (totalRestanJjg / totalPanenJjg) * 100 : 0;

    return {
      'totalActivities': totalActivities,
      'totalPanenActivities': totalPanenActivities,
      'totalPengirimanActivities': totalPengirimanActivities,
      'totalPanenJjg': totalPanenJjg,
      'totalKirimJjg': totalKirimJjg,
      'totalRestanJjg': totalRestanJjg,
      'totalRestanKg': totalRestanKg,
      'totalLocations': totalLocations,
      'sesuaiCount': sesuaiCount,
      'restanCount': restanCount,
      'kelebihanCount': kelebihanCount,
      'restanPercentage': restanPercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: dataProvider.isSyncing ? null : _onRefresh,
                  icon: dataProvider.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Icon(Icons.refresh, color: Colors.grey[800], size: 20),
                  tooltip: 'Refresh Data',
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isSyncing && dataProvider.restanLocationSummary.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary = _calculateDashboardSummary(dataProvider);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Welcome
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.dashboard, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'Ringkasan Monitoring',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pantau aktivitas panen dan pengiriman dengan cepat',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Terakhir diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats Cards
                  const Text(
                    'Statistik Cepat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row 1: Activities & Locations
                  Row(
                    children: [
                      Expanded(
                        child: QuickStatsWidget(
                          title: 'Total Aktivitas',
                          value: '${summary['totalActivities']}',
                          icon: Icons.assignment,
                          color: Colors.blue,
                          subtitle: 'Panen + Pengiriman',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickStatsWidget(
                          title: 'Total Lokasi',
                          value: '${summary['totalLocations']}',
                          icon: Icons.location_on,
                          color: Colors.green,
                          subtitle: 'TPH yang dipantau',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 2: Panen & Pengiriman
                  Row(
                    children: [
                      Expanded(
                        child: QuickStatsWidget(
                          title: 'Aktivitas Panen',
                          value: '${summary['totalPanenActivities']}',
                          icon: Icons.agriculture,
                          color: Colors.orange,
                          subtitle: 'Total kegiatan panen',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickStatsWidget(
                          title: 'Aktivitas Kirim',
                          value: '${summary['totalPengirimanActivities']}',
                          icon: Icons.local_shipping,
                          color: Colors.purple,
                          subtitle: 'Total kegiatan kirim',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Production Summary
                  const Text(
                    'Ringkasan Produksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green[400]!, Colors.green[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.agriculture,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Panen',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${summary['totalPanenJjg']} Janjang',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Pengiriman',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${summary['totalKirimJjg']} Janjang',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Restan Alert Section
                  const Text(
                    'Status Restan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: summary['totalRestanJjg'] > 0
                            ? [Colors.red[50]!, Colors.red[100]!]
                            : [Colors.green[50]!, Colors.green[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: summary['totalRestanJjg'] > 0
                            ? Colors.red[200]!
                            : Colors.green[200]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (summary['totalRestanJjg'] > 0 ? Colors.red : Colors.green).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: summary['totalRestanJjg'] > 0
                                      ? [Colors.red[400]!, Colors.red[600]!]
                                      : [Colors.green[400]!, Colors.green[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                summary['totalRestanJjg'] > 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    summary['totalRestanJjg'] > 0 ? 'Ada Restan' : 'Tidak Ada Restan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: summary['totalRestanJjg'] > 0
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    summary['totalRestanJjg'] > 0
                                        ? '${summary['totalRestanJjg']} Janjang Restan (${summary['totalRestanKg'].toStringAsFixed(0)} Kg)'
                                        : 'Semua produksi sudah dikirim',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: summary['totalRestanJjg'] > 0
                                          ? Colors.red[600]
                                          : Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (summary['totalRestanJjg'] > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.red[700], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Persentase restan: ${summary['restanPercentage'].toStringAsFixed(1)}% dari total panen',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location Status Summary
                  const Text(
                    'Status Lokasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: StatusCardWidget(
                          title: 'Sesuai',
                          count: '${summary['sesuaiCount']}',
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatusCardWidget(
                          title: 'Restan',
                          count: '${summary['restanCount']}',
                          color: Colors.red,
                          icon: Icons.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatusCardWidget(
                          title: 'Kelebihan',
                          count: '${summary['kelebihanCount']}',
                          color: Colors.blue,
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}