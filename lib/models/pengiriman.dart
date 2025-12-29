import 'package:json_annotation/json_annotation.dart';
import 'koordinat.dart';
import 'upload_info.dart';

part 'pengiriman.g.dart';

@JsonSerializable()
class Pengiriman {
  final int id;
  @JsonKey(name: 'upload_id')
  final int uploadId;
  @JsonKey(name: 'tipe_aplikasi')
  final String? tipeAplikasi;
  @JsonKey(name: 'nama_kerani')
  final String namaKerani;
  @JsonKey(name: 'nik_kerani')
  final String nikKerani;
  final String tanggal;
  final String afdeling;
  final String nopol;
  @JsonKey(name: 'nomor_kendaraan')
  final String nomorKendaraan;
  final String blok;
  @JsonKey(name: 'no_tph')
  final String noTph;
  @JsonKey(name: 'jumlah_janjang')
  final int jumlahJanjang;
  @JsonKey(name: 'koreksi_kirim')
  final int? koreksiKirim;
  final String waktu;
  final Koordinat? koordinat;
  @JsonKey(name: 'kg_total')
  final double kgTotal;
  final double? bjr;
  @JsonKey(name: 'kg_brd')
  final double? kgBrd;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'upload_info')
  final UploadInfo? uploadInfo;

  const Pengiriman({
    required this.id,
    required this.uploadId,
    this.tipeAplikasi,
    required this.namaKerani,
    required this.nikKerani,
    required this.tanggal,
    required this.afdeling,
    required this.nopol,
    required this.nomorKendaraan,
    required this.blok,
    required this.noTph,
    required this.jumlahJanjang,
    this.koreksiKirim,
    required this.waktu,
    this.koordinat,
    required this.kgTotal,
    this.bjr,
    this.kgBrd,
    required this.createdAt,
    this.uploadInfo,
  });

  factory Pengiriman.fromJson(Map<String, dynamic> json) => _$PengirimanFromJson(json);

  Map<String, dynamic> toJson() => _$PengirimanToJson(this);

  // Untuk database SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'upload_id': uploadId,
      'tipe_aplikasi': tipeAplikasi,
      'nama_kerani': namaKerani,
      'nik_kerani': nikKerani,
      'tanggal': tanggal,
      'afdeling': afdeling,
      'nopol': nopol,
      'nomor_kendaraan': nomorKendaraan,
      'blok': blok,
      'no_tph': noTph,
      'jumlah_janjang': jumlahJanjang,
      'waktu': waktu,
      'koordinat_lat': koordinat?.latitude,
      'koordinat_lng': koordinat?.longitude,
      'kg_total': kgTotal,
      'bjr': bjr,
      'kg_brd': kgBrd,
      'koreksi_kirim': koreksiKirim,  // Add koreksi field
      'created_at': createdAt,
    };
  }

  factory Pengiriman.fromMap(Map<String, dynamic> map) {
    return Pengiriman(
      id: map['id'],
      uploadId: map['upload_id'],
      tipeAplikasi: map['tipe_aplikasi'],
      namaKerani: map['nama_kerani'],
      nikKerani: map['nik_kerani'],
      tanggal: map['tanggal'],
      afdeling: map['afdeling'],
      nopol: map['nopol'],
      nomorKendaraan: map['nomor_kendaraan'],
      blok: map['blok'],
      noTph: map['no_tph'],
      jumlahJanjang: map['jumlah_janjang'],
      waktu: map['waktu'],
      koordinat: (map['koordinat_lat'] != null && map['koordinat_lng'] != null)
          ? Koordinat(latitude: map['koordinat_lat'], longitude: map['koordinat_lng'])
          : null,
      kgTotal: map['kg_total'] ?? map['kg'], // Support both field names for backward compatibility
      bjr: map['bjr']?.toDouble(),
      kgBrd: map['kg_brd']?.toDouble(),
      koreksiKirim: map['koreksi_kirim'],  // Add koreksi field
      createdAt: map['created_at'],
    );
  }

  String get vehicleInfo => '$nopol - $nomorKendaraan';

  /// Menghitung kg total berdasarkan rumus: (jumlahJanjang * bjr) + kgBrd
  double get calculatedKg {
    double bjrValue = bjr ?? 0.0;
    double kgBrdValue = kgBrd ?? 0.0;
    double calculated = (jumlahJanjang * bjrValue) + kgBrdValue;
    print('🧮 Calculated KG for ID $id: ($jumlahJanjang * $bjrValue) + $kgBrdValue = $calculated');
    return calculated;
  }

  @override
  String toString() {
    return 'Pengiriman{id: $id, namaKerani: $namaKerani, tanggal: $tanggal, afdeling: $afdeling}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pengiriman && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}