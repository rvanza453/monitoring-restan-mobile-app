class RestanModel {
  final String tanggalPanen;
  final String afdeling; // Field baru ditambahkan
  final String blok;
  final String noTph;
  final int jjgPanen;
  final int jjgPengiriman;
  final double bjr; // BJR dari panen
  final double kgPanen;
  final double kgPengiriman;
  final int delayDays;
  final String tanggalPengiriman;

  RestanModel({
    required this.tanggalPanen,
    required this.afdeling, // Constructor diperbarui
    required this.blok,
    required this.noTph,
    required this.jjgPanen,
    required this.jjgPengiriman,
    required this.bjr,
    required this.kgPanen,
    required this.kgPengiriman,
    required this.delayDays,
    required this.tanggalPengiriman,
  });

  // Getter untuk selisih
  int get selisihJjg => jjgPanen - jjgPengiriman;
  double get selisihKg => kgPanen - kgPengiriman;

  factory RestanModel.fromData({
    required dynamic panenData,
    required dynamic pengirimanData,
  }) {
    // Kalkulasi delay berdasarkan tanggal panen dan tanggal pengiriman
    DateTime tanggalPanenDate = DateTime.parse(
      panenData['tanggal_pemeriksaan'] ?? '',
    );

    // Handle kasus tidak ada pengiriman yang cocok
    String tanggalPengirimanStr =
        pengirimanData['tanggal'] ?? panenData['tanggal_pemeriksaan'];
    DateTime tanggalPengirimanDate = DateTime.parse(tanggalPengirimanStr);

    // Jika pengiriman sama dengan panen (tidak ada pengiriman yang cocok), set delay tinggi
    int delayDays = 0;
    if (tanggalPengirimanStr == panenData['tanggal_pemeriksaan']) {
      // Hitung delay dari hari ini untuk menunjukkan berapa lama sudah tertunda
      delayDays = DateTime.now().difference(tanggalPanenDate).inDays;
    } else {
      delayDays = tanggalPengirimanDate.difference(tanggalPanenDate).inDays;
    }

    // Ambil data dari panen dan pengiriman
    int jjgPanen = int.tryParse(panenData['jjg']?.toString() ?? '0') ?? 0;
    int jjgPengiriman =
        int.tryParse(pengirimanData['jjg_pengiriman']?.toString() ?? '0') ?? 0;

    // Gunakan BJR dari panen, jika tidak ada gunakan dari pengiriman
    double bjr = double.tryParse(panenData['bjr']?.toString() ?? '0.0') ?? 0.0;
    if (bjr <= 0) {
      bjr = double.tryParse(pengirimanData['bjr']?.toString() ?? '0.0') ?? 0.0;
    }

    // Hitung kg dari panen berdasarkan BJR dan jjg panen
    double kgBrdPanen =
        double.tryParse(panenData['kg_brd']?.toString() ?? '0.0') ?? 0.0;
    double kgPanen = panenData['kg_total'] != null
        ? double.tryParse(panenData['kg_total'].toString()) ?? 0.0
        : (jjgPanen * bjr) + kgBrdPanen;

    // Ambil kg dari pengiriman
    double kgPengiriman =
        double.tryParse(
          pengirimanData['kg_total']?.toString() ??
              pengirimanData['kg']?.toString() ??
              '0.0',
        ) ??
        0.0;


    return RestanModel(
      tanggalPanen: panenData['tanggal_pemeriksaan'] ?? '',
      afdeling: panenData['afdeling'] ?? '', // Mengambil data afdeling
      blok: panenData['blok'] ?? '',
      noTph: panenData['no_tph'] ?? '',
      jjgPanen: jjgPanen,
      jjgPengiriman: jjgPengiriman,
      bjr: bjr,
      kgPanen: kgPanen,
      kgPengiriman: kgPengiriman,
      delayDays: delayDays,
      tanggalPengiriman: tanggalPengirimanStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal_panen': tanggalPanen,
      'afdeling': afdeling, // Ditambahkan ke JSON
      'blok': blok,
      'no_tph': noTph,
      'jjg_panen': jjgPanen,
      'jjg_pengiriman': jjgPengiriman,
      'bjr': bjr,
      'kg_panen': kgPanen,
      'kg_pengiriman': kgPengiriman,
      'selisih_jjg': selisihJjg,
      'selisih_kg': selisihKg,
      'delay_days': delayDays,
      'tanggal_pengiriman': tanggalPengiriman,
    };
  }

  factory RestanModel.fromJson(Map<String, dynamic> json) {
    return RestanModel(
      tanggalPanen: json['tanggal_panen'] ?? '',
      afdeling: json['afdeling'] ?? '', // Ditambahkan dari JSON
      blok: json['blok'] ?? '',
      noTph: json['no_tph'] ?? '',
      jjgPanen: json['jjg_panen'] ?? 0,
      jjgPengiriman: json['jjg_pengiriman'] ?? 0,
      bjr: (json['bjr'] ?? 0.0).toDouble(),
      kgPanen: (json['kg_panen'] ?? 0.0).toDouble(),
      kgPengiriman: (json['kg_pengiriman'] ?? 0.0).toDouble(),
      delayDays: json['delay_days'] ?? 0,
      tanggalPengiriman: json['tanggal_pengiriman'] ?? '',
    );
  }

  @override
  String toString() {
    return 'RestanModel(tanggalPanen: $tanggalPanen, afdeling: $afdeling, blok: $blok, noTph: $noTph, jjgPanen: $jjgPanen, jjgPengiriman: $jjgPengiriman, selisihJjg: $selisihJjg, selisihKg: $selisihKg, bjr: $bjr, delayDays: $delayDays)';
  }
}
