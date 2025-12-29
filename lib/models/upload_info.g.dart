// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadInfo _$UploadInfoFromJson(Map<String, dynamic> json) => UploadInfo(
  filename: json['filename'] as String,
  originalFilename: json['original_filename'] as String,
  uploadDate: json['upload_date'] as String,
  uploadedBy: json['uploaded_by'] as String,
);

Map<String, dynamic> _$UploadInfoToJson(UploadInfo instance) =>
    <String, dynamic>{
      'filename': instance.filename,
      'original_filename': instance.originalFilename,
      'upload_date': instance.uploadDate,
      'uploaded_by': instance.uploadedBy,
    };
