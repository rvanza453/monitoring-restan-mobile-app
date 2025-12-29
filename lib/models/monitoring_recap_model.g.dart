// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitoring_recap_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonitoringRecap _$MonitoringRecapFromJson(Map<String, dynamic> json) =>
    MonitoringRecap(
      date: json['date'] as String,
      afdeling: json['afdeling'] as String,
      blok: json['blok'] as String,
      noTPH: json['noTPH'] as String,
      jjgPanen: (json['jjgPanen'] as num).toInt(),
      jjgAngkut: (json['jjgAngkut'] as num).toInt(),
      kgPanen: (json['kgPanen'] as num).toDouble(),
      kgAngkut: (json['kgAngkut'] as num).toDouble(),
      kgBrd: (json['kgBrd'] as num).toDouble(),
      bjr: (json['bjr'] as num).toDouble(),
      tanggalPanen: json['tanggalPanen'] as String,
      tanggalAngkut: json['tanggalAngkut'] as String,
      selisihJjg: (json['selisihJjg'] as num).toInt(),
      selisihKg: (json['selisihKg'] as num).toDouble(),
      delayHari: (json['delayHari'] as num).toInt(),
      kgRestan: (json['kgRestan'] as num).toDouble(),
      status: json['status'] as String,
      statusColor: json['statusColor'] as String,
      delayColor: json['delayColor'] as String,
    );

Map<String, dynamic> _$MonitoringRecapToJson(MonitoringRecap instance) =>
    <String, dynamic>{
      'date': instance.date,
      'afdeling': instance.afdeling,
      'blok': instance.blok,
      'noTPH': instance.noTPH,
      'jjgPanen': instance.jjgPanen,
      'jjgAngkut': instance.jjgAngkut,
      'kgPanen': instance.kgPanen,
      'kgAngkut': instance.kgAngkut,
      'kgBrd': instance.kgBrd,
      'bjr': instance.bjr,
      'tanggalPanen': instance.tanggalPanen,
      'tanggalAngkut': instance.tanggalAngkut,
      'selisihJjg': instance.selisihJjg,
      'selisihKg': instance.selisihKg,
      'delayHari': instance.delayHari,
      'kgRestan': instance.kgRestan,
      'status': instance.status,
      'statusColor': instance.statusColor,
      'delayColor': instance.delayColor,
    };

MonitoringSummary _$MonitoringSummaryFromJson(Map<String, dynamic> json) =>
    MonitoringSummary(
      totalRecords: (json['total_records'] as num).toInt(),
      totalPanenJjg: (json['total_panen_jjg'] as num).toInt(),
      totalAngkutJjg: (json['total_angkut_jjg'] as num).toInt(),
      totalRestanJjg: (json['total_restan_jjg'] as num).toInt(),
      totalKelebihanJjg: (json['total_kelebihan_jjg'] as num).toInt(),
      totalPanenKg: (json['total_panen_kg'] as num).toDouble(),
      totalAngkutKg: (json['total_angkut_kg'] as num).toDouble(),
      totalRestanKg: (json['total_restan_kg'] as num).toDouble(),
      totalSesuai: (json['total_sesuai'] as num).toInt(),
      totalRestan: (json['total_restan'] as num).toInt(),
      totalKelebihan: (json['total_kelebihan'] as num).toInt(),
      totalDelay: (json['total_delay'] as num).toInt(),
      statusBreakdown: Map<String, int>.from(json['status_breakdown'] as Map),
    );

Map<String, dynamic> _$MonitoringSummaryToJson(MonitoringSummary instance) =>
    <String, dynamic>{
      'total_records': instance.totalRecords,
      'total_panen_jjg': instance.totalPanenJjg,
      'total_angkut_jjg': instance.totalAngkutJjg,
      'total_restan_jjg': instance.totalRestanJjg,
      'total_kelebihan_jjg': instance.totalKelebihanJjg,
      'total_panen_kg': instance.totalPanenKg,
      'total_angkut_kg': instance.totalAngkutKg,
      'total_restan_kg': instance.totalRestanKg,
      'total_sesuai': instance.totalSesuai,
      'total_restan': instance.totalRestan,
      'total_kelebihan': instance.totalKelebihan,
      'total_delay': instance.totalDelay,
      'status_breakdown': instance.statusBreakdown,
    };

MonitoringStatistics _$MonitoringStatisticsFromJson(
  Map<String, dynamic> json,
) => MonitoringStatistics(
  totalPanen: (json['total_panen'] as num).toInt(),
  totalTransport: (json['total_transport'] as num).toInt(),
  panenStats: PanenStatistics.fromJson(
    json['panen_stats'] as Map<String, dynamic>,
  ),
  transportStats: TransportStatistics.fromJson(
    json['transport_stats'] as Map<String, dynamic>,
  ),
  locationStats: LocationStatistics.fromJson(
    json['location_stats'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$MonitoringStatisticsToJson(
  MonitoringStatistics instance,
) => <String, dynamic>{
  'total_panen': instance.totalPanen,
  'total_transport': instance.totalTransport,
  'panen_stats': instance.panenStats,
  'transport_stats': instance.transportStats,
  'location_stats': instance.locationStats,
};

PanenStatistics _$PanenStatisticsFromJson(Map<String, dynamic> json) =>
    PanenStatistics(
      totalJjg: (json['total_jjg'] as num).toInt(),
      totalKg: (json['total_kg'] as num).toDouble(),
      avgBjr: (json['avg_bjr'] as num).toDouble(),
      uniqueLocations: (json['unique_locations'] as num).toInt(),
    );

Map<String, dynamic> _$PanenStatisticsToJson(PanenStatistics instance) =>
    <String, dynamic>{
      'total_jjg': instance.totalJjg,
      'total_kg': instance.totalKg,
      'avg_bjr': instance.avgBjr,
      'unique_locations': instance.uniqueLocations,
    };

TransportStatistics _$TransportStatisticsFromJson(Map<String, dynamic> json) =>
    TransportStatistics(
      totalJjg: (json['total_jjg'] as num).toInt(),
      totalKg: (json['total_kg'] as num).toDouble(),
      avgBjr: (json['avg_bjr'] as num).toDouble(),
      uniqueLocations: (json['unique_locations'] as num).toInt(),
      uniqueVehicles: (json['unique_vehicles'] as num).toInt(),
    );

Map<String, dynamic> _$TransportStatisticsToJson(
  TransportStatistics instance,
) => <String, dynamic>{
  'total_jjg': instance.totalJjg,
  'total_kg': instance.totalKg,
  'avg_bjr': instance.avgBjr,
  'unique_locations': instance.uniqueLocations,
  'unique_vehicles': instance.uniqueVehicles,
};

LocationStatistics _$LocationStatisticsFromJson(Map<String, dynamic> json) =>
    LocationStatistics(
      totalLocations: (json['total_locations'] as num).toInt(),
      panenOnlyLocations: (json['panen_only_locations'] as num).toInt(),
      transportOnlyLocations: (json['transport_only_locations'] as num).toInt(),
      matchedLocations: (json['matched_locations'] as num).toInt(),
    );

Map<String, dynamic> _$LocationStatisticsToJson(LocationStatistics instance) =>
    <String, dynamic>{
      'total_locations': instance.totalLocations,
      'panen_only_locations': instance.panenOnlyLocations,
      'transport_only_locations': instance.transportOnlyLocations,
      'matched_locations': instance.matchedLocations,
    };

AfdelingSummary _$AfdelingSummaryFromJson(Map<String, dynamic> json) =>
    AfdelingSummary(
      afdeling: json['afdeling'] as String,
      totalLocations: (json['total_locations'] as num).toInt(),
      totalPanenJjg: (json['total_panen_jjg'] as num).toInt(),
      totalAngkutJjg: (json['total_angkut_jjg'] as num).toInt(),
      totalRestanJjg: (json['total_restan_jjg'] as num).toInt(),
      totalKelebihanJjg: (json['total_kelebihan_jjg'] as num).toInt(),
      totalRestanKg: (json['total_restan_kg'] as num).toDouble(),
      sesuaiCount: (json['sesuai_count'] as num).toInt(),
      restanCount: (json['restan_count'] as num).toInt(),
      kelebihanCount: (json['kelebihan_count'] as num).toInt(),
    );

Map<String, dynamic> _$AfdelingSummaryToJson(AfdelingSummary instance) =>
    <String, dynamic>{
      'afdeling': instance.afdeling,
      'total_locations': instance.totalLocations,
      'total_panen_jjg': instance.totalPanenJjg,
      'total_angkut_jjg': instance.totalAngkutJjg,
      'total_restan_jjg': instance.totalRestanJjg,
      'total_kelebihan_jjg': instance.totalKelebihanJjg,
      'total_restan_kg': instance.totalRestanKg,
      'sesuai_count': instance.sesuaiCount,
      'restan_count': instance.restanCount,
      'kelebihan_count': instance.kelebihanCount,
    };
