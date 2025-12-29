// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'koordinat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Koordinat _$KoordinatFromJson(Map<String, dynamic> json) => Koordinat(
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$KoordinatToJson(Koordinat instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
