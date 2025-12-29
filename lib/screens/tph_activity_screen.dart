import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/panen.dart';
import '../models/pengiriman.dart';
import '../providers/data_provider.dart';

class TphActivityScreen extends StatelessWidget {
  final String afdeling;
  final String blok;
  final String noTph;

  const TphActivityScreen({
    Key? key,
    required this.afdeling,
    required this.blok,
    required this.noTph,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final activities = dataProvider.getActivitiesForTph(afdeling, blok, noTph);
    final List<Panen> panenRecords = activities['panen'] as List<Panen>;
    final List<Pengiriman> pengirimanRecords = activities['pengiriman'] as List<Pengiriman>;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aktivitas TPH', style: TextStyle(fontSize: 18)),
            Text(
              'Afd $afdeling / Blok $blok / TPH $noTph',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Panen'),
                Tab(text: 'Pengiriman'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPanenList(panenRecords),
                  _buildPengirimanList(pengirimanRecords),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanenList(List<Panen> records) {
    if (records.isEmpty) {
      return const Center(child: Text('Tidak ada data panen di lokasi ini.'));
    }
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final correctedJjg = record.jumlahJanjang + (record.koreksiPanen ?? 0);
        return ListTile(
          title: Text(
              '${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(record.tanggalPemeriksaan))}'),
          subtitle: Text('Pemanen: ${record.namaPemanen}'),
          trailing: Text(
            '$correctedJjg Jjg',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }

  Widget _buildPengirimanList(List<Pengiriman> records) {
    if (records.isEmpty) {
      return const Center(
          child: Text('Tidak ada data pengiriman di lokasi ini.'));
    }
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final correctedJjg = record.jumlahJanjang + (record.koreksiKirim ?? 0);
        return ListTile(
          title: Text(
              '${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(record.tanggal))} - ${record.nomorKendaraan}'),
          subtitle: Text('Kerani: ${record.namaKerani}'),
          trailing: Text(
            '$correctedJjg Jjg',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }
}
