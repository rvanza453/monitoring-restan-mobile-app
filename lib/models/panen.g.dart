// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'panen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Panen _$PanenFromJson(Map<String, dynamic> json) => Panen(
  id: (json['id'] as num).toInt(),
  uploadId: (json['upload_id'] as num).toInt(),
  namaKerani: json['nama_kerani'] as String,
  tanggalPemeriksaan: json['tanggal_pemeriksaan'] as String,
  afdeling: json['afdeling'] as String,
  namaPemanen: json['nama_pemanen'] as String,
  nikPemanen: json['nik_pemanen'] as String,
  blok: json['blok'] as String,
  noAncak: json['no_ancak'] as String,
  noTph: json['no_tph'] as String,
  jam: json['jam'] as String,
  lastModified: json['last_modified'] as String,
  koordinat: json['koordinat'] == null
      ? null
      : Koordinat.fromJson(json['koordinat'] as Map<String, dynamic>),
  jumlahJanjang: (json['jumlah_janjang'] as num).toInt(),
  koreksiPanen: (json['koreksi_panen'] as num?)?.toInt(),
  bjr: (json['bjr'] as num?)?.toDouble(),
  kgTotal: (json['kg_total'] as num?)?.toDouble(),
  kgBrd: (json['kg_brd'] as num?)?.toDouble(),
  createdAt: json['created_at'] as String,
  uploadInfo: json['upload_info'] == null
      ? null
      : UploadInfo.fromJson(json['upload_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PanenToJson(Panen instance) => <String, dynamic>{
  'id': instance.id,
  'upload_id': instance.uploadId,
  'nama_kerani': instance.namaKerani,
  'tanggal_pemeriksaan': instance.tanggalPemeriksaan,
  'afdeling': instance.afdeling,
  'nama_pemanen': instance.namaPemanen,
  'nik_pemanen': instance.nikPemanen,
  'blok': instance.blok,
  'no_ancak': instance.noAncak,
  'no_tph': instance.noTph,
  'jam': instance.jam,
  'last_modified': instance.lastModified,
  'koordinat': instance.koordinat,
  'jumlah_janjang': instance.jumlahJanjang,
  'koreksi_panen': instance.koreksiPanen,
  'bjr': instance.bjr,
  'kg_total': instance.kgTotal,
  'kg_brd': instance.kgBrd,
  'created_at': instance.createdAt,
  'upload_info': instance.uploadInfo,
};
