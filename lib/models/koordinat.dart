import 'package:json_annotation/json_annotation.dart';

part 'koordinat.g.dart';

@JsonSerializable()
class Koordinat {
  final double? latitude;
  final double? longitude;

  const Koordinat({
    this.latitude,
    this.longitude,
  });

  factory Koordinat.fromJson(Map<String, dynamic> json) => _$KoordinatFromJson(json);

  Map<String, dynamic> toJson() => _$KoordinatToJson(this);

  bool get isValid => latitude != null && longitude != null;

  @override
  String toString() {
    return 'Koordinat{latitude: $latitude, longitude: $longitude}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Koordinat &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}