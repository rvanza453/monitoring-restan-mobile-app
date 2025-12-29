import 'package:json_annotation/json_annotation.dart';
import 'koordinat.dart';
import 'upload_info.dart';

part 'panen.g.dart';

@JsonSerializable()
class Panen {
  final int id;
  @JsonKey(name: 'upload_id')
  final int uploadId;
  @JsonKey(name: 'nama_kerani')
  final String namaKerani;
  @JsonKey(name: 'tanggal_pemeriksaan')
  final String tanggalPemeriksaan;
  final String afdeling;
  @JsonKey(name: 'nama_pemanen')
  final String namaPemanen;
  @JsonKey(name: 'nik_pemanen')
  final String nikPemanen;
  final String blok;
  @JsonKey(name: 'no_ancak')
  final String noAncak;
  @JsonKey(name: 'no_tph')
  final String noTph;
  final String jam;
  @JsonKey(name: 'last_modified')
  final String lastModified;
  final Koordinat? koordinat;
  @JsonKey(name: 'jumlah_janjang')
  final int jumlahJanjang;
  @JsonKey(name: 'koreksi_panen')
  final int? koreksiPanen;
  final double? bjr;
  @JsonKey(name: 'kg_total')
  final double? kgTotal;
  @JsonKey(name: 'kg_brd')
  final double? kgBrd;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'upload_info')
  final UploadInfo? uploadInfo;

  const Panen({
    required this.id,
    required this.uploadId,
    required this.namaKerani,
    required this.tanggalPemeriksaan,
    required this.afdeling,
    required this.namaPemanen,
    required this.nikPemanen,
    required this.blok,
    required this.noAncak,
    required this.noTph,
    required this.jam,
    required this.lastModified,
    this.koordinat,
    required this.jumlahJanjang,
    this.koreksiPanen,
    this.bjr,
    this.kgTotal,
    this.kgBrd,
    required this.createdAt,
    this.uploadInfo,
  });

  factory Panen.fromJson(Map<String, dynamic> json) => _$PanenFromJson(json);

  Map<String, dynamic> toJson() => _$PanenToJson(this);

  // Untuk database SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'upload_id': uploadId,
      'nama_kerani': namaKerani,
      'tanggal_pemeriksaan': tanggalPemeriksaan,
      'afdeling': afdeling,
      'nama_pemanen': namaPemanen,
      'nik_pemanen': nikPemanen,
      'blok': blok,
      'no_ancak': noAncak,
      'no_tph': noTph,
      'jam': jam,
      'last_modified': lastModified,
      'koordinat_lat': koordinat?.latitude,
      'koordinat_lng': koordinat?.longitude,
      'jumlah_janjang': jumlahJanjang,
      'bjr': bjr,
      'kg_total': kgTotal,
      'kg_brd': kgBrd,
      'koreksi_panen': koreksiPanen,  // Add koreksi field
      'created_at': createdAt,
    };
  }

  factory Panen.fromMap(Map<String, dynamic> map) {
    return Panen(
      id: map['id'],
      uploadId: map['upload_id'],
      namaKerani: map['nama_kerani'],
      tanggalPemeriksaan: map['tanggal_pemeriksaan'],
      afdeling: map['afdeling'],
      namaPemanen: map['nama_pemanen'],
      nikPemanen: map['nik_pemanen'],
      blok: map['blok'],
      noAncak: map['no_ancak'],
      noTph: map['no_tph'],
      jam: map['jam'],
      lastModified: map['last_modified'],
      koordinat: (map['koordinat_lat'] != null && map['koordinat_lng'] != null)
          ? Koordinat(latitude: map['koordinat_lat'], longitude: map['koordinat_lng'])
          : null,
      jumlahJanjang: map['jumlah_janjang'],
      bjr: map['bjr']?.toDouble(),
      kgTotal: map['kg_total']?.toDouble(),
      kgBrd: map['kg_brd']?.toDouble(),
      koreksiPanen: map['koreksi_panen'],  // Add koreksi field
      createdAt: map['created_at'],
    );
  }

  @override
  String toString() {
    return 'Panen{id: $id, namaKerani: $namaKerani, tanggal: $tanggalPemeriksaan, afdeling: $afdeling}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Panen && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}