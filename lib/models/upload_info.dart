import 'package:json_annotation/json_annotation.dart';

part 'upload_info.g.dart';

@JsonSerializable()
class UploadInfo {
  final String filename;
  @JsonKey(name: 'original_filename')
  final String originalFilename;
  @JsonKey(name: 'upload_date')
  final String uploadDate;
  @JsonKey(name: 'uploaded_by')
  final String uploadedBy;

  const UploadInfo({
    required this.filename,
    required this.originalFilename,
    required this.uploadDate,
    required this.uploadedBy,
  });

  factory UploadInfo.fromJson(Map<String, dynamic> json) => _$UploadInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UploadInfoToJson(this);

  @override
  String toString() {
    return 'UploadInfo{filename: $filename, uploadDate: $uploadDate, uploadedBy: $uploadedBy}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadInfo &&
          runtimeType == other.runtimeType &&
          filename == other.filename;

  @override
  int get hashCode => filename.hashCode;
}