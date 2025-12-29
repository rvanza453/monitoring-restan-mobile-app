// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pengiriman.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pengiriman _$PengirimanFromJson(Map<String, dynamic> json) => Pengiriman(
  id: (json['id'] as num).toInt(),
  uploadId: (json['upload_id'] as num).toInt(),
  tipeAplikasi: json['tipe_aplikasi'] as String?,
  namaKerani: json['nama_kerani'] as String,
  nikKerani: json['nik_kerani'] as String,
  tanggal: json['tanggal'] as String,
  afdeling: json['afdeling'] as String,
  nopol: json['nopol'] as String,
  nomorKendaraan: json['nomor_kendaraan'] as String,
  blok: json['blok'] as String,
  noTph: json['no_tph'] as String,
  jumlahJanjang: (json['jumlah_janjang'] as num).toInt(),
  koreksiKirim: (json['koreksi_kirim'] as num?)?.toInt(),
  waktu: json['waktu'] as String,
  koordinat: json['koordinat'] == null
      ? null
      : Koordinat.fromJson(json['koordinat'] as Map<String, dynamic>),
  kgTotal: (json['kg_total'] as num).toDouble(),
  bjr: (json['bjr'] as num?)?.toDouble(),
  kgBrd: (json['kg_brd'] as num?)?.toDouble(),
  createdAt: json['created_at'] as String,
  uploadInfo: json['upload_info'] == null
      ? null
      : UploadInfo.fromJson(json['upload_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PengirimanToJson(Pengiriman instance) =>
    <String, dynamic>{
      'id': instance.id,
      'upload_id': instance.uploadId,
      'tipe_aplikasi': instance.tipeAplikasi,
      'nama_kerani': instance.namaKerani,
      'nik_kerani': instance.nikKerani,
      'tanggal': instance.tanggal,
      'afdeling': instance.afdeling,
      'nopol': instance.nopol,
      'nomor_kendaraan': instance.nomorKendaraan,
      'blok': instance.blok,
      'no_tph': instance.noTph,
      'jumlah_janjang': instance.jumlahJanjang,
      'koreksi_kirim': instance.koreksiKirim,
      'waktu': instance.waktu,
      'koordinat': instance.koordinat,
      'kg_total': instance.kgTotal,
      'bjr': instance.bjr,
      'kg_brd': instance.kgBrd,
      'created_at': instance.createdAt,
      'upload_info': instance.uploadInfo,
    };
