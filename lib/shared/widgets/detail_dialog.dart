import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/monitoring_recap_model.dart';

enum DetailType { panen, pengiriman, restan }

class DetailDialog extends StatelessWidget {
  final DetailType type;
  final dynamic data;
  final dynamic panenData; // Bisa berupa object Panen atau null
  final dynamic pengirimanData; // Bisa berupa object Pengiriman atau null

  const DetailDialog({
    Key? key,
    required this.type,
    required this.data,
    this.panenData,
    this.pengirimanData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Jika tipe Restan, gunakan layout dengan TabController
    if (type == DetailType.restan) {
      return DefaultTabController(
        length: 3,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildTabBar(), // Tab Bar khusus Restan
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRestanTab(),      // Tab 1: Analisa & Summary
                      _buildPanenTab(),       // Tab 2: Detail Panen Asli
                      _buildPengirimanTab(),  // Tab 3: Detail Pengiriman Asli
                    ],
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      );
    }

    // Layout Standar (Panen / Pengiriman biasa)
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContent(),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER & NAVIGATION
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    String title;
    Color color;
    IconData icon;

    switch (type) {
      case DetailType.panen:
        title = 'Detail Panen';
        color = Colors.green;
        icon = Icons.agriculture;
        break;
      case DetailType.pengiriman:
        title = 'Detail Pengiriman';
        color = Colors.blue;
        icon = Icons.local_shipping;
        break;
      case DetailType.restan:
        title = 'Monitoring Restan';
        color = Colors.orange;
        icon = Icons.analytics_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[50],
      child: TabBar(
        labelColor: Colors.orange[800],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.orange,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'ANALISA'),
          Tab(text: 'DATA PANEN'),
          Tab(text: 'DATA ANGKUT'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT SWITCHER
  // ---------------------------------------------------------------------------

  Widget _buildContent() {
    switch (type) {
      case DetailType.panen:
        return _buildPanenContent(data); // Render detail panen standard
      case DetailType.pengiriman:
        return _buildPengirimanContent(data); // Render detail pengiriman standard
      default:
        return const SizedBox();
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 1: RESTAN ANALISA (Overview)
  // ---------------------------------------------------------------------------

  Widget _buildRestanTab() {
    final restan = data as MonitoringRecap;
    
    // Tentukan warna status
    Color statusColor;
    if (restan.status.toLowerCase().contains('sesuai')) statusColor = Colors.green;
    else if (restan.status.toLowerCase().contains('restan')) statusColor = Colors.red;
    else statusColor = Colors.blue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Card Utama
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  restan.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 1.2
                  ),
                ),
                const SizedBox(height: 4),
                if (restan.delayHari > 0)
                  Text(
                    'Delay ${restan.delayHari} Hari',
                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
                  )
                else
                  Text(
                    'Tuntas di hari yang sama',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // 2. Comparison Grid (Panen vs Angkut)
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  'PANEN', 
                  '${restan.jjgPanen}', 
                  '${restan.kgPanen.toStringAsFixed(0)} Kg', 
                  Colors.green
                )
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  'ANGKUT', 
                  '${restan.jjgAngkut}', 
                  '${restan.kgAngkut.toStringAsFixed(0)} Kg', 
                  Colors.blue
                )
              ),
            ],
          ),

          const SizedBox(height: 16),
          
          // 3. Selisih Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELISIH / SISA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '${restan.selisihJjg} Janjang',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: restan.selisihJjg > 0 ? Colors.red : (restan.selisihJjg < 0 ? Colors.blue : Colors.green)
                      ),
                    ),
                  ],
                ),
                Text(
                  '${restan.kgRestan.toStringAsFixed(1)} Kg',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // 4. Informasi Lokasi
          _SectionTitle(title: 'LOKASI & WAKTU', icon: Icons.map),
          _DetailRow(label: 'Afdeling', value: restan.afdeling),
          _DetailRow(label: 'Blok', value: restan.blok),
          _DetailRow(label: 'TPH', value: restan.noTPH),
          _DetailRow(label: 'Tanggal Catat', value: _formatDate(restan.date)),
          
          // 5. Debug Information for FIFO Matching Verification
          const SizedBox(height: 24),
          _SectionTitle(title: 'SINKRONISASI DATA', icon: Icons.sync),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restan.tanggalPanen.isNotEmpty)
                  _DetailRow(label: 'Tanggal Panen', value: _formatDate(restan.tanggalPanen)),
                if (restan.tanggalAngkut.isNotEmpty && restan.tanggalAngkut != '-')
                  _DetailRow(label: 'Tanggal Angkut', value: _formatDate(restan.tanggalAngkut))
                else if (restan.jjgAngkut == 0)
                  _DetailRow(label: 'Status Angkut', value: 'Belum ada pengiriman'),
                
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: panenData != null ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        panenData != null ? '✓ Detail Panen' : '✗ No Panen Data',
                        style: TextStyle(
                          fontSize: 11,
                          color: panenData != null ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pengirimanData != null ? Colors.blue[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pengirimanData != null ? '✓ Detail Angkut' : (restan.jjgAngkut > 0 ? '⚠ No Angkut Data' : '○ No Transport'),
                        style: TextStyle(
                          fontSize: 11,
                          color: pengirimanData != null ? Colors.blue[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: DETAIL PANEN (Reusable Content)
  // ---------------------------------------------------------------------------

  Widget _buildPanenTab() {
    final restan = data as MonitoringRecap;
    
    if (panenData == null) {
      String message;
      if (restan.jjgPanen == 0) {
        message = 'Data ini adalah "Angkut Tanpa Panen" - tidak ada data panen untuk lokasi ini.';
      } else {
        message = 'Data detail panen tidak ditemukan. Kemungkinan data telah teragregasi atau tidak tersinkronisasi.';
      }
      return _buildEmptyStateTab(message);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildPanenContent(panenData), // Reuse logic
    );
  }

  // Logic render detail panen (dipakai di Tab Restan & Dialog Panen biasa)
  Widget _buildPanenContent(dynamic panen) {
    // HITUNG LOGIKA KOREKSI
    int originalJjg = panen.jumlahJanjang;
    int koreksi = panen.koreksiPanen ?? 0;
    int totalJjg = originalJjg + koreksi;
    bool hasKoreksi = koreksi != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'IDENTITAS PEMANEN', icon: Icons.person),
        _DetailRow(label: 'Nama Pemanen', value: panen.namaPemanen, isBold: true),
        _DetailRow(label: 'NIK', value: panen.nikPemanen ?? '-'),
        _DetailRow(label: 'Kerani Pencatat', value: panen.namaKerani),
        
        const SizedBox(height: 24),
        
        _SectionTitle(title: 'LOKASI PANEN', icon: Icons.location_on),
        _DetailRow(label: 'Afdeling', value: panen.afdeling),
        _DetailRow(label: 'Blok', value: panen.blok),
        _DetailRow(label: 'TPH', value: panen.noTph, isBold: true),
        _DetailRow(label: 'Ancak', value: panen.noAncak ?? '-'),
        if (panen.koordinat != null)
        _DetailRow(label: 'Koordinat', value: '${panen.koordinat?.latitude}, ${panen.koordinat?.longitude}'),

        const SizedBox(height: 24),

        _SectionTitle(title: 'HASIL PANEN', icon: Icons.scale),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (hasKoreksi) ...[
                // TAMPILAN JIKA ADA KOREKSI
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total (Termasuk Koreksi)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('$totalJjg Janjang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                _DetailRow(label: 'Input Original', value: '$originalJjg'),
                _DetailRow(label: 'Nilai Koreksi', value: (koreksi > 0 ? '+$koreksi' : '$koreksi'), isBold: true),
                const Divider(),
              ] else ...[
                // TAMPILAN BIASA
                _DetailRow(label: 'Jumlah Janjang', value: '$originalJjg', isBold: true),
                const Divider(),
              ],
              
              _DetailRow(label: 'BJR', value: panen.bjr?.toStringAsFixed(2) ?? '-'),
              _DetailRow(label: 'Kg Total', value: '${panen.kgTotal?.toStringAsFixed(1) ?? '-'} Kg'),
              _DetailRow(label: 'Kg Brd', value: '${panen.kgBrd?.toStringAsFixed(1) ?? '-'} Kg'),
            ],
          ),
        ),

        const SizedBox(height: 24),
        
        _SectionTitle(title: 'METADATA', icon: Icons.info_outline),
        _DetailRow(label: 'Waktu Input', value: panen.jam ?? '-'),
        _DetailRow(label: 'Tanggal', value: _formatDate(panen.tanggalPemeriksaan)),
        if (panen.uploadInfo != null) ...[
           _DetailRow(label: 'Upload By', value: panen.uploadInfo?.uploadBy ?? '-'),
           _DetailRow(label: 'Status Sync', value: panen.uploadInfo?.syncStatus ?? '-'),
        ]
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: DETAIL PENGIRIMAN (Reusable Content)
  // ---------------------------------------------------------------------------

  Widget _buildPengirimanTab() {
    final restan = data as MonitoringRecap;
    
    if (pengirimanData == null) {
      String message;
      if (restan.jjgAngkut == 0) {
        message = 'Buah ini belum diangkut - masih dalam status "Restan".';
      } else {
        message = 'Data detail pengiriman tidak ditemukan meskipun tercatat ada ${restan.jjgAngkut} janjang yang diangkut. Data mungkin teragregasi atau tidak tersinkronisasi.';
      }
      return _buildEmptyStateTab(message);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildPengirimanContent(pengirimanData), // Reuse logic
    );
  }

  // Logic render detail pengiriman
  Widget _buildPengirimanContent(dynamic pengiriman) {
    // HITUNG LOGIKA KOREKSI
    int originalJjg = pengiriman.jumlahJanjang;
    int koreksi = pengiriman.koreksiKirim ?? 0;
    int totalJjg = originalJjg + koreksi;
    bool hasKoreksi = koreksi != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'TRANSPORT & DRIVER', icon: Icons.local_shipping),
        _DetailRow(label: 'Nomor Polisi', value: pengiriman.nopol ?? '-', isBold: true),
        _DetailRow(label: 'No. Internal', value: pengiriman.nomorKendaraan),
        
        const SizedBox(height: 24),

        _SectionTitle(title: 'PETUGAS / KERANI', icon: Icons.badge),
        _DetailRow(label: 'Nama Kerani', value: pengiriman.namaKerani),
        _DetailRow(label: 'NIK', value: pengiriman.nikKerani ?? '-'),
        _DetailRow(label: 'Tipe Aplikasi', value: pengiriman.tipeAplikasi ?? '-'),

        const SizedBox(height: 24),
        
        _SectionTitle(title: 'MUATAN ANGKUT', icon: Icons.scale),
         Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (hasKoreksi) ...[
                // TAMPILAN JIKA ADA KOREKSI
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total (Termasuk Koreksi)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text('$totalJjg Janjang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                _DetailRow(label: 'Muatan Original', value: '$originalJjg'),
                _DetailRow(label: 'Nilai Koreksi', value: (koreksi > 0 ? '+$koreksi' : '$koreksi'), isBold: true),
                const Divider(),
              ] else ...[
                // TAMPILAN BIASA
                _DetailRow(label: 'Janjang Angkut', value: '$originalJjg', isBold: true),
                const Divider(),
              ],
              
              _DetailRow(label: 'Kg Total', value: '${pengiriman.kgTotal?.toStringAsFixed(1) ?? '-'} Kg'),
              _DetailRow(label: 'BJR', value: pengiriman.bjr?.toStringAsFixed(2) ?? '-'),
            ],
          ),
        ),

        const SizedBox(height: 24),
        
        _SectionTitle(title: 'LOKASI & WAKTU', icon: Icons.map),
        _DetailRow(label: 'Lokasi', value: 'Afd ${pengiriman.afdeling} / Blok ${pengiriman.blok} / TPH ${pengiriman.noTph}'),
        _DetailRow(label: 'Tanggal', value: _formatDate(pengiriman.tanggal)),
        _DetailRow(label: 'Jam', value: pengiriman.waktu ?? '-'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildStatBox(String label, String mainValue, String subValue, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(mainValue, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(subValue, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyStateTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        color: Colors.white,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Tutup', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  // Static Methods for Easy Call
  static void showPanenDetail(BuildContext context, dynamic panen) {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        type: DetailType.panen,
        data: panen,
      ),
    );
  }

  static void showPengirimanDetail(BuildContext context, dynamic pengiriman) {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        type: DetailType.pengiriman,
        data: pengiriman,
      ),
    );
  }

  static void showRestanDetail(BuildContext context, MonitoringRecap restan, 
      {dynamic panenData, dynamic pengirimanData}) {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        type: DetailType.restan,
        data: restan,
        panenData: panenData,
        pengirimanData: pengirimanData,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRIVATE REUSABLE WIDGETS
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({Key? key, required this.title, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({Key? key, required this.label, required this.value, this.isBold = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}