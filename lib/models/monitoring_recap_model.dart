import 'package:json_annotation/json_annotation.dart';

part 'monitoring_recap_model.g.dart';

@JsonSerializable()
class MonitoringRecap {
  final String date;
  final String afdeling;
  final String blok;
  final String noTPH;
  final int jjgPanen;
  final int jjgAngkut;
  final double kgPanen;
  final double kgAngkut;
  final double kgBrd;
  final double bjr;
  final String tanggalPanen;
  final String tanggalAngkut;
  final int selisihJjg;
  final double selisihKg;
  final int delayHari;
  final double kgRestan;
  final String status;
  final String statusColor;
  final String delayColor;

  MonitoringRecap({
    required this.date,
    required this.afdeling,
    required this.blok,
    required this.noTPH,
    required this.jjgPanen,
    required this.jjgAngkut,
    required this.kgPanen,
    required this.kgAngkut,
    required this.kgBrd,
    required this.bjr,
    required this.tanggalPanen,
    required this.tanggalAngkut,
    required this.selisihJjg,
    required this.selisihKg,
    required this.delayHari,
    required this.kgRestan,
    required this.status,
    required this.statusColor,
    required this.delayColor,
  });

  factory MonitoringRecap.fromJson(Map<String, dynamic> json) => _$MonitoringRecapFromJson(json);
  Map<String, dynamic> toJson() => _$MonitoringRecapToJson(this);

  // Helper methods for UI
  bool get isRestan => status.toLowerCase().contains('restan');
  bool get isSesuai => status.toLowerCase().contains('sesuai');
  bool get isKelebihan => status.toLowerCase().contains('kelebihan');
  bool get hasDelay => status.toLowerCase().contains('delay');
  
  // Color helpers
  bool get isGoodStatus => statusColor == 'green';
  bool get isBadStatus => statusColor == 'red';
  bool get isWarningStatus => statusColor == 'orange' || statusColor == 'yellow';
  
  // Status priority for sorting
  int get statusPriority {
    if (isRestan) return 1; // Highest priority
    if (isKelebihan) return 2;
    if (isSesuai) return 3; // Lowest priority
    return 4;
  }
}

@JsonSerializable()
class MonitoringSummary {
  @JsonKey(name: 'total_records')
  final int totalRecords;
  
  @JsonKey(name: 'total_panen_jjg')
  final int totalPanenJjg;
  
  @JsonKey(name: 'total_angkut_jjg')
  final int totalAngkutJjg;
  
  @JsonKey(name: 'total_restan_jjg')
  final int totalRestanJjg;
  
  @JsonKey(name: 'total_kelebihan_jjg')
  final int totalKelebihanJjg;
  
  @JsonKey(name: 'total_panen_kg')
  final double totalPanenKg;
  
  @JsonKey(name: 'total_angkut_kg')
  final double totalAngkutKg;
  
  @JsonKey(name: 'total_restan_kg')
  final double totalRestanKg;
  
  @JsonKey(name: 'total_sesuai')
  final int totalSesuai;
  
  @JsonKey(name: 'total_restan')
  final int totalRestan;
  
  @JsonKey(name: 'total_kelebihan')
  final int totalKelebihan;
  
  @JsonKey(name: 'total_delay')
  final int totalDelay;
  
  @JsonKey(name: 'status_breakdown')
  final Map<String, int> statusBreakdown;

  MonitoringSummary({
    required this.totalRecords,
    required this.totalPanenJjg,
    required this.totalAngkutJjg,
    required this.totalRestanJjg,
    required this.totalKelebihanJjg,
    required this.totalPanenKg,
    required this.totalAngkutKg,
    required this.totalRestanKg,
    required this.totalSesuai,
    required this.totalRestan,
    required this.totalKelebihan,
    required this.totalDelay,
    required this.statusBreakdown,
  });

  factory MonitoringSummary.fromJson(Map<String, dynamic> json) => _$MonitoringSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MonitoringSummaryToJson(this);

  // Helper getters
  double get restanPercentage => totalRecords > 0 ? (totalRestan / totalRecords) * 100 : 0;
  double get sesuaiPercentage => totalRecords > 0 ? (totalSesuai / totalRecords) * 100 : 0;
  double get kelebihanPercentage => totalRecords > 0 ? (totalKelebihan / totalRecords) * 100 : 0;
  double get delayPercentage => totalRecords > 0 ? (totalDelay / totalRecords) * 100 : 0;
}

@JsonSerializable()
class MonitoringStatistics {
  @JsonKey(name: 'total_panen')
  final int totalPanen;
  
  @JsonKey(name: 'total_transport')
  final int totalTransport;
  
  @JsonKey(name: 'panen_stats')
  final PanenStatistics panenStats;
  
  @JsonKey(name: 'transport_stats')
  final TransportStatistics transportStats;
  
  @JsonKey(name: 'location_stats')
  final LocationStatistics locationStats;

  MonitoringStatistics({
    required this.totalPanen,
    required this.totalTransport,
    required this.panenStats,
    required this.transportStats,
    required this.locationStats,
  });

  factory MonitoringStatistics.fromJson(Map<String, dynamic> json) => _$MonitoringStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$MonitoringStatisticsToJson(this);
}

@JsonSerializable()
class PanenStatistics {
  @JsonKey(name: 'total_jjg')
  final int totalJjg;
  
  @JsonKey(name: 'total_kg')
  final double totalKg;
  
  @JsonKey(name: 'avg_bjr')
  final double avgBjr;
  
  @JsonKey(name: 'unique_locations')
  final int uniqueLocations;

  PanenStatistics({
    required this.totalJjg,
    required this.totalKg,
    required this.avgBjr,
    required this.uniqueLocations,
  });

  factory PanenStatistics.fromJson(Map<String, dynamic> json) => _$PanenStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$PanenStatisticsToJson(this);
}

@JsonSerializable()
class TransportStatistics {
  @JsonKey(name: 'total_jjg')
  final int totalJjg;
  
  @JsonKey(name: 'total_kg')
  final double totalKg;
  
  @JsonKey(name: 'avg_bjr')
  final double avgBjr;
  
  @JsonKey(name: 'unique_locations')
  final int uniqueLocations;
  
  @JsonKey(name: 'unique_vehicles')
  final int uniqueVehicles;

  TransportStatistics({
    required this.totalJjg,
    required this.totalKg,
    required this.avgBjr,
    required this.uniqueLocations,
    required this.uniqueVehicles,
  });

  factory TransportStatistics.fromJson(Map<String, dynamic> json) => _$TransportStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$TransportStatisticsToJson(this);
}

@JsonSerializable()
class LocationStatistics {
  @JsonKey(name: 'total_locations')
  final int totalLocations;
  
  @JsonKey(name: 'panen_only_locations')
  final int panenOnlyLocations;
  
  @JsonKey(name: 'transport_only_locations')
  final int transportOnlyLocations;
  
  @JsonKey(name: 'matched_locations')
  final int matchedLocations;

  LocationStatistics({
    required this.totalLocations,
    required this.panenOnlyLocations,
    required this.transportOnlyLocations,
    required this.matchedLocations,
  });

  factory LocationStatistics.fromJson(Map<String, dynamic> json) => _$LocationStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$LocationStatisticsToJson(this);
  
  double get matchPercentage => totalLocations > 0 ? (matchedLocations / totalLocations) * 100 : 0;
}

@JsonSerializable()
class AfdelingSummary {
  final String afdeling;
  
  @JsonKey(name: 'total_locations')
  final int totalLocations;
  
  @JsonKey(name: 'total_panen_jjg')
  final int totalPanenJjg;
  
  @JsonKey(name: 'total_angkut_jjg')
  final int totalAngkutJjg;
  
  @JsonKey(name: 'total_restan_jjg')
  final int totalRestanJjg;
  
  @JsonKey(name: 'total_kelebihan_jjg')
  final int totalKelebihanJjg;
  
  @JsonKey(name: 'total_restan_kg')
  final double totalRestanKg;
  
  @JsonKey(name: 'sesuai_count')
  final int sesuaiCount;
  
  @JsonKey(name: 'restan_count')
  final int restanCount;
  
  @JsonKey(name: 'kelebihan_count')
  final int kelebihanCount;

  AfdelingSummary({
    required this.afdeling,
    required this.totalLocations,
    required this.totalPanenJjg,
    required this.totalAngkutJjg,
    required this.totalRestanJjg,
    required this.totalKelebihanJjg,
    required this.totalRestanKg,
    required this.sesuaiCount,
    required this.restanCount,
    required this.kelebihanCount,
  });

  factory AfdelingSummary.fromJson(Map<String, dynamic> json) => _$AfdelingSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$AfdelingSummaryToJson(this);

  // Helper getters
  double get restanPercentage => totalLocations > 0 ? (restanCount / totalLocations) * 100 : 0;
  double get sesuaiPercentage => totalLocations > 0 ? (sesuaiCount / totalLocations) * 100 : 0;
  double get kelebihanPercentage => totalLocations > 0 ? (kelebihanCount / totalLocations) * 100 : 0;
}